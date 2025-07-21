#!/bin/bash

# Compact client request test

echo "🔍 Compact Client Request Test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
else
    echo "❌ No JavaScript file found"
    exit 1
fi

echo "📋 Testing: $JS_FILENAME"
echo ""

# Test with Chrome User-Agent
echo "🔍 Chrome UA (localhost):"
CHROME_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
if echo "$CHROME_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML served"
elif echo "$CHROME_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript served"
else
    echo "⚠️  Unknown: $(echo "$CHROME_RESPONSE" | cut -c1-30)..."
fi

# Test external access
echo "🔍 Chrome UA (external):"
EXTERNAL_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
     "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
if echo "$EXTERNAL_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML served"
elif echo "$EXTERNAL_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript served"
else
    echo "⚠️  Unknown: $(echo "$EXTERNAL_RESPONSE" | cut -c1-30)..."
fi

# Test Content-Type
echo "🔍 Content-Type:"
CONTENT_TYPE=$(curl -s -I -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type")
echo "$CONTENT_TYPE"

# Test file size
echo "🔍 File size:"
ACTUAL_SIZE=$(ls -l "$JS_FILE" | awk '{print $5}')
SERVED_SIZE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | wc -c)
echo "Actual: $ACTUAL_SIZE bytes, Served: $SERVED_SIZE bytes"

# Test nginx location matching
echo "🔍 Nginx location test:"
curl -s "http://localhost/us/static/js/$JS_FILENAME" > /dev/null
sleep 1
echo "Access log: $(tail -1 /var/log/nginx/access.log | cut -d' ' -f6-7)"

echo ""
echo "📋 SUMMARY:"
if echo "$CHROME_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ CONFIRMED: Server is serving HTML instead of JavaScript"
    echo "🔧 This explains the client-side 'Unexpected token <' error"
elif echo "$CHROME_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ Server is serving JavaScript correctly"
    echo "🔍 Issue might be client-side caching or other browser issue"
else
    echo "⚠️  Unknown response type - needs further investigation"
fi 