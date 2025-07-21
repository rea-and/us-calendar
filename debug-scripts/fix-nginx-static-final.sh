#!/bin/bash

# Final fix for nginx static file serving

echo "🔧 Final Nginx Static File Fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Analyzing Current Issue..."
echo "================================"

# Check what's happening with static files
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 JavaScript file: $JS_FILENAME"
    echo "📋 Actual file path: $JS_FILE"
    
    echo ""
    echo "📋 Testing direct file access:"
    if [ -f "$JS_FILE" ]; then
        echo "✅ File exists"
        echo "📋 File size: $(ls -lh "$JS_FILE" | awk '{print $5}')"
        echo "📋 File permissions: $(ls -la "$JS_FILE" | awk '{print $1}')"
    else
        echo "❌ File does not exist"
        exit 1
    fi
fi

echo ""
echo "🔧 Step 2: Creating New Nginx Configuration..."
echo "================================"

# Create backup
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Create a completely new nginx configuration
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

    # JavaScript files
    location ~* \.js$ {
        root /var/www/us-calendar/frontend/build;
        try_files $uri =404;
        add_header Content-Type "application/javascript" always;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # CSS files
    location ~* \.css$ {
        root /var/www/us-calendar/frontend/build;
        try_files $uri =404;
        add_header Content-Type "text/css" always;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Other static files (images, fonts, etc.)
    location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /var/www/us-calendar/frontend/build;
        try_files $uri =404;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # React app routes - must come last
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

echo "✅ New nginx configuration created"

echo ""
echo "🔍 Step 3: Testing Nginx Configuration..."
echo "================================"

# Test nginx config
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "🔧 Step 4: Setting File Permissions..."
echo "================================"

# Set proper permissions
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

echo "✅ File permissions set"

echo ""
echo "🔄 Step 5: Restarting Nginx..."
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
echo "🧪 Step 6: Testing Static File Serving..."
echo "================================"

# Wait for nginx to fully start
sleep 3

# Test JavaScript file serving
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 Testing JavaScript file: $JS_FILENAME"
    
    # Test the response
    RESPONSE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME")
    if echo "$RESPONSE" | head -1 | grep -q "function\|var\|const\|let\|import\|webpack"; then
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
    
    # Test file size
    ACTUAL_SIZE=$(ls -l "$JS_FILE" | awk '{print $5}')
    SERVED_SIZE=$(curl -s "http://localhost/us/static/js/$JS_FILENAME" | wc -c)
    echo "📋 Actual file size: $ACTUAL_SIZE bytes"
    echo "📋 Served file size: $SERVED_SIZE bytes"
fi

echo ""
echo "🔍 Step 7: Testing CSS File Serving..."
echo "================================"

# Test CSS file
CSS_FILE=$(ls /var/www/us-calendar/frontend/build/static/css/main.*.css 2>/dev/null | head -1)
if [ -n "$CSS_FILE" ]; then
    CSS_FILENAME=$(basename "$CSS_FILE")
    echo "📋 Testing CSS file: $CSS_FILENAME"
    
    RESPONSE=$(curl -s "http://localhost/us/static/css/$CSS_FILENAME")
    if echo "$RESPONSE" | head -1 | grep -q "{"; then
        echo "✅ CSS file served correctly (contains CSS code)"
    else
        echo "❌ CSS file not serving correctly"
        echo "📋 First line: $(echo "$RESPONSE" | head -1 | cut -c1-50)..."
    fi
fi

echo ""
echo "🔍 Step 8: Testing Main Page..."
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
echo "🔍 Step 9: Testing External Access..."
echo "================================"

# Test external access
echo "📋 Testing external IP access:"
EXTERNAL_RESPONSE=$(curl -s "http://157.230.244.80/us/static/js/$JS_FILENAME" | head -1)
if echo "$EXTERNAL_RESPONSE" | grep -q "function\|var\|const\|let\|import\|webpack"; then
    echo "✅ External access to JavaScript file works"
else
    echo "❌ External access to JavaScript file failed"
    echo "📋 First line: $(echo "$EXTERNAL_RESPONSE" | head -1 | cut -c1-50)..."
fi

echo ""
echo "✅ Final Nginx Static File Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - http://157.230.244.80/us"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 If still having issues:"
echo "   1. Clear browser cache completely"
echo "   2. Check browser console for errors"
echo "   3. Try different browser"
echo "   4. Check nginx error logs: tail -f /var/log/nginx/error.log"
echo ""
echo "💡 Key changes made:"
echo "   - Used file extension-based location blocks"
echo "   - Set proper Content-Type headers for each file type"
echo "   - Used root directive instead of alias for static files"
echo "   - Ensured proper location order" 