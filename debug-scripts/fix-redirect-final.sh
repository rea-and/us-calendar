#!/bin/bash

# Final redirect fix - remove all redirects

echo "🔧 Final redirect fix - removing all redirects..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Apache Logs for Redirect Source..."
echo "================================"

# Check Apache error logs
echo "📋 Recent Apache error logs:"
tail -20 /var/log/apache2/error.log

echo ""
echo "📋 Recent Apache access logs:"
tail -20 /var/log/apache2/access.log

echo ""
echo "🔍 Step 2: Checking All Apache Configuration Files..."
echo "================================"

# Check all Apache configuration files for redirects
echo "📋 Checking for redirect rules in Apache configs..."
grep -r "Redirect\|RewriteRule\|301\|302" /etc/apache2/ 2>/dev/null | head -10

echo ""
echo "🔍 Step 3: Creating Minimal Apache Configuration..."
echo "================================"

# Create a minimal Apache configuration with no redirects
cat > /etc/apache2/sites-available/us-calendar.conf << 'EOF'
<VirtualHost *:80>
    ServerName carlevato.net
    ServerAlias www.carlevato.net
    DocumentRoot /var/www/us-calendar/frontend/build
    
    # API proxy
    ProxyPreserveHost On
    ProxyPass /api/ http://localhost:5001/api/
    ProxyPassReverse /api/ http://localhost:5001/api/
    
    # Static files
    <Directory "/var/www/us-calendar/frontend/build">
        Require all granted
        Options -Indexes
        FallbackResource /index.html
    </Directory>
    
    # JavaScript files
    <FilesMatch "\.js$">
        Header set Content-Type "application/javascript"
    </FilesMatch>
    
    # CSS files
    <FilesMatch "\.css$">
        Header set Content-Type "text/css"
    </FilesMatch>
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/us-calendar-error.log
    CustomLog ${APACHE_LOG_DIR}/us-calendar-access.log combined
</VirtualHost>
EOF

# Disable ALL other sites completely
echo "📋 Disabling ALL other sites..."
for site in /etc/apache2/sites-enabled/*; do
    echo "Disabling: $(basename "$site")"
    a2dissite "$(basename "$site")" 2>/dev/null || true
done

# Enable only our site
echo "📋 Enabling only our site..."
a2ensite us-calendar.conf

# Check what's enabled
echo "📋 Enabled sites after cleanup:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 4: Testing Apache Configuration..."
echo "================================"

# Test configuration
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    exit 1
fi

echo ""
echo "🔍 Step 5: Restarting Apache..."
echo "================================"

# Restart Apache
systemctl restart apache2
sleep 3

# Check Apache status
if systemctl is-active apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    tail -10 /var/log/apache2/error.log
    exit 1
fi

echo ""
echo "🔍 Step 6: Testing Direct Access..."
echo "================================"

# Wait for Apache to fully start
sleep 2

# Test with verbose curl to see exactly what's happening
echo "📋 Testing with verbose curl:"
curl -v http://localhost/us/ 2>&1 | head -30

echo ""
echo "📋 Testing HTTP response:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/ 2>/dev/null || echo "000")
echo "HTTP Status: $HTTP_STATUS"

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

# Test external access
echo ""
echo "📋 Testing external access:"
EXTERNAL_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://carlevato.net/us/ 2>/dev/null || echo "000")
echo "External HTTP Status: $EXTERNAL_HTTP"

echo ""
echo "✅ Final Redirect Fix Complete!"
echo ""
echo "🌐 Your calendar should now be available at:"
if [ "$EXTERNAL_HTTP" = "200" ]; then
    echo "   - http://carlevato.net/us/ (HTTP)"
fi
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If HTTP shows 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Test locally: curl -I http://localhost/us/"
echo "   3. Check Apache config: apache2ctl -S" 