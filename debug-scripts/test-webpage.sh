#!/bin/bash

# Comprehensive webpage testing script

echo "🧪 Testing Webpage Serving on Server..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🌐 Testing Basic Webpage Access..."
echo "================================"

# Test main page access
echo "📋 Testing main page (/)..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/

echo "📋 Testing /us page..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/us

echo "📋 Testing /us/ (with trailing slash)..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/us/

echo ""
echo "📄 Testing HTML Content..."
echo "================================"

# Test if HTML content is correct
echo "📋 Checking if index.html is served correctly..."
HTML_CONTENT=$(curl -s http://localhost/us/)
if echo "$HTML_CONTENT" | grep -q "Our Calendar"; then
    echo "✅ HTML contains 'Our Calendar' title"
else
    echo "❌ HTML missing 'Our Calendar' title"
fi

if echo "$HTML_CONTENT" | grep -q "root"; then
    echo "✅ HTML contains React root div"
else
    echo "❌ HTML missing React root div"
fi

if echo "$HTML_CONTENT" | grep -q "main.*\.js"; then
    echo "✅ HTML contains JavaScript file reference"
else
    echo "❌ HTML missing JavaScript file reference"
fi

if echo "$HTML_CONTENT" | grep -q "main.*\.css"; then
    echo "✅ HTML contains CSS file reference"
else
    echo "❌ HTML missing CSS file reference"
fi

echo ""
echo "📁 Testing Static Files..."
echo "================================"

# Get the actual filenames from the build
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
CSS_FILE=$(ls /var/www/us-calendar/frontend/build/static/css/main.*.css 2>/dev/null | head -1)

if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 Testing JavaScript file: $JS_FILENAME"
    curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://localhost/us/static/js/$JS_FILENAME"
else
    echo "❌ JavaScript file not found"
fi

if [ -n "$CSS_FILE" ]; then
    CSS_FILENAME=$(basename "$CSS_FILE")
    echo "📋 Testing CSS file: $CSS_FILENAME"
    curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://localhost/us/static/css/$CSS_FILENAME"
else
    echo "❌ CSS file not found"
fi

echo ""
echo "📋 Testing manifest.json..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" http://localhost/us/manifest.json

echo ""
echo "🔗 Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing /api/users..."
API_RESPONSE=$(curl -s http://localhost/api/users)
if echo "$API_RESPONSE" | grep -q "Angel\|Andrea"; then
    echo "✅ API returns user data"
    echo "📄 Response: $(echo "$API_RESPONSE" | head -3)"
else
    echo "❌ API not returning user data"
fi

echo "📋 Testing /api/events..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/api/events

echo "📋 Testing /api/health..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/api/health

echo ""
echo "🌐 Testing External Access..."
echo "================================"

# Test using server's external IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
if [ -n "$SERVER_IP" ]; then
    echo "📋 Testing external IP: $SERVER_IP"
    echo "📋 Testing main page via IP..."
    curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_IP/us"
    
    echo "📋 Testing API via IP..."
    curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_IP/api/users"
else
    echo "⚠️  Could not determine external IP"
fi

echo ""
echo "🔍 Testing Error Pages..."
echo "================================"

# Test non-existent pages
echo "📋 Testing 404 page..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/us/nonexistent

echo "📋 Testing non-existent API..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost/api/nonexistent

echo ""
echo "📊 Testing Performance..."
echo "================================"

# Test response times
echo "📋 Testing main page response time..."
time curl -s -o /dev/null http://localhost/us/

echo "📋 Testing API response time..."
time curl -s -o /dev/null http://localhost/api/users

echo ""
echo "🔧 Testing Service Status..."
echo "================================"

# Check if services are running
echo "📊 Backend service status:"
systemctl is-active us-calendar

echo "📊 Nginx service status:"
systemctl is-active nginx

echo ""
echo "📋 Testing Port Accessibility..."
echo "================================"

# Test if ports are accessible
if netstat -tlnp | grep :80; then
    echo "✅ Port 80 is listening"
else
    echo "❌ Port 80 is not listening"
fi

if netstat -tlnp | grep :5001; then
    echo "✅ Port 5001 is listening"
else
    echo "❌ Port 5001 is not listening"
fi

echo ""
echo "🧪 Testing Browser Simulation..."
echo "================================"

# Test with browser-like headers
echo "📋 Testing with browser headers..."
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
     -o /dev/null -w "Status: %{http_code}\n" http://localhost/us/

echo ""
echo "✅ Webpage Testing Completed!"
echo ""
echo "📋 Summary:"
echo "================================"
echo "🌐 Main page: http://localhost/us"
echo "🔗 API base: http://localhost/api"
echo "📁 Static files: http://localhost/us/static/"
echo ""
echo "💡 If all tests pass, your webpage should be working correctly!"
echo "🌐 Test in browser: http://carlevato.net/us"
echo ""
echo "🔍 For detailed debugging:"
echo "   - Check nginx logs: tail -f /var/log/nginx/error.log"
echo "   - Check backend logs: journalctl -u us-calendar -f"
echo "   - Test in browser with developer tools (F12)" 