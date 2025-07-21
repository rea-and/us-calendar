#!/bin/bash

# Fix frontend API URL configuration

echo "🔧 Fixing frontend API URL configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Frontend Configuration..."
echo "================================"

# Check the current App.js file
echo "📋 Current API configuration in App.js:"
grep -A 3 "API_BASE_URL" /opt/us-calendar/frontend/src/App.js

echo ""
echo "🔍 Step 2: Fixing API URL Configuration..."
echo "================================"

# Fix the API URL in App.js
echo "📋 Fixing API URL to use HTTPS and correct domain..."
sed -i 's/http:\/\/carlaveto\.net\/api/https:\/\/carlevato.net\/api/g' /opt/us-calendar/frontend/src/App.js

echo "📋 Updated API configuration:"
grep -A 3 "API_BASE_URL" /opt/us-calendar/frontend/src/App.js

echo ""
echo "🔍 Step 3: Rebuilding Frontend..."
echo "================================"

# Navigate to frontend directory and rebuild
echo "📋 Navigating to frontend directory..."
cd /opt/us-calendar/frontend

echo "📋 Installing dependencies..."
npm install

echo "📋 Building production version..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend build successful"
else
    echo "❌ Frontend build failed"
    exit 1
fi

echo ""
echo "🔍 Step 4: Deploying Updated Frontend..."
echo "================================"

# Copy the built files to the web directory
echo "📋 Copying built files to web directory..."
cp -r build/* /var/www/us-calendar/frontend/build/

echo "📋 Setting proper permissions..."
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 5: Testing Updated Frontend..."
echo "================================"

# Test the frontend
echo "📋 Testing frontend access:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo "📋 Testing API access:"
curl -I https://carlevato.net/api/users 2>/dev/null | head -5

echo ""
echo "🔍 Step 6: Testing CORS Headers..."
echo "================================"

# Test CORS headers
echo "📋 Testing CORS headers on users API:"
curl -H "Origin: https://carlevato.net" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS https://carlevato.net/api/users -v 2>&1 | grep -E "(Access-Control|HTTP)"

echo ""
echo "🔍 Step 7: Checking Backend API Endpoints..."
echo "================================"

# Check if the users endpoint exists
echo "📋 Testing backend users endpoint:"
curl -I http://localhost:5001/api/users 2>/dev/null | head -5

echo "📋 Testing backend events endpoint:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

echo ""
echo "🔍 Step 8: Checking Logs..."
echo "================================"

# Check Apache logs
echo "📋 Apache error logs:"
tail -5 /var/log/apache2/us-calendar-ssl-error.log

echo "📋 Backend service logs:"
journalctl -u us-calendar-backend --no-pager -n 5

echo ""
echo "✅ Frontend API URL Fix Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo "   - http://carlevato.net/us/ (HTTP domain access)"
echo ""
echo "🔍 The frontend now uses the correct HTTPS API URL!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check browser console for errors"
echo "   2. Test API directly: curl https://carlevato.net/api/users"
echo "   3. Check backend: systemctl status us-calendar-backend"
echo "   4. Check logs: tail -f /var/log/apache2/us-calendar-ssl-error.log" 