#!/bin/bash

# Fix MIME type issue - nginx serving HTML instead of JavaScript

echo "🔧 Fixing MIME Type Issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Confirming the Issue..."
echo "================================"

echo "📋 The error shows:"
echo "   - MIME type 'text/html' instead of 'application/javascript'"
echo "   - Server is serving HTML instead of JavaScript"
echo "   - This happens when nginx location blocks don't match correctly"

# Find the JavaScript file
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
else
    echo "❌ No JavaScript file found"
    exit 1
fi

echo ""
echo "🔍 Step 2: Testing Current MIME Type..."
echo "================================"

# Test what MIME type is currently being served
echo "📋 Testing current MIME type:"
MIME_TYPE=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type" | head -1)
echo "📋 Current MIME type: $MIME_TYPE"

if echo "$MIME_TYPE" | grep -q "text/html"; then
    echo "❌ CONFIRMED: HTML MIME type being served"
    echo "📋 This explains the Firefox error"
elif echo "$MIME_TYPE" | grep -q "application/javascript"; then
    echo "✅ JavaScript MIME type being served"
    echo "📋 Issue might be elsewhere"
else
    echo "⚠️  Unknown MIME type"
fi

echo ""
echo "🔧 Step 3: Creating MIME Type Fix..."
echo "================================"

# Create backup
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Create a completely new nginx configuration with explicit MIME types
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

    # JavaScript files - explicit MIME type
    location ~* \.js$ {
        root /var/www/us-calendar/frontend/build;
        add_header Content-Type "application/javascript" always;
        add_header Cache-Control "public, max-age=31536000" always;
        expires 1y;
        try_files $uri =404;
    }

    # CSS files - explicit MIME type
    location ~* \.css$ {
        root /var/www/us-calendar/frontend/build;
        add_header Content-Type "text/css" always;
        add_header Cache-Control "public, max-age=31536000" always;
        expires 1y;
        try_files $uri =404;
    }

    # Other static files
    location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # React app routes - must come last
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files $uri $uri/ /us/index.html;
        add_header Content-Type "text/html" always;
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

echo "✅ MIME type fix configuration created"

echo ""
echo "🔍 Step 4: Testing Nginx Configuration..."
echo "================================"

# Test nginx config
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "🔧 Step 5: Setting File Permissions..."
echo "================================"

# Set proper permissions
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

echo "✅ File permissions set"

echo ""
echo "🔄 Step 6: Restarting Nginx..."
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
echo "🧪 Step 7: Testing Fixed MIME Type..."
echo "================================"

# Wait for nginx to fully start
sleep 3

# Test the MIME type
echo "📋 Testing MIME type after fix:"
NEW_MIME_TYPE=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type" | head -1)
echo "📋 New MIME type: $NEW_MIME_TYPE"

if echo "$NEW_MIME_TYPE" | grep -q "application/javascript"; then
    echo "✅ JavaScript MIME type now being served"
elif echo "$NEW_MIME_TYPE" | grep -q "text/html"; then
    echo "❌ Still serving HTML MIME type"
else
    echo "⚠️  Unknown MIME type"
fi

# Test the actual content
echo "📋 Testing content:"
CONTENT=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | head -1)
if echo "$CONTENT" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
    echo "✅ JavaScript content being served"
elif echo "$CONTENT" | grep -q "<!DOCTYPE\|<html"; then
    echo "❌ HTML content still being served"
else
    echo "⚠️  Unknown content type"
fi

echo ""
echo "🔍 Step 8: Testing External Access..."
echo "================================"

# Test external access
echo "📋 Testing external MIME type:"
EXTERNAL_MIME_TYPE=$(curl -s -I "http://157.230.244.80/us/static/js/$JS_FILENAME" | grep -i "content-type" | head -1)
echo "📋 External MIME type: $EXTERNAL_MIME_TYPE"

if echo "$EXTERNAL_MIME_TYPE" | grep -q "application/javascript"; then
    echo "✅ External access serving JavaScript MIME type"
else
    echo "❌ External access still has MIME type issues"
fi

echo ""
echo "🔍 Step 9: Testing with Firefox User-Agent..."
echo "================================"

# Test with Firefox User-Agent specifically
echo "📋 Testing with Firefox User-Agent:"
FIREFOX_MIME_TYPE=$(curl -s -I -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0" \
     "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type" | head -1)
echo "📋 Firefox MIME type: $FIREFOX_MIME_TYPE"

if echo "$FIREFOX_MIME_TYPE" | grep -q "application/javascript"; then
    echo "✅ Firefox receiving JavaScript MIME type"
else
    echo "❌ Firefox still receiving wrong MIME type"
fi

echo ""
echo "✅ MIME Type Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - http://157.230.244.80/us"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 If still having issues:"
echo "   1. Clear browser cache completely"
echo "   2. Try Firefox in private mode"
echo "   3. Check browser developer tools"
echo "   4. Test with different browsers"
echo ""
echo "💡 Key changes made:"
echo "   - Used file extension location blocks (.js, .css)"
echo "   - Set explicit Content-Type headers"
echo "   - Used root directive instead of alias for static files"
echo "   - Ensured proper location priority" 