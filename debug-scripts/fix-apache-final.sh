#!/bin/bash

# Final Apache configuration fix

echo "🔧 Final Apache configuration fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Apache Configuration..."
echo "================================"

# Check what sites are enabled
echo "📋 Enabled Apache sites:"
ls -la /etc/apache2/sites-enabled/

# Check Apache configuration
echo ""
echo "📋 Apache virtual host configuration:"
apache2ctl -S 2>/dev/null

echo ""
echo "🔍 Step 2: Checking Apache Logs..."
echo "================================"

# Check Apache error logs
echo "📋 Recent Apache error logs:"
tail -10 /var/log/apache2/error.log

echo ""
echo "📋 Recent Apache access logs:"
tail -10 /var/log/apache2/access.log

echo ""
echo "🔍 Step 3: Testing Direct File Access..."
echo "================================"

# Test if files exist
echo "📋 Checking if frontend files exist:"
ls -la /var/www/us-calendar/frontend/build/

# Test direct file access
echo ""
echo "📋 Testing direct file access:"
if [ -f "/var/www/us-calendar/frontend/build/index.html" ]; then
    echo "✅ index.html exists"
    head -5 /var/www/us-calendar/frontend/build/index.html
else
    echo "❌ index.html missing"
fi

echo ""
echo "🔍 Step 4: Checking Apache Configuration Files..."
echo "================================"

# Check our Apache configuration
echo "📋 Our Apache configuration:"
cat /etc/apache2/sites-available/us-calendar.conf

echo ""
echo "🔍 Step 5: Testing Local Requests..."
echo "================================"

# Test with verbose curl to see what's happening
echo "📋 Testing local HTTP request with verbose output:"
curl -v http://localhost/us/ 2>&1 | head -20

echo ""
echo "📋 Testing local HTTPS request with verbose output:"
curl -v https://localhost/us/ --insecure 2>&1 | head -20

echo ""
echo "🔍 Step 6: Fixing Apache Configuration..."
echo "================================"

# Create a simple, working Apache configuration
echo "📋 Creating simplified Apache configuration..."
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

# Disable all other sites
echo "📋 Disabling all other sites..."
for site in /etc/apache2/sites-enabled/*; do
    if [[ "$site" != "/etc/apache2/sites-enabled/us-calendar.conf" ]]; then
        echo "Disabling: $(basename "$site")"
        a2dissite "$(basename "$site")" 2>/dev/null || true
    fi
done

# Enable our site
echo "📋 Enabling our site..."
a2ensite us-calendar.conf

# Test configuration
echo "📋 Testing Apache configuration..."
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    exit 1
fi

echo ""
echo "🔍 Step 7: Restarting Apache..."
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
echo "🔍 Step 8: Final Testing..."
echo "================================"

# Wait for Apache to fully start
sleep 2

# Test HTTP response
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
echo "✅ Apache Final Fix Complete!"
echo ""
echo "🌐 Your calendar should now be available at:"
echo "   - http://carlevato.net/us/ (HTTP)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If HTTP shows 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Test locally: curl -I http://localhost/us/" 