#!/bin/bash

# Fix Apache SSL and troubleshooting script

echo "🔧 Fixing Apache SSL and troubleshooting..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Apache Status..."
echo "================================"

# Check Apache status
if systemctl is-active apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache is not running"
    echo "📋 Starting Apache..."
    systemctl start apache2
    sleep 2
    if systemctl is-active apache2; then
        echo "✅ Apache started successfully"
    else
        echo "❌ Apache failed to start"
        echo "📋 Checking Apache error logs..."
        tail -10 /var/log/apache2/error.log
        exit 1
    fi
fi

echo ""
echo "🔍 Step 2: Checking Apache Configuration..."
echo "================================"

# Test Apache configuration
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Checking configuration..."
    apache2ctl configtest 2>&1
    exit 1
fi

echo ""
echo "🔍 Step 3: Checking Apache Ports..."
echo "================================"

# Check if Apache is listening on port 80
if netstat -tlnp | grep :80; then
    echo "✅ Apache is listening on port 80"
else
    echo "❌ Apache is not listening on port 80"
    echo "📋 Checking Apache error logs..."
    tail -10 /var/log/apache2/error.log
fi

echo ""
echo "🔍 Step 4: Testing Local Apache Response..."
echo "================================"

# Test local Apache response
echo "📋 Testing local Apache response..."
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/ 2>/dev/null || echo "000")
echo "Local Apache Status: $LOCAL_STATUS"

if [ "$LOCAL_STATUS" = "000" ]; then
    echo "❌ Apache not responding locally"
    echo "📋 Checking Apache error logs..."
    tail -10 /var/log/apache2/error.log
    echo "📋 Checking Apache access logs..."
    tail -10 /var/log/apache2/access.log
else
    echo "✅ Apache responding locally"
fi

echo ""
echo "🔍 Step 5: Checking File Permissions..."
echo "================================"

# Check file permissions
if [ -d "/var/www/us-calendar/frontend/build" ]; then
    echo "✅ Frontend build directory exists"
    ls -la /var/www/us-calendar/frontend/build/ | head -5
else
    echo "❌ Frontend build directory missing"
    echo "📋 Checking if React build exists..."
    ls -la /var/www/us-calendar/frontend/
fi

# Check ownership
if [ "$(stat -c '%U:%G' /var/www/us-calendar)" = "www-data:www-data" ]; then
    echo "✅ File ownership is correct"
else
    echo "❌ File ownership is incorrect"
    echo "📋 Fixing file ownership..."
    chown -R www-data:www-data /var/www/us-calendar
    chmod -R 755 /var/www/us-calendar
fi

echo ""
echo "🔍 Step 6: Fixing SSL Certificate..."
echo "================================"

# Fix SSL certificate by expanding existing one
echo "📋 Expanding existing SSL certificate..."
if certbot --apache --expand -d carlevato.net -d www.carlevato.net --non-interactive --agree-tos --email admin@carlevato.net; then
    echo "✅ SSL certificate expanded successfully"
    echo "🔄 Restarting Apache with SSL configuration..."
    systemctl restart apache2
else
    echo "❌ SSL certificate expansion failed"
    echo "📋 Trying to renew existing certificate..."
    if certbot renew --apache; then
        echo "✅ SSL certificate renewed successfully"
        systemctl restart apache2
    else
        echo "❌ SSL certificate renewal failed"
        echo "📋 Continuing with HTTP only..."
    fi
fi

echo ""
echo "🔍 Step 7: Final Testing..."
echo "================================"

# Wait for Apache to fully restart
sleep 3

# Test HTTP response
echo "📋 Testing HTTP response:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/ 2>/dev/null || echo "000")
echo "HTTP Status: $HTTP_STATUS"

# Test HTTPS response (if certificate exists)
if [ -f "/etc/letsencrypt/live/carlevato.net/fullchain.pem" ]; then
    echo "📋 Testing HTTPS response:"
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://localhost/us/ --insecure 2>/dev/null || echo "000")
    echo "HTTPS Status: $HTTPS_STATUS"
else
    echo "📋 HTTPS not available (no certificate)"
fi

# Test API
echo "📋 Testing API:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/users 2>/dev/null || echo "000")
echo "API Status: $API_STATUS"

# Test static files
echo "📋 Testing static files:"
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    JS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/us/static/js/$JS_FILENAME" 2>/dev/null || echo "000")
    echo "JavaScript file status: $JS_STATUS"
    
    # Test MIME type
    JS_MIME=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" 2>/dev/null | grep -i "content-type" | head -1)
    echo "JavaScript MIME type: $JS_MIME"
else
    echo "❌ No JavaScript files found"
fi

echo ""
echo "🔍 Step 8: Checking Backend Service..."
echo "================================"

# Check backend service
if systemctl is-active us-calendar; then
    echo "✅ Backend service is running"
else
    echo "❌ Backend service is not running"
    echo "📋 Starting backend service..."
    systemctl start us-calendar
    sleep 2
    if systemctl is-active us-calendar; then
        echo "✅ Backend service started successfully"
    else
        echo "❌ Backend service failed to start"
        echo "📋 Checking backend logs..."
        journalctl -u us-calendar --no-pager -n 10
    fi
fi

echo ""
echo "✅ Apache Fix and Troubleshooting Complete!"
echo ""
echo "🌐 Your application should now be available at:"
if [ -f "/etc/letsencrypt/live/carlevato.net/fullchain.pem" ]; then
    echo "   - https://carlevato.net/us/ (HTTPS)"
fi
echo "   - http://carlevato.net/us/ (HTTP)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Check backend: journalctl -u us-calendar -f"
echo "   3. Test locally: curl -I http://localhost/us/" 