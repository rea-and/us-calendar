#!/bin/bash

# Fix default site removal issue

echo "🔧 Fixing default site removal issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Situation..."
echo "================================"

# Check what's in the sites-enabled directory
echo "📋 Current sites-enabled directory:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "📋 Virtual host status:"
apache2ctl -S 2>/dev/null | grep -A 10 "port 80"

echo ""
echo "🔍 Step 2: Manually Removing Default Site..."
echo "================================"

# The issue is that 000-default.conf is a regular file, not a symlink
# We need to remove it manually
echo "📋 Removing default site configuration file..."
rm -f /etc/apache2/sites-enabled/000-default.conf

# Also remove the backup file
echo "📋 Removing backup file..."
rm -f /etc/apache2/sites-enabled/000-default.conf.backup

echo "📋 Sites-enabled directory after removal:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 3: Verifying Calendar Site is Enabled..."
echo "================================"

# Make sure our calendar site is enabled
echo "📋 Ensuring calendar site is enabled..."
a2ensite us-calendar

echo "📋 Final sites-enabled directory:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 4: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
echo "📋 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    exit 1
fi

echo ""
echo "🔍 Step 5: Restarting Apache..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    exit 1
fi

echo ""
echo "🔍 Step 6: Testing Access..."
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

# Test with verbose curl
echo "📋 Verbose test:"
curl -v http://localhost/us/ 2>&1 | head -20

echo ""
echo "🔍 Step 7: Checking Virtual Host Status..."
echo "================================"

# Check virtual host status again
echo "📋 Virtual host status after fix:"
apache2ctl -S 2>/dev/null | grep -A 10 "port 80"

echo ""
echo "🔍 Step 8: Checking Apache Logs..."
echo "================================"

# Check Apache error logs
echo "📋 Recent Apache error logs:"
tail -5 /var/log/apache2/error.log

echo "📋 Calendar site error logs:"
tail -5 /var/log/apache2/us-calendar-error.log

echo ""
echo "✅ Default Site Removal Fix Complete!"
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
echo "   3. Check backend: systemctl status us-calendar-backend" 