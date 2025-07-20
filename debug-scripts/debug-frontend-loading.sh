#!/bin/bash

# Debug frontend loading issues (spinner but no content)

echo "🔍 Debugging Frontend Loading Issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔧 Checking Backend API Connectivity..."
echo "================================"

# Check if backend is running
echo "📊 Backend service status:"
systemctl status us-calendar --no-pager

# Test API endpoints
echo ""
echo "🧪 Testing API endpoints..."
echo "📋 Testing /api/users endpoint:"
curl -s http://localhost:5001/api/users | head -5

echo ""
echo "📋 Testing /api/events endpoint:"
curl -s http://localhost:5001/api/events | head -5

echo ""
echo "📋 Testing /api/health endpoint:"
curl -s http://localhost:5001/api/health

echo ""
echo "🌐 Testing API through nginx proxy..."
echo "📋 Testing /api/users through nginx:"
curl -s http://localhost/api/users | head -5

echo ""
echo "🔍 Checking React App Configuration..."
echo "================================"

# Check if React app is configured to use the correct API URL
echo "📄 Checking React app configuration..."
if [ -f "/var/www/us-calendar/frontend/src/App.js" ]; then
    echo "✅ App.js exists"
    echo "📋 Looking for API configuration:"
    grep -n "localhost\|5001\|api" /var/www/us-calendar/frontend/src/App.js | head -5
else
    echo "❌ App.js not found"
fi

# Check package.json for proxy configuration
echo ""
echo "📋 Package.json proxy configuration:"
if [ -f "/var/www/us-calendar/frontend/package.json" ]; then
    grep -A 5 -B 5 "proxy" /var/www/us-calendar/frontend/package.json
else
    echo "❌ package.json not found"
fi

echo ""
echo "🔍 Checking Browser Console Errors..."
echo "================================"

# Check nginx error logs for recent errors
echo "📋 Recent nginx error logs:"
tail -10 /var/log/nginx/error.log

echo ""
echo "📋 Recent nginx access logs:"
tail -10 /var/log/nginx/access.log

echo ""
echo "🔧 Checking CORS Configuration..."
echo "================================"

# Check if CORS is properly configured in the backend
echo "📄 Checking backend CORS configuration:"
if [ -f "/var/www/us-calendar/backend/app.py" ]; then
    echo "✅ app.py exists"
    echo "📋 CORS configuration:"
    grep -A 5 -B 5 "CORS\|cors" /var/www/us-calendar/backend/app.py
else
    echo "❌ app.py not found"
fi

echo ""
echo "🔍 Checking React Build Configuration..."
echo "================================"

# Check if the React app was built with the correct configuration
echo "📄 Checking index.html for script references:"
head -30 /var/www/us-calendar/frontend/build/index.html

echo ""
echo "📋 Checking for any build warnings or errors:"
echo "📄 Asset manifest:"
cat /var/www/us-calendar/frontend/build/asset-manifest.json

echo ""
echo "🔧 Quick Fixes to Try..."
echo "================================"

echo "1. 🔄 Restart backend service:"
systemctl restart us-calendar
sleep 2
systemctl status us-calendar --no-pager

echo ""
echo "2. 🌐 Restart nginx:"
systemctl restart nginx

echo ""
echo "3. 🧪 Test API connectivity again:"
curl -s http://localhost:5001/api/users | head -3

echo ""
echo "4. 🔍 Check if React app can reach the API:"
echo "📋 Testing from React app perspective:"
curl -s -H "Origin: http://carlevato.net" http://localhost:5001/api/users | head -3

echo ""
echo "✅ Debugging completed!"
echo ""
echo "💡 Common issues and solutions:"
echo "1. API not accessible: Check backend logs with 'journalctl -u us-calendar -f'"
echo "2. CORS issues: Check if backend allows requests from carlaveto.net"
echo "3. Network errors: Check browser developer tools (F12) Network tab"
echo "4. JavaScript errors: Check browser developer tools (F12) Console tab"
echo ""
echo "🌐 Test the application at: http://carlevato.net/us"
echo "🔍 Open browser developer tools (F12) to see specific errors" 