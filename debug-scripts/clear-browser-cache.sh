#!/bin/bash

# Clear browser cache and fix caching issues

echo "🔧 Clearing browser cache and fixing caching issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Frontend Files..."
echo "================================"

# Check if the updated files are actually deployed
echo "📋 Checking if updated App.js is deployed:"
grep -A 3 "API_BASE_URL" /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -10

echo ""
echo "📋 Checking build directory contents:"
ls -la /var/www/us-calendar/frontend/build/static/js/

echo ""
echo "🔍 Step 2: Adding Cache-Busting Headers..."
echo "================================"

# Add cache-busting headers to Apache configuration
echo "📋 Adding cache-busting headers to Apache config..."
cat >> /etc/apache2/sites-available/us-calendar-ssl.conf << 'EOF'

    # Cache-busting headers for React app
    <LocationMatch "^/us/">
        Header always set Cache-Control "no-cache, no-store, must-revalidate"
        Header always set Pragma "no-cache"
        Header always set Expires "0"
    </LocationMatch>
    
    # Cache static assets with versioning
    <LocationMatch "^/us/static/">
        Header always set Cache-Control "public, max-age=31536000"
    </LocationMatch>
EOF

echo "📋 Updated HTTPS virtual host configuration:"
tail -10 /etc/apache2/sites-available/us-calendar-ssl.conf

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
    exit 1
fi

echo ""
echo "🔍 Step 5: Testing Frontend with Cache Headers..."
echo "================================"

# Test frontend with cache headers
echo "📋 Testing frontend with cache headers:"
curl -I https://carlevato.net/us/ 2>/dev/null | grep -E "(Cache-Control|Pragma|Expires|HTTP)"

echo "📋 Testing API access:"
curl -I https://carlevato.net/api/users 2>/dev/null | head -5

echo ""
echo "🔍 Step 6: Checking Frontend Source..."
echo "================================"

# Check the actual frontend source being served
echo "📋 Checking frontend source for API URL:"
curl -s https://carlevato.net/us/ | grep -o "carlaveto\|carlevato" | head -5

echo ""
echo "🔍 Step 7: Forcing Frontend Rebuild..."
echo "================================"

# Force a complete rebuild and redeploy
echo "📋 Forcing complete frontend rebuild..."
cd /opt/us-calendar/frontend

echo "📋 Cleaning build directory..."
rm -rf build/

echo "📋 Rebuilding frontend..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo "📋 Deploying rebuilt frontend..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 8: Final Testing..."
echo "================================"

# Final testing
echo "📋 Testing updated frontend:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo "📋 Testing API:"
curl -I https://carlevato.net/api/users 2>/dev/null | head -5

echo ""
echo "✅ Browser Cache Clear Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo "   - http://carlevato.net/us/ (HTTP domain access)"
echo ""
echo "🔍 IMPORTANT: Clear your browser cache completely!"
echo "📱 Steps to clear cache:"
echo "   1. Open Chrome DevTools (F12)"
echo "   2. Right-click the refresh button"
echo "   3. Select 'Empty Cache and Hard Reload'"
echo "   4. Or use Ctrl+Shift+R (Cmd+Shift+R on Mac)"
echo ""
echo "🔧 If issues persist:"
echo "   1. Clear browser cache completely"
echo "   2. Test in incognito/private mode"
echo "   3. Check browser console for errors"
echo "   4. Test API directly: curl https://carlevato.net/api/users" 