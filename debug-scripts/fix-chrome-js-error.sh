#!/bin/bash

# Fix Chrome JavaScript syntax error

echo "🔧 Fixing Chrome JavaScript Syntax Error..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Diagnosing the Issue..."
echo "================================"

echo "📋 The error 'Uncaught SyntaxError: Unexpected token <' means"
echo "📋 Chrome is receiving HTML instead of JavaScript code."
echo "📋 This usually happens when nginx serves index.html instead of the JS file."

# Find the JavaScript file
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
    echo "📋 Actual file path: $JS_FILE"
else
    echo "❌ No JavaScript file found"
    exit 1
fi

echo ""
echo "🔍 Step 2: Testing Current File Serving..."
echo "================================"

# Test what's actually being served
echo "📋 Testing what Chrome would receive:"
RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line received: $RESPONSE"

if echo "$RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ CONFIRMED: HTML is being served instead of JavaScript"
    echo "📋 This is the root cause of the Chrome error"
elif echo "$RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript is being served correctly"
    echo "📋 The issue might be browser caching"
else
    echo "⚠️  Unknown response type"
fi

echo ""
echo "🔍 Step 3: Testing External Access..."
echo "================================"

# Test external access
echo "📋 Testing external IP access:"
EXTERNAL_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
echo "📋 External first line: $EXTERNAL_RESPONSE"

if echo "$EXTERNAL_RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ External access also serving HTML"
else
    echo "✅ External access serving JavaScript"
fi

echo ""
echo "🔧 Step 4: Creating Chrome-Specific Nginx Fix..."
echo "================================"

# Create backup
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Create a Chrome-specific nginx configuration
cat > /etc/nginx/sites-available/us-calendar << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name carlevato.net www.carlevato.net _;

    # API proxy
    location /api/ {
        proxy_pass http://localhost:5001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files - MUST come before /us location with exact matching
    location = /us/static/js/main.542ce4b5.js {
        alias /var/www/us-calendar/frontend/build/static/js/main.542ce4b5.js;
        add_header Content-Type "application/javascript" always;
        add_header Cache-Control "public, max-age=31536000" always;
        expires 1y;
    }

    location = /us/static/css/main.18cb73c2.css {
        alias /var/www/us-calendar/frontend/build/static/css/main.18cb73c2.css;
        add_header Content-Type "text/css" always;
        add_header Cache-Control "public, max-age=31536000" always;
        expires 1y;
    }

    # General static files fallback
    location ~* ^/us/static/(.*)$ {
        alias /var/www/us-calendar/frontend/build/static/$1;
        add_header Cache-Control "public, max-age=31536000" always;
        expires 1y;
        try_files $uri =404;
    }

    # React app routes - must come last
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files $uri $uri/ /us/index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        expires -1;
    }

    # Root redirect to /us
    location = / {
        return 301 /us/;
    }

    # Default location
    location / {
        return 301 /us/;
    }
}
EOF

echo "✅ Chrome-specific nginx configuration created"

echo ""
echo "🔍 Step 5: Testing Nginx Configuration..."
echo "================================"

# Test nginx config
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "🔧 Step 6: Setting File Permissions..."
echo "================================"

# Set proper permissions
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

echo "✅ File permissions set"

echo ""
echo "🔄 Step 7: Restarting Nginx..."
echo "================================"

# Restart nginx
systemctl restart nginx
if systemctl is-active nginx; then
    echo "✅ Nginx restarted successfully"
else
    echo "❌ Nginx failed to restart"
    exit 1
fi

echo ""
echo "🧪 Step 8: Testing Fixed File Serving..."
echo "================================"

# Wait for nginx to fully start
sleep 3

# Test the specific JavaScript file
echo "📋 Testing JavaScript file serving:"
RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://localhost/us/static/js/$JS_FILENAME" | head -1)
echo "📋 First line: $RESPONSE"

if echo "$RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript file served correctly (contains JS code)"
elif echo "$RESPONSE" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ JavaScript file still serving HTML"
else
    echo "⚠️  Unknown response type"
fi

# Test content type
CONTENT_TYPE=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type")
echo "📋 Content-Type: $CONTENT_TYPE"

# Test file size
ACTUAL_SIZE=$(ls -l "$JS_FILE" | awk '{print $5}')
SERVED_SIZE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | wc -c)
echo "📋 Actual file size: $ACTUAL_SIZE bytes"
echo "📋 Served file size: $SERVED_SIZE bytes"

echo ""
echo "🔍 Step 9: Testing External Access..."
echo "================================"

# Test external access
echo "📋 Testing external IP access:"
EXTERNAL_RESPONSE=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
echo "📋 External first line: $EXTERNAL_RESPONSE"

if echo "$EXTERNAL_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ External access serving JavaScript correctly"
else
    echo "❌ External access still has issues"
fi

echo ""
echo "🔍 Step 10: Browser Cache Instructions..."
echo "================================"

echo "📋 IMPORTANT: Clear Chrome cache completely:"
echo "   1. Open Chrome"
echo "   2. Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)"
echo "   3. Set time range to 'All time'"
echo "   4. Check all boxes"
echo "   5. Click 'Clear data'"
echo "   6. Restart Chrome"
echo ""
echo "📋 Alternative: Use Chrome Incognito mode"
echo "   - Press Ctrl+Shift+N (or Cmd+Shift+N on Mac)"
echo "   - Go to http://157.230.244.80/us/"
echo ""

echo "✅ Chrome JavaScript Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - http://157.230.244.80/us"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 If still having issues:"
echo "   1. Clear Chrome cache completely"
echo "   2. Try Chrome Incognito mode"
echo "   3. Check Chrome DevTools Console"
echo "   4. Try a different browser"
echo ""
echo "💡 Key changes made:"
echo "   - Added exact location matching for main JS file"
echo "   - Set explicit Content-Type headers"
echo "   - Added cache control headers"
echo "   - Ensured proper location priority" 