#!/bin/bash

# Validate Service Script for CodeDeploy
# This script validates that the application is working correctly

set -e

echo "Starting ValidateService phase..."

# Function to log validation results
log_validation() {
    echo "$(date): $1" >> /var/log/deployment-validation.log
    echo "$1"
}

# Function to check HTTP response
check_http_response() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    log_validation "Checking $description..."
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" -eq "$expected_status" ]; then
        log_validation "✓ $description: HTTP $response (Expected: $expected_status)"
        return 0
    else
        log_validation "✗ $description: HTTP $response (Expected: $expected_status)"
        return 1
    fi
}

# Function to check content
check_content() {
    local url=$1
    local expected_content=$2
    local description=$3
    
    log_validation "Checking $description..."
    
    if curl -s "$url" | grep -q "$expected_content"; then
        log_validation "✓ $description: Content found"
        return 0
    else
        log_validation "✗ $description: Content not found"
        return 1
    fi
}

# Initialize validation log
echo "=== Deployment Validation Log ===" > /var/log/deployment-validation.log
echo "Started at: $(date)" >> /var/log/deployment-validation.log

# Wait for application to be fully ready
log_validation "Waiting for application to be ready..."
sleep 10

# 1. Check if nginx is running
log_validation "Validating nginx service..."
if systemctl is-active --quiet nginx; then
    log_validation "✓ Nginx is running"
else
    log_validation "✗ Nginx is not running"
    exit 1
fi

# 2. Check health endpoint
check_http_response "http://localhost/health" 200 "Health endpoint"

# 3. Check main application page
check_http_response "http://localhost/" 200 "Main application page"

# 4. Check if main content is loaded
check_content "http://localhost/" "We're coming soon" "Main page content"

# 5. Check if images are accessible
log_validation "Checking static assets..."
if [ -f "/var/www/html/images/hero-desktop.jpg" ]; then
    log_validation "✓ Hero image exists"
else
    log_validation "✗ Hero image missing"
fi

check_http_response "http://localhost/images/hero-desktop.jpg" 200 "Hero image accessibility"

# 6. Check CSS and styling
check_content "http://localhost/" "background: linear-gradient" "CSS styling"

# 7. Check JavaScript functionality
check_content "http://localhost/" "addEventListener" "JavaScript functionality"

# 8. Check form validation
log_validation "Checking form validation..."
if grep -q "emailRegex" /var/www/html/index.html; then
    log_validation "✓ Email validation script found"
else
    log_validation "✗ Email validation script missing"
fi

# 9. Check security headers
log_validation "Checking security headers..."
headers=$(curl -s -I http://localhost/ | grep -E "(X-Frame-Options|X-XSS-Protection|X-Content-Type-Options)" | wc -l)
if [ "$headers" -ge 3 ]; then
    log_validation "✓ Security headers are present"
else
    log_validation "✗ Security headers are missing"
fi

# 10. Check performance optimizations
log_validation "Checking performance optimizations..."
if grep -q "gzip" /etc/nginx/nginx.conf; then
    log_validation "✓ Gzip compression is enabled"
else
    log_validation "✗ Gzip compression is disabled"
fi

# 11. Check file permissions
log_validation "Checking file permissions..."
if [ "$(stat -c %a /var/www/html)" = "755" ]; then
    log_validation "✓ Directory permissions are correct"
else
    log_validation "✗ Directory permissions are incorrect"
fi

# 12. Check log files
log_validation "Checking log files..."
if [ -f "/var/log/nginx/access.log" ] && [ -f "/var/log/nginx/error.log" ]; then
    log_validation "✓ Nginx log files exist"
else
    log_validation "✗ Nginx log files missing"
fi

# 13. Check deployment info
log_validation "Checking deployment information..."
if [ -f "/var/www/html/.deployment-info" ]; then
    log_validation "✓ Deployment info file exists"
    cat /var/www/html/.deployment-info >> /var/log/deployment-validation.log
else
    log_validation "✗ Deployment info file missing"
fi

# 14. Load testing (basic)
log_validation "Performing basic load test..."
for i in {1..10}; do
    if ! curl -f http://localhost/health > /dev/null 2>&1; then
        log_validation "✗ Load test failed on iteration $i"
        exit 1
    fi
done
log_validation "✓ Basic load test passed"

# 15. Check system resources
log_validation "Checking system resources..."
disk_usage=$(df /var/www/html | tail -1 | awk '{print $5}' | sed 's/%//')
memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')

log_validation "Disk usage: ${disk_usage}%"
log_validation "Memory usage: ${memory_usage}%"

if [ "$disk_usage" -lt 90 ] && [ "$memory_usage" -lt 90 ]; then
    log_validation "✓ System resources are healthy"
else
    log_validation "⚠ System resources are high"
fi

# Final validation summary
echo "=== Validation Summary ===" >> /var/log/deployment-validation.log
echo "Completed at: $(date)" >> /var/log/deployment-validation.log

log_validation "Validation completed successfully!"
log_validation "Application is ready for production use"

echo "ValidateService phase completed successfully!" 