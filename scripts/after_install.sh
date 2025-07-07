#!/bin/bash

# After Install Script for CodeDeploy
# This script runs after the application is installed

set -e

echo "Starting AfterInstall phase..."

# Set proper permissions
echo "Setting proper permissions..."
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html

# Create backup of current deployment
echo "Creating backup of current deployment..."
if [ -d "/var/www/html.backup" ]; then
    rm -rf /var/www/html.backup
fi
cp -r /var/www/html /var/www/html.backup

# Set up log rotation
echo "Setting up log rotation..."
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

# Configure system limits for nginx
echo "Configuring system limits..."
cat > /etc/security/limits.d/nginx.conf << 'EOF'
nginx soft nofile 65536
nginx hard nofile 65536
EOF

# Set up monitoring and health checks
echo "Setting up monitoring..."
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for the application

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    echo "Nginx is not running"
    exit 1
fi

# Check if application is responding
if ! curl -f http://localhost/health > /dev/null 2>&1; then
    echo "Application health check failed"
    exit 1
fi

echo "Health check passed"
exit 0
EOF

chmod +x /usr/local/bin/health-check.sh

# Set up cron job for health monitoring
echo "Setting up health monitoring cron job..."
cat > /etc/cron.d/health-monitor << 'EOF'
*/5 * * * * root /usr/local/bin/health-check.sh >> /var/log/health-monitor.log 2>&1
EOF

# Create application status file
echo "Creating application status file..."
echo "DEPLOYED_AT=$(date)" > /var/www/html/.deployment-info
echo "VERSION=${DEPLOYMENT_ID}" >> /var/www/html/.deployment-info

echo "AfterInstall phase completed successfully!" 