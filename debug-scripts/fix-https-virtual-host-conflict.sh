#!/bin/bash

# Fix HTTPS virtual host conflict

echo "🔧 Fixing HTTPS virtual host conflict..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current HTTPS Virtual Hosts..."
echo "================================"

# Check what HTTPS virtual hosts are enabled
echo "📋 Enabled HTTPS sites:"
ls -la /etc/apache2/sites-enabled/ | grep ssl

echo ""
echo "📋 Virtual host status:"
apache2ctl -S 2>/dev/null | grep -A 5 ":443"

echo ""
echo "🔍 Step 2: Removing Conflicting HTTPS Site..."
echo "================================"

# The issue is that both 000-default-le-ssl.conf and us-calendar-ssl.conf exist
# and both have the same ServerName, causing conflicts
echo "📋 Removing conflicting default HTTPS site..."
rm -f /etc/apache2/sites-enabled/000-default-le-ssl.conf

echo "📋 Enabled sites after removal:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 3: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
echo "📋 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Restoring default HTTPS site..."
    a2ensite 000-default-le-ssl
    exit 1
fi

echo ""
echo "🔍 Step 4: Restarting Apache..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    echo "📋 Restoring default HTTPS site..."
    a2ensite 000-default-le-ssl
    systemctl restart apache2
    exit 1
fi

echo ""
echo "🔍 Step 5: Testing HTTPS Access..."
echo "================================"

# Test HTTPS access
echo "📋 Testing HTTPS calendar access:"
curl -I https://localhost/us/ 2>/dev/null | head -5

echo "📋 Testing HTTPS API access:"
curl -I https://localhost/api/events 2>/dev/null | head -5

echo "📋 Testing external HTTPS access:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo "📋 Testing external HTTPS API:"
curl -I https://carlevato.net/api/events 2>/dev/null | head -5

echo ""
echo "🔍 Step 6: Testing CORS Headers..."
echo "================================"

# Test CORS headers
echo "📋 Testing CORS headers on API:"
curl -H "Origin: https://carlevato.net" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS https://carlevato.net/api/events -v 2>&1 | grep -E "(Access-Control|HTTP)"

echo ""
echo "🔍 Step 7: Testing Full Application..."
echo "================================"

# Test the full application
echo "📋 Testing HTTP calendar access:"
curl -I http://carlevato.net/us/ 2>/dev/null | head -5

echo "📋 Testing HTTP API access:"
curl -I http://carlevato.net/api/events 2>/dev/null | head -5

echo "📋 Testing backend directly:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

echo ""
echo "🔍 Step 8: Checking Logs..."
echo "================================"

# Check Apache logs
echo "📋 Apache error logs:"
tail -5 /var/log/apache2/error.log

echo "📋 Calendar HTTPS error logs:"
tail -5 /var/log/apache2/us-calendar-ssl-error.log

echo "📋 Calendar HTTP error logs:"
tail -5 /var/log/apache2/us-calendar-error.log

echo ""
echo "✅ HTTPS Virtual Host Conflict Fix Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo "   - http://carlevato.net/us/ (HTTP domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If both HTTP and HTTPS show 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-ssl-error.log"
echo "   2. Test HTTPS: curl -I https://carlevato.net/us/"
echo "   3. Test API: curl -I https://carlevato.net/api/events"
echo "   4. Check backend: systemctl status us-calendar-backend" 