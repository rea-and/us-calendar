#!/bin/bash

# Test what client browsers actually receive

echo "🔍 Testing Client Browser Request..."

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
echo "🔍 Step 2: Testing with Chrome User-Agent..."
echo "================================"

echo "📋 Testing with Chrome User-Agent (localhost):"
CHROME_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $CHROME_RESPONSE"

if echo "$CHROME_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ CONFIRMED: HTML is being served to Chrome"
    echo "📋 This explains the client-side error"
elif echo "$CHROME_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript is being served to Chrome"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 3: Testing with Safari User-Agent..."
echo "================================"

echo "📋 Testing with Safari User-Agent (localhost):"
SAFARI_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $SAFARI_RESPONSE"

if echo "$SAFARI_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML is being served to Safari"
elif echo "$SAFARI_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript is being served to Safari"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 4: Testing External Access with Chrome UA..."
echo "================================"

echo "📋 Testing external IP with Chrome User-Agent:"
EXTERNAL_CHROME_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
     "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $EXTERNAL_CHROME_RESPONSE"

if echo "$EXTERNAL_CHROME_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ External access also serving HTML to Chrome"
elif echo "$EXTERNAL_CHROME_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ External access serving JavaScript to Chrome"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 5: Testing with Accept Headers..."
echo "================================"

echo "📋 Testing with JavaScript Accept header:"
ACCEPT_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -H "Accept: application/javascript, text/javascript, */*" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $ACCEPT_RESPONSE"

if echo "$ACCEPT_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML served even with JavaScript Accept header"
elif echo "$ACCEPT_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript served with Accept header"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 6: Testing with Referer Header..."
echo "================================"

echo "📋 Testing with Referer header:"
REFERER_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -H "Referer: http://157.230.244.80/us/" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $REFERER_RESPONSE"

if echo "$REFERER_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML served with Referer header"
elif echo "$REFERER_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript served with Referer header"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 7: Testing Full HTTP Response..."
echo "================================"

echo "📋 Full HTTP response headers:"
curl -s -I -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME"

echo ""
echo "📋 Full HTTP response body (first 5 lines):"
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -5

echo ""
echo "🔍 Step 8: Testing Different URL Patterns..."
echo "================================"

echo "📋 Testing /static/js/$JS_FILENAME (without /us prefix):"
NO_US_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $NO_US_RESPONSE"

if echo "$NO_US_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML served without /us prefix"
elif echo "$NO_US_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript served without /us prefix"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 9: Checking Nginx Location Matching..."
echo "================================"

echo "📋 Current nginx configuration for static files:"
grep -A 10 -B 5 "static" /etc/nginx/sites-available/us-calendar

echo ""
echo "📋 Testing which location block matches:"
echo "Requesting: /us/static/js/$JS_FILENAME"
curl -s "http://localhost/us/static/js/$JS_FILENAME" > /dev/null
sleep 1
echo "Recent nginx access log:"
tail -1 /var/log/nginx/access.log

echo ""
echo "✅ Client Request Test Completed!"
echo ""
echo "📋 SUMMARY:"
echo "=========="
echo "If any test shows HTML being served, that explains the client error."
echo "The issue is that nginx is serving index.html instead of the JS file."
echo ""
echo "🔧 NEXT STEPS:"
echo "=============="
echo "1. If HTML is being served, we need to fix nginx location blocks"
echo "2. If JavaScript is being served, the issue is client-side caching"
echo "3. Check the nginx access logs to see which location block is matching" 