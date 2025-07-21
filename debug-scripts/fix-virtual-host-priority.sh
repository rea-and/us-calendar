#!/bin/bash

# Fix virtual host priority issue

echo "🔧 Fixing virtual host priority issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Virtual Host Status..."
echo "================================"

# Check what virtual hosts are active
echo "📋 Active virtual hosts:"
apache2ctl -S 2>/dev/null

echo ""
echo "📋 Enabled sites:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 2: Checking Our Calendar Site Configuration..."
echo "================================"

# Check our calendar site configuration
echo "📋 Our calendar site configuration:"
cat /etc/apache2/sites-available/us-calendar.conf

echo ""
echo "🔍 Step 3: Checking Virtual Host Priority..."
echo "================================"

# The issue is that both virtual hosts have the same ServerName
# We need to make our calendar site take priority
echo "📋 Current virtual host priority issue:"
echo "   - 000-default.conf has ServerName carlevato.net"
echo "   - us-calendar.conf has ServerName carlevato.net"
echo "   - Apache is using the first one it finds (000-default.conf)"

echo ""
echo "🔍 Step 4: Fixing Virtual Host Priority..."
echo "================================"

# Disable the default site completely
echo "📋 Disabling default site..."
a2dissite 000-default

# Enable our calendar site
echo "📋 Ensuring calendar site is enabled..."
a2ensite us-calendar

# Check what's enabled now
echo "📋 Enabled sites after fix:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 5: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
echo "📋 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Re-enabling default site..."
    a2ensite 000-default
    exit 1
fi

echo ""
echo "🔍 Step 6: Restarting Apache..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    echo "📋 Re-enabling default site..."
    a2ensite 000-default
    systemctl restart apache2
    exit 1
fi

echo ""
echo "🔍 Step 7: Testing Access..."
echo "================================"

# Test HTTP access
echo "📋 Testing HTTP access:"
curl -I http://localhost/us/ 2>/dev/null | head -5

# Test API access
echo "📋 Testing API access:"
curl -I http://localhost/api/events 2>/dev/null | head -5

# Test external access
echo "📋 Testing external access:"
curl -I http://157.230.244.80/us/ 2>/dev/null | head -5

# Test with verbose curl to see what's happening
echo "📋 Verbose test:"
curl -v http://localhost/us/ 2>&1 | head -20

echo ""
echo "🔍 Step 8: Checking Apache Logs..."
echo "================================"

# Check Apache error logs
echo "📋 Recent Apache error logs:"
tail -5 /var/log/apache2/error.log

echo "📋 Calendar site error logs:"
tail -5 /var/log/apache2/us-calendar-error.log

echo ""
echo "✅ Virtual Host Priority Fix Complete!"
echo ""
echo "🌐 Your calendar should now be available at:"
echo "   - http://carlevato.net/us/ (domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If HTTP shows 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Test locally: curl -I http://localhost/us/"
echo "   3. Re-enable default: a2ensite 000-default" 