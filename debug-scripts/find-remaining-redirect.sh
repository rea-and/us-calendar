#!/bin/bash

# Find remaining redirect rule

echo "🔍 Finding remaining redirect rule..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking All Apache Configuration Files..."
echo "================================"

# Check all Apache configuration files for redirects
echo "📋 Searching for all redirect rules in Apache configs..."
find /etc/apache2 -name "*.conf" -exec grep -l "Redirect\|RewriteRule\|301\|302" {} \; 2>/dev/null

echo ""
echo "📋 Checking each file for redirect rules:"
for file in $(find /etc/apache2 -name "*.conf" -exec grep -l "Redirect\|RewriteRule\|301\|302" {} \; 2>/dev/null); do
    echo ""
    echo "📋 File: $file"
    grep -n "Redirect\|RewriteRule\|301\|302" "$file" 2>/dev/null
done

echo ""
echo "🔍 Step 2: Checking Our Virtual Host Configuration..."
echo "================================"

# Check our specific virtual host configuration
echo "📋 Our virtual host configuration:"
cat /etc/apache2/sites-available/us-calendar.conf

echo ""
echo "🔍 Step 3: Checking Apache Virtual Host Status..."
echo "================================"

# Check what virtual hosts are active
echo "📋 Active virtual hosts:"
apache2ctl -S 2>/dev/null

echo ""
echo "🔍 Step 4: Testing with Different Host Headers..."
echo "================================"

# Test with different host headers to see if it's host-based
echo "📋 Testing with localhost host header:"
curl -v -H "Host: localhost" http://localhost/us/ 2>&1 | head -20

echo ""
echo "📋 Testing with IP host header:"
curl -v -H "Host: 157.230.244.80" http://localhost/us/ 2>&1 | head -20

echo ""
echo "📋 Testing with carlevato.net host header:"
curl -v -H "Host: carlevato.net" http://localhost/us/ 2>&1 | head -20

echo ""
echo "🔍 Step 5: Checking Apache Error Logs..."
echo "================================"

# Check Apache error logs for more details
echo "📋 Recent Apache error logs:"
tail -10 /var/log/apache2/error.log

echo ""
echo "🔍 Step 6: Checking if HTTPS Virtual Host is Interfering..."
echo "================================"

# Check if there's an HTTPS virtual host that's causing the redirect
echo "📋 Checking for HTTPS virtual hosts:"
grep -r "SSLEngine\|443" /etc/apache2/sites-enabled/ 2>/dev/null

echo ""
echo "📋 Checking if mod_rewrite is enabled:"
apache2ctl -M | grep rewrite

echo ""
echo "✅ Redirect Analysis Complete!"
echo ""
echo "🔧 Next steps based on findings:"
echo "   1. If redirect is in our config, we'll remove it"
echo "   2. If redirect is in another config, we'll disable that site"
echo "   3. If it's host-based, we'll fix the virtual host priority" 