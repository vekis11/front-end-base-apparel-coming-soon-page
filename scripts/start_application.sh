#!/bin/bash

# Start Application Script for CodeDeploy
# This script starts the application and performs health checks

set -e

echo "Starting ApplicationStart phase..."

# Reload nginx configuration
echo "Reloading nginx configuration..."
systemctl reload nginx

# Wait for nginx to fully start
echo "Waiting for nginx to start..."
sleep 5

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx failed to start"
    systemctl status nginx
    exit 1
fi

# Perform initial health check
echo "Performing initial health check..."
for i in {1..30}; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo "Application is healthy and responding"
        break
    else
        echo "Waiting for application to be ready... (attempt $i/30)"
        sleep 2
    fi
    
    if [ $i -eq 30 ]; then
        echo "ERROR: Application failed to start within 60 seconds"
        exit 1
    fi
done

# Verify application files are accessible
echo "Verifying application files..."
if [ ! -f "/var/www/html/index.html" ]; then
    echo "ERROR: index.html not found"
    exit 1
fi

# Check application logs
echo "Checking application logs..."
if [ -f "/var/log/nginx/error.log" ]; then
    echo "Recent nginx error log entries:"
    tail -10 /var/log/nginx/error.log
fi

# Set up application monitoring
echo "Setting up application monitoring..."
cat > /usr/local/bin/app-monitor.sh << 'EOF'
#!/bin/bash
# Application monitoring script

LOG_FILE="/var/log/app-monitor.log"
HEALTH_URL="http://localhost/health"

# Check application health
if ! curl -f "$HEALTH_URL" > /dev/null 2>&1; then
    echo "$(date): Application health check failed" >> "$LOG_FILE"
    # Send alert (you can integrate with CloudWatch, SNS, etc.)
    exit 1
fi

# Check disk space
DISK_USAGE=$(df /var/www/html | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "$(date): Disk usage is high: ${DISK_USAGE}%" >> "$LOG_FILE"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ "$MEMORY_USAGE" -gt 80 ]; then
    echo "$(date): Memory usage is high: ${MEMORY_USAGE}%" >> "$LOG_FILE"
fi

echo "$(date): Application monitoring check passed" >> "$LOG_FILE"
EOF

chmod +x /usr/local/bin/app-monitor.sh

# Start monitoring in background
echo "Starting application monitoring..."
nohup /usr/local/bin/app-monitor.sh > /dev/null 2>&1 &

# Display deployment information
echo "Deployment Information:"
echo "======================="
echo "Deployment ID: ${DEPLOYMENT_ID}"
echo "Application URL: http://localhost"
echo "Health Check URL: http://localhost/health"
echo "Nginx Status: $(systemctl is-active nginx)"
echo "Deployment completed at: $(date)"

echo "ApplicationStart phase completed successfully!" 