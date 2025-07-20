#!/bin/bash

# Comprehensive webpage testing script for Mac client

echo "🧪 Testing Webpage from Mac Client..."

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed. Please install it first."
    exit 1
fi

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found. Install with: brew install jq"
    echo "   Continuing without JSON parsing..."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# Server configuration
SERVER_DOMAIN="carlevato.net"
SERVER_IP="157.230.244.80"

echo ""
echo "🌐 Testing External Webpage Access..."
echo "================================"

# Test main page access via domain
echo "📋 Testing main page via domain (http://$SERVER_DOMAIN/)..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/"

echo "📋 Testing /us page via domain..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/us"

echo "📋 Testing /us/ (with trailing slash) via domain..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/us/"

# Test via IP as fallback
echo ""
echo "📋 Testing via IP address ($SERVER_IP)..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_IP/us/"

echo ""
echo "📄 Testing HTML Content..."
echo "================================"

# Test if HTML content is correct
echo "📋 Checking if index.html is served correctly..."
HTML_CONTENT=$(curl -s "http://$SERVER_DOMAIN/us/")
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
    JS_FILE=$(echo "$HTML_CONTENT" | grep -o 'main\.[^"]*\.js' | head -1)
    echo "   Found: $JS_FILE"
else
    echo "❌ HTML missing JavaScript file reference"
fi

if echo "$HTML_CONTENT" | grep -q "main.*\.css"; then
    echo "✅ HTML contains CSS file reference"
    CSS_FILE=$(echo "$HTML_CONTENT" | grep -o 'main\.[^"]*\.css' | head -1)
    echo "   Found: $CSS_FILE"
else
    echo "❌ HTML missing CSS file reference"
fi

echo ""
echo "📁 Testing Static Files..."
echo "================================"

# Test static files if we found them
if [ -n "$JS_FILE" ]; then
    echo "📋 Testing JavaScript file: $JS_FILE"
    curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/us/static/js/$JS_FILE"
fi

if [ -n "$CSS_FILE" ]; then
    echo "📋 Testing CSS file: $CSS_FILE"
    curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/us/static/css/$CSS_FILE"
fi

echo "📋 Testing manifest.json..."
curl -s -o /dev/null -w "Status: %{http_code}, Size: %{size_download} bytes\n" "http://$SERVER_DOMAIN/us/manifest.json"

echo ""
echo "🔗 Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing /api/users..."
API_RESPONSE=$(curl -s "http://$SERVER_DOMAIN/api/users")
if echo "$API_RESPONSE" | grep -q "Angel\|Andrea"; then
    echo "✅ API returns user data"
    if [ "$JQ_AVAILABLE" = true ]; then
        echo "📄 Response preview:"
        echo "$API_RESPONSE" | jq '.[0:2]' 2>/dev/null || echo "$API_RESPONSE" | head -3
    else
        echo "📄 Response: $(echo "$API_RESPONSE" | head -3)"
    fi
else
    echo "❌ API not returning user data"
    echo "📄 Response: $API_RESPONSE"
fi

echo "📋 Testing /api/events..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/api/events"

echo "📋 Testing /api/health..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/api/health"

echo ""
echo "🌐 Testing HTTPS (if available)..."
echo "================================"

# Test HTTPS if available
echo "📋 Testing HTTPS main page..."
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$SERVER_DOMAIN/us/" 2>/dev/null || echo "000")
if [ "$HTTPS_STATUS" != "000" ]; then
    echo "✅ HTTPS available: Status $HTTPS_STATUS"
else
    echo "⚠️  HTTPS not available (expected if SSL not configured)"
fi

echo ""
echo "🔍 Testing Error Pages..."
echo "================================"

# Test non-existent pages
echo "📋 Testing 404 page..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/us/nonexistent"

echo "📋 Testing non-existent API..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/api/nonexistent"

echo ""
echo "📊 Testing Performance..."
echo "================================"

# Test response times
echo "📋 Testing main page response time..."
time curl -s -o /dev/null "http://$SERVER_DOMAIN/us/"

echo "📋 Testing API response time..."
time curl -s -o /dev/null "http://$SERVER_DOMAIN/api/users"

echo ""
echo "🌐 Testing DNS Resolution..."
echo "================================"

# Test DNS resolution
echo "📋 Testing DNS resolution for $SERVER_DOMAIN..."
if nslookup "$SERVER_DOMAIN" >/dev/null 2>&1; then
    echo "✅ DNS resolution successful"
    RESOLVED_IP=$(nslookup "$SERVER_DOMAIN" | grep "Address:" | tail -1 | awk '{print $2}')
    echo "   Resolved to: $RESOLVED_IP"
else
    echo "❌ DNS resolution failed"
fi

echo ""
echo "🧪 Testing Browser Simulation..."
echo "================================"

# Test with browser-like headers
echo "📋 Testing with browser headers..."
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
     -H "Accept-Language: en-US,en;q=0.9" \
     -H "Accept-Encoding: gzip, deflate" \
     -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/us/"

echo ""
echo "📱 Testing Mobile User Agent..."
echo "================================"

# Test with mobile user agent
echo "📋 Testing with mobile headers..."
curl -s -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15" \
     -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
     -o /dev/null -w "Status: %{http_code}\n" "http://$SERVER_DOMAIN/us/"

echo ""
echo "🔍 Testing Network Connectivity..."
echo "================================"

# Test basic connectivity
echo "📋 Testing ping to server..."
if ping -c 3 "$SERVER_DOMAIN" >/dev/null 2>&1; then
    echo "✅ Server is reachable"
else
    echo "❌ Server is not reachable"
fi

echo "📋 Testing port 80 connectivity..."
if nc -z "$SERVER_DOMAIN" 80 2>/dev/null; then
    echo "✅ Port 80 is open"
else
    echo "❌ Port 80 is closed"
fi

echo ""
echo "✅ Webpage Testing Completed!"
echo ""
echo "📋 Summary:"
echo "================================"
echo "🌐 Main page: http://$SERVER_DOMAIN/us"
echo "🔗 API base: http://$SERVER_DOMAIN/api"
echo "📁 Static files: http://$SERVER_DOMAIN/us/static/"
echo ""
echo "💡 If all tests pass, your webpage should be working correctly!"
echo ""
echo "🌐 Test in browser:"
echo "   - http://$SERVER_DOMAIN/us"
echo "   - http://$SERVER_IP/us (if DNS issues)"
echo ""
echo "🔍 For detailed debugging:"
echo "   - Open browser developer tools (F12)"
echo "   - Check Console tab for JavaScript errors"
echo "   - Check Network tab for failed requests"
echo "   - Test on mobile device or browser mobile simulation"
echo ""
echo "📱 Mobile Testing Tips:"
echo "   - Use Chrome DevTools mobile simulation"
echo "   - Test on actual mobile device"
echo "   - Check touch interactions and responsive design" 