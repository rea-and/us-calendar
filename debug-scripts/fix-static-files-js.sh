#!/bin/bash

# Fix JavaScript file serving issue

echo "🔧 Fixing JavaScript File Serving Issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Diagnosing the Issue..."
echo "================================"

# Check what's actually being served for JS files
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
    
    echo ""
    echo "📋 Testing what nginx serves for JS file:"
    curl -s "http://localhost/us/static/js/$JS_FILENAME" | head -5
    
    echo ""
    echo "📋 Testing what nginx serves for main page:"
    curl -s "http://localhost/us/" | head -5
    
    echo ""
    echo "📋 Comparing file sizes:"
    echo "JS file size: $(ls -lh "$JS_FILE" | awk '{print $5}')"
    echo "HTML response size: $(curl -s "http://localhost/us/static/js/$JS_FILENAME" | wc -c) bytes"
else
    echo "❌ JavaScript file not found"
    exit 1
fi

echo ""
echo "🔧 Step 2: Checking Nginx Configuration..."
echo "================================"

# Check current nginx config
echo "📋 Current nginx configuration for static files:"
grep -A 10 -B 5 "location.*static" /etc/nginx/sites-available/us-calendar

echo ""
echo "🔧 Step 3: Fixing Nginx Configuration..."
echo "================================"

# Create backup
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Fix nginx configuration to properly serve static files
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

    # Static files for React app - MUST come before /us location
    location ~* ^/us/static/(.*)$ {
        alias /var/www/us-calendar/frontend/build/static/$1;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Content-Type "application/javascript" always;
        try_files $uri =404;
    }

    # React app routes
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files $uri $uri/ /us/index.html;
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
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

echo "✅ Nginx configuration updated"

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
echo "🧪 Step 7: Testing Static File Serving..."
echo "================================"

# Wait a moment for nginx to fully start
sleep 2

# Test static file serving
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 Testing JavaScript file serving: $JS_FILENAME"
    
    # Test the response
    RESPONSE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME")
    if echo "$RESPONSE" | head -1 | grep -q "function\|var\|const\|let\|import"; then
        echo "✅ JavaScript file served correctly (contains JS code)"
        echo "📋 First line: $(echo "$RESPONSE" | head -1 | cut -c1-50)..."
    elif echo "$RESPONSE" | head -1 | grep -q "<!DOCTYPE\|<html"; then
        echo "❌ JavaScript file still serving HTML"
        echo "📋 First line: $(echo "$RESPONSE" | head -1 | cut -c1-50)..."
    else
        echo "⚠️  Unknown response type"
        echo "📋 First line: $(echo "$RESPONSE" | head -1 | cut -c1-50)..."
    fi
    
    # Test content type
    CONTENT_TYPE=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type")
    echo "📋 Content-Type: $CONTENT_TYPE"
fi

echo ""
echo "🔍 Step 8: Testing CSS File Serving..."
echo "================================"

# Test CSS file
CSS_FILE=$(ls /var/www/us-calendar/frontend/build/static/css/main.*.css 2>/dev/null | head -1)
if [ -n "$CSS_FILE" ]; then
    CSS_FILENAME=$(basename "$CSS_FILE")
    echo "📋 Testing CSS file serving: $CSS_FILENAME"
    
    RESPONSE=$(curl -s "http://localhost/us/static/css/$CSS_FILENAME")
    if echo "$RESPONSE" | head -1 | grep -q "{"; then
        echo "✅ CSS file served correctly (contains CSS code)"
    else
        echo "❌ CSS file not serving correctly"
    fi
fi

echo ""
echo "🔍 Step 9: Testing Main Page..."
echo "================================"

# Test main page
echo "📋 Testing main page:"
RESPONSE=$(curl -s "http://localhost/us/")
if echo "$RESPONSE" | grep -q "main.*\.js"; then
    echo "✅ Main page contains JavaScript reference"
    echo "📋 JS reference: $(echo "$RESPONSE" | grep -o 'main\.[^"]*\.js' | head -1)"
else
    echo "❌ Main page missing JavaScript reference"
fi

echo ""
echo "✅ Static File Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - http://157.230.244.80/us"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 If still having issues:"
echo "   1. Clear browser cache completely"
echo "   2. Check browser console for errors"
echo "   3. Try different browser"
echo "   4. Check the monitoring script results"
echo ""
echo "💡 The key fix was:"
echo "   - Using regex location for static files"
echo "   - Setting proper Content-Type headers"
echo "   - Ensuring static location comes before /us location" 