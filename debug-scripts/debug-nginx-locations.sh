#!/bin/bash

# Debug nginx location handling

echo "🔍 Debugging Nginx Location Handling..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Current Nginx Configuration..."
echo "================================"

echo "📋 Current nginx configuration:"
cat /etc/nginx/sites-available/us-calendar

echo ""
echo "🔍 Step 2: Testing URL Patterns..."
echo "================================"

JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
    
    # Test different URL patterns
    echo ""
    echo "📋 Testing URL patterns:"
    
    # Pattern 1: /us/static/js/main.542ce4b5.js
    echo "1. Testing /us/static/js/$JS_FILENAME"
    RESPONSE1=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | head -5)
    echo "$RESPONSE1"
    
    # Pattern 2: /static/js/main.542ce4b5.js
    echo ""
    echo "2. Testing /static/js/$JS_FILENAME"
    RESPONSE2=$(curl -s -I "http://localhost/static/js/$JS_FILENAME" | head -5)
    echo "$RESPONSE2"
    
    # Pattern 3: Direct file access
    echo ""
    echo "3. Testing direct file content:"
    DIRECT_CONTENT=$(head -1 "$JS_FILE")
    echo "First line of actual file: $DIRECT_CONTENT"
fi

echo ""
echo "🔍 Step 3: Testing Nginx Location Matching..."
echo "================================"

# Test which location block matches
echo "📋 Testing location block matching:"

# Create a test request and check nginx logs
echo "Making test request..."
curl -s "http://localhost/us/static/js/$JS_FILENAME" > /dev/null

echo ""
echo "📋 Recent nginx access logs:"
tail -3 /var/log/nginx/access.log

echo ""
echo "📋 Recent nginx error logs:"
tail -3 /var/log/nginx/error.log

echo ""
echo "🔍 Step 4: Testing File Path Resolution..."
echo "================================"

# Test what nginx thinks the file path should be
echo "📋 Testing file path resolution:"

# Check if the file exists at the expected nginx path
NGINX_PATH="/var/www/us-calendar/frontend/build/us/static/js/$JS_FILENAME"
echo "Nginx expected path: $NGINX_PATH"
if [ -f "$NGINX_PATH" ]; then
    echo "✅ File exists at nginx expected path"
else
    echo "❌ File does NOT exist at nginx expected path"
fi

# Check the actual file path
ACTUAL_PATH="/var/www/us-calendar/frontend/build/static/js/$JS_FILENAME"
echo "Actual file path: $ACTUAL_PATH"
if [ -f "$ACTUAL_PATH" ]; then
    echo "✅ File exists at actual path"
else
    echo "❌ File does NOT exist at actual path"
fi

echo ""
echo "🔍 Step 5: Testing Different Nginx Configurations..."
echo "================================"

echo "📋 The issue is that nginx is looking for files at:"
echo "   /var/www/us-calendar/frontend/build/us/static/js/$JS_FILENAME"
echo "But the files are actually at:"
echo "   /var/www/us-calendar/frontend/build/static/js/$JS_FILENAME"
echo ""
echo "📋 This means the /us location is being applied to static files!"
echo ""
echo "🔧 Solution: We need to use a more specific location block"
echo "   that matches the exact static file path pattern." 