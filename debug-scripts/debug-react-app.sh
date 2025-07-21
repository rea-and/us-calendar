#!/bin/bash

# Debug React app issues

echo "🐛 Debugging React App Issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📁 Checking React Build Files..."
echo "================================"

# Check if build directory exists
if [ ! -d "/var/www/us-calendar/frontend/build" ]; then
    echo "❌ Build directory not found!"
    exit 1
fi

echo "✅ Build directory exists"

# List build files
echo ""
echo "📋 Build directory contents:"
ls -la /var/www/us-calendar/frontend/build/

echo ""
echo "📋 Static files:"
ls -la /var/www/us-calendar/frontend/build/static/js/
ls -la /var/www/us-calendar/frontend/build/static/css/

echo ""
echo "🔍 Checking index.html..."
echo "================================"

# Check index.html content
echo "📋 index.html content:"
cat /var/www/us-calendar/frontend/build/index.html

echo ""
echo "🔍 Checking JavaScript Files..."
echo "================================"

# Check main JavaScript file
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    echo "📋 Main JavaScript file: $JS_FILE"
    echo "📋 File size: $(ls -lh "$JS_FILE" | awk '{print $5}')"
    
    # Check for API URL configuration
    echo ""
    echo "🔍 Looking for API URL configuration..."
    if grep -q "localhost:5001" "$JS_FILE"; then
        echo "✅ Found localhost:5001 API URL"
    fi
    
    if grep -q "carlevato.net" "$JS_FILE"; then
        echo "✅ Found carlevato.net API URL"
    fi
    
    if grep -q "https://" "$JS_FILE"; then
        echo "⚠️  Found HTTPS URLs in JavaScript"
        grep -o "https://[^\"]*" "$JS_FILE" | head -5
    fi
    
    # Check for common React errors
    echo ""
    echo "🔍 Checking for common React issues..."
    if grep -q "Cannot read property" "$JS_FILE"; then
        echo "⚠️  Found potential null reference errors"
    fi
    
    if grep -q "undefined" "$JS_FILE"; then
        echo "⚠️  Found undefined references"
    fi
else
    echo "❌ JavaScript file not found"
fi

echo ""
echo "🔍 Checking CSS Files..."
echo "================================"

# Check main CSS file
CSS_FILE=$(ls /var/www/us-calendar/frontend/build/static/css/main.*.css 2>/dev/null | head -1)
if [ -n "$CSS_FILE" ]; then
    echo "📋 Main CSS file: $CSS_FILE"
    echo "📋 File size: $(ls -lh "$CSS_FILE" | awk '{print $5}')"
else
    echo "❌ CSS file not found"
fi

echo ""
echo "🔍 Testing React App Loading..."
echo "================================"

# Test if React app loads properly
echo "📋 Testing React app HTML response..."
HTML_RESPONSE=$(curl -s http://localhost/us/)
if echo "$HTML_RESPONSE" | grep -q "root"; then
    echo "✅ React root div found"
else
    echo "❌ React root div not found"
fi

if echo "$HTML_RESPONSE" | grep -q "main.*\.js"; then
    echo "✅ JavaScript file reference found"
else
    echo "❌ JavaScript file reference not found"
fi

echo ""
echo "🔍 Checking API Configuration..."
echo "================================"

# Check if API is accessible from React app perspective
echo "📋 Testing API from localhost..."
API_RESPONSE=$(curl -s http://localhost/api/users)
if echo "$API_RESPONSE" | grep -q "Angel\|Andrea"; then
    echo "✅ API accessible from localhost"
else
    echo "❌ API not accessible from localhost"
fi

echo ""
echo "🔍 Checking for CORS Issues..."
echo "================================"

# Test CORS headers
echo "📋 Testing CORS headers..."
curl -s -I http://localhost/api/users | grep -i "access-control"

echo ""
echo "🔍 Checking Nginx Configuration for React..."
echo "================================"

# Check nginx config for React app
echo "📋 Nginx configuration for /us location:"
grep -A 10 "location /us" /etc/nginx/sites-available/us-calendar

echo ""
echo "🔍 Testing Static File Serving..."
echo "================================"

# Test static file serving
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 Testing JavaScript file serving: $JS_FILENAME"
    curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | head -1
fi

if [ -n "$CSS_FILE" ]; then
    CSS_FILENAME=$(basename "$CSS_FILE")
    echo "📋 Testing CSS file serving: $CSS_FILENAME"
    curl -s -I "http://localhost/us/static/css/$CSS_FILENAME" | head -1
fi

echo ""
echo "🔍 Checking for Common React Issues..."
echo "================================"

echo "💡 Common React app issues:"
echo "1. JavaScript errors in browser console"
echo "2. API URL mismatch (HTTPS vs HTTP)"
echo "3. CORS issues"
echo "4. Missing dependencies"
echo "5. Browser compatibility issues"
echo ""
echo "🔍 To debug further:"
echo "1. Open browser developer tools (F12)"
echo "2. Check Console tab for JavaScript errors"
echo "3. Check Network tab for failed requests"
echo "4. Try different browser (Chrome, Firefox)"
echo "5. Clear browser cache completely"
echo ""
echo "✅ React App Debug Completed!" 