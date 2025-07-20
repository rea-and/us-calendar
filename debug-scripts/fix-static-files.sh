#!/bin/bash

# Fix static file 404 errors

echo "🔧 Fixing Static File 404 Errors..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📁 Checking Static Files..."
echo "================================"

# Check if build directory exists
if [ ! -d "/var/www/us-calendar/frontend/build" ]; then
    echo "❌ Build directory not found. Rebuilding frontend..."
    cd /opt/us-calendar/frontend
    npm run build
    exit 1
fi

# List static files
echo "📋 Static files in build directory:"
ls -la /var/www/us-calendar/frontend/build/static/js/
ls -la /var/www/us-calendar/frontend/build/static/css/

echo ""
echo "🔍 Checking Nginx Configuration..."
echo "================================"

# Check current nginx config
echo "📋 Current nginx configuration for /us location:"
grep -A 10 -B 5 "location /us" /etc/nginx/sites-available/us-calendar

echo ""
echo "🔧 Fixing Nginx Static File Configuration..."
echo "================================"

# Create a backup of the current config
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Fix the nginx configuration to properly serve static files
cat > /etc/nginx/sites-available/us-calendar << 'EOF'
server {
    listen 80;
    server_name carlevato.net www.carlevato.net;

    # API proxy
    location /api/ {
        proxy_pass http://localhost:5001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files for React app
    location /us/static/ {
        alias /var/www/us-calendar/frontend/build/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
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
echo "🔍 Testing Nginx Configuration..."
echo "================================"

# Test nginx configuration
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "🔧 Setting File Permissions..."
echo "================================"

# Set proper permissions
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

echo "✅ File permissions set"

echo ""
echo "🔄 Restarting Services..."
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
echo "🧪 Testing Static Files..."
echo "================================"

# Test static files
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
CSS_FILE=$(ls /var/www/us-calendar/frontend/build/static/css/main.*.css 2>/dev/null | head -1)

if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    echo "📋 Testing JavaScript file: $JS_FILENAME"
    curl -s -o /dev/null -w "Status: %{http_code}\n" "http://localhost/us/static/js/$JS_FILENAME"
fi

if [ -n "$CSS_FILE" ]; then
    CSS_FILENAME=$(basename "$CSS_FILE")
    echo "📋 Testing CSS file: $CSS_FILENAME"
    curl -s -o /dev/null -w "Status: %{http_code}\n" "http://localhost/us/static/css/$CSS_FILENAME"
fi

echo "📋 Testing manifest.json..."
curl -s -o /dev/null -w "Status: %{http_code}\n" "http://localhost/us/manifest.json"

echo ""
echo "🔍 Checking Nginx Logs..."
echo "================================"

# Check for errors in nginx logs
echo "📋 Recent nginx error logs:"
tail -5 /var/log/nginx/error.log

echo ""
echo "📋 Recent nginx access logs:"
tail -5 /var/log/nginx/access.log

echo ""
echo "✅ Static File Fix Completed!"
echo ""
echo "🌐 Test your webpage now:"
echo "   - Local: http://localhost/us"
echo "   - External: http://carlevato.net/us"
echo ""
echo "💡 If static files still return 404, check:"
echo "   1. File paths in nginx config"
echo "   2. File permissions"
echo "   3. Nginx error logs: tail -f /var/log/nginx/error.log" 