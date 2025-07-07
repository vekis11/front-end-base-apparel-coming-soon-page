#!/bin/bash

# EC2 Instance Setup Script for CodeDeploy
# This script prepares EC2 instances for deployment

set -e

echo "Starting EC2 instance setup..."

# Update system
echo "Updating system packages..."
yum update -y

# Install required packages
echo "Installing required packages..."
yum install -y \
    nginx \
    docker \
    git \
    curl \
    wget \
    unzip \
    jq \
    aws-cli \
    amazon-cloudwatch-agent \
    codedeploy-agent

# Start and enable services
echo "Starting and enabling services..."
systemctl start nginx
systemctl enable nginx
systemctl start docker
systemctl enable docker
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Configure nginx
echo "Configuring nginx..."
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    server {
        listen 80;
        server_name localhost;
        root /var/www/html;
        index index.html;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # Rate limiting
        limit_req zone=api burst=20 nodelay;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Vary Accept-Encoding;
        }

        # Handle HTML5 routing
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Metrics endpoint for monitoring
        location /metrics {
            access_log off;
            return 200 "nginx_connections_active $nginx_connections_active\nnginx_connections_reading $nginx_connections_reading\nnginx_connections_writing $nginx_connections_writing\nnginx_connections_waiting $nginx_connections_waiting\n";
            add_header Content-Type text/plain;
        }

        # Deny access to hidden files
        location ~ /\. {
            deny all;
        }
    }
}
EOF

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

# Create application directory
echo "Creating application directory..."
mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Configure CloudWatch agent
echo "Configuring CloudWatch agent..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/nginx/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/nginx/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/codedeploy-agent/codedeploy-agent.log",
                        "log_group_name": "/aws/ec2/codedeploy-agent",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "BaseApparel/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Configure log rotation
echo "Configuring log rotation..."
cat > /etc/logrotate.d/nginx << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 nginx nginx
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
EOF

cat > /etc/logrotate.d/codedeploy-agent << 'EOF'
/var/log/codedeploy-agent/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

# Set up monitoring scripts
echo "Setting up monitoring scripts..."
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for the application

LOG_FILE="/var/log/health-check.log"

log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    log_message "ERROR: Nginx is not running"
    exit 1
fi

# Check if application is responding
if ! curl -f http://localhost/health > /dev/null 2>&1; then
    log_message "ERROR: Application health check failed"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /var/www/html | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    log_message "WARNING: Disk usage is high: ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ "$MEMORY_USAGE" -gt 80 ]; then
    log_message "WARNING: Memory usage is high: ${MEMORY_USAGE}%"
fi

log_message "Health check passed"
exit 0
EOF

chmod +x /usr/local/bin/health-check.sh

# Set up cron jobs
echo "Setting up cron jobs..."
cat > /etc/cron.d/health-monitor << 'EOF'
*/5 * * * * root /usr/local/bin/health-check.sh
EOF

cat > /etc/cron.d/system-maintenance << 'EOF'
0 2 * * 0 root yum update -y --security
0 3 * * 0 root systemctl restart nginx
0 4 * * 0 root systemctl restart docker
EOF

# Configure system limits
echo "Configuring system limits..."
cat > /etc/security/limits.d/nginx.conf << 'EOF'
nginx soft nofile 65536
nginx hard nofile 65536
EOF

cat > /etc/security/limits.d/docker.conf << 'EOF'
docker soft nofile 65536
docker hard nofile 65536
EOF

# Set up firewall rules (if using firewalld)
if systemctl is-active --quiet firewalld; then
    echo "Configuring firewall..."
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

# Create deployment info file
echo "Creating deployment info file..."
cat > /var/www/html/.deployment-info << EOF
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
SETUP_DATE=$(date)
SETUP_SCRIPT_VERSION=1.0.0
EOF

# Set proper permissions
echo "Setting proper permissions..."
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Create backup directory
echo "Creating backup directory..."
mkdir -p /var/www/html.backup
chown -R nginx:nginx /var/www/html.backup

# Test the setup
echo "Testing the setup..."
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx is running"
else
    echo "✗ Nginx failed to start"
    exit 1
fi

if systemctl is-active --quiet docker; then
    echo "✓ Docker is running"
else
    echo "✗ Docker failed to start"
    exit 1
fi

if systemctl is-active --quiet codedeploy-agent; then
    echo "✓ CodeDeploy agent is running"
else
    echo "✗ CodeDeploy agent failed to start"
    exit 1
fi

# Display setup information
echo "========================================"
echo "EC2 Instance Setup Completed Successfully"
echo "========================================"
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
echo "Setup Date: $(date)"
echo ""
echo "Services Status:"
echo "- Nginx: $(systemctl is-active nginx)"
echo "- Docker: $(systemctl is-active docker)"
echo "- CodeDeploy Agent: $(systemctl is-active codedeploy-agent)"
echo "- CloudWatch Agent: $(systemctl is-active amazon-cloudwatch-agent)"
echo ""
echo "Next Steps:"
echo "1. Tag this instance with Environment=production"
echo "2. Ensure the instance is in the correct CodeDeploy deployment group"
echo "3. Test the health check endpoint: curl http://localhost/health"
echo "4. Monitor logs in CloudWatch"
echo "========================================" 