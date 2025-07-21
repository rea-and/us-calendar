#!/bin/bash

# Fix global redirect in Apache configuration

echo "🔧 Fixing global redirect in Apache configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Global Apache Configuration..."
echo "================================"

# Check the main Apache configuration file
echo "📋 Checking /etc/apache2/apache2.conf for redirect rules:"
grep -n "Redirect\|RewriteRule" /etc/apache2/apache2.conf

echo ""
echo "🔍 Step 2: Backing Up and Fixing Apache Configuration..."
echo "================================"

# Backup the original configuration
echo "📋 Backing up original Apache configuration..."
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.backup

# Remove the redirect rule
echo "📋 Removing redirect rule from Apache configuration..."
sed -i '/RedirectTemp \/ https:\/\/docs.google.com/d' /etc/apache2/apache2.conf

# Check if the redirect was removed
echo "📋 Checking if redirect rule was removed:"
grep -n "Redirect\|RewriteRule" /etc/apache2/apache2.conf

echo ""
echo "🔍 Step 3: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Restoring backup..."
    cp /etc/apache2/apache2.conf.backup /etc/apache2/apache2.conf
    exit 1
fi

echo ""
echo "🔍 Step 4: Restarting Apache..."
echo "================================"

# Restart Apache
systemctl restart apache2
sleep 3

# Check Apache status
if systemctl is-active apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    echo "📋 Restoring backup..."
    cp /etc/apache2/apache2.conf.backup /etc/apache2/apache2.conf
    systemctl restart apache2
    exit 1
fi

echo ""
echo "🔍 Step 5: Testing Direct Access..."
echo "================================"

# Wait for Apache to fully start
sleep 2

# Test with verbose curl to see if redirect is gone
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
echo "✅ Global Redirect Fix Complete!"
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
echo "   3. Restore backup: cp /etc/apache2/apache2.conf.backup /etc/apache2/apache2.conf" 