#!/bin/bash

# Test external access to static files

echo "🔍 Testing External Access to Static Files..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Finding JavaScript File..."
echo "================================"

JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
else
    echo "❌ No JavaScript file found"
    exit 1
fi

echo ""
echo "🔍 Step 2: Testing Local Access..."
echo "================================"

echo "📋 Testing localhost access:"
LOCAL_RESPONSE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | head -1)
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/us/static/js/$JS_FILENAME")
echo "📋 HTTP Status: $LOCAL_STATUS"
echo "📋 First line: $LOCAL_RESPONSE"

if echo "$LOCAL_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ Local access works (contains JavaScript code)"
else
    echo "❌ Local access failed"
fi

echo ""
echo "🔍 Step 3: Testing External IP Access..."
echo "================================"

echo "📋 Testing external IP access:"
EXTERNAL_RESPONSE=$(curl -s "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
EXTERNAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://157.230.244.80/us/static/js/$JS_FILENAME")
echo "📋 HTTP Status: $EXTERNAL_STATUS"
echo "📋 First line: $EXTERNAL_RESPONSE"

if echo "$EXTERNAL_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ External access works (contains JavaScript code)"
else
    echo "❌ External access failed"
fi

echo ""
echo "🔍 Step 4: Testing Domain Access..."
echo "================================"

echo "📋 Testing domain access:"
DOMAIN_RESPONSE=$(curl -s "http://carlevato.net/us/static/js/$JS_FILENAME" | head -1)
DOMAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://carlevato.net/us/static/js/$JS_FILENAME")
echo "📋 HTTP Status: $DOMAIN_STATUS"
echo "📋 First line: $DOMAIN_RESPONSE"

if echo "$DOMAIN_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ Domain access works (contains JavaScript code)"
else
    echo "❌ Domain access failed"
fi

echo ""
echo "🔍 Step 5: Comparing File Sizes..."
echo "================================"

ACTUAL_SIZE=$(ls -l "$JS_FILE" | awk '{print $5}')
LOCAL_SIZE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | wc -c)
EXTERNAL_SIZE=$(curl -s "http://157.230.244.80/us/static/js/$JS_FILENAME" | wc -c)
DOMAIN_SIZE=$(curl -s "http://carlevato.net/us/static/js/$JS_FILENAME" | wc -c)

echo "📋 Actual file size: $ACTUAL_SIZE bytes"
echo "📋 Local served size: $LOCAL_SIZE bytes"
echo "📋 External served size: $EXTERNAL_SIZE bytes"
echo "📋 Domain served size: $DOMAIN_SIZE bytes"

echo ""
echo "🔍 Step 6: Testing Content-Type Headers..."
echo "================================"

echo "📋 Local Content-Type:"
curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type"

echo "📋 External Content-Type:"
curl -s -I "http://157.230.244.80/us/static/js/$JS_FILENAME" | grep -i "content-type"

echo "📋 Domain Content-Type:"
curl -s -I "http://carlevato.net/us/static/js/$JS_FILENAME" | grep -i "content-type"

echo ""
echo "✅ External Access Test Completed!" 