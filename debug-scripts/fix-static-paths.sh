#!/bin/bash

# Fix static file path issues for React build

echo "🔧 Fixing Static File Path Issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📄 Checking index.html file..."
echo "================================"

# Check the index.html file to see what paths it's expecting
echo "📋 Contents of index.html:"
head -20 /var/www/us-calendar/frontend/build/index.html

echo ""
echo "🔍 Looking for static file references..."
grep -o 'src="[^"]*"' /var/www/us-calendar/frontend/build/index.html
grep -o 'href="[^"]*"' /var/www/us-calendar/frontend/build/index.html

echo ""
echo "🔧 Fixing file permissions..."
echo "================================"

# Fix file permissions
echo "🔐 Setting correct permissions..."
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

echo ""
echo "🌐 Updating nginx configuration for better static file handling..."
echo "================================"

# Update nginx configuration to handle all possible static file paths
cat > /etc/nginx/sites-available/us-calendar << 'EOF'
server {
    listen 80;
    server_name carlaveto.net;

    # Serve React frontend at /us
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files $uri $uri/ /us/index.html;
        
        # Add headers for SPA routing
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle all static assets with proper fallbacks
    location ~* ^/us/static/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Handle static files without /us prefix (fallback)
    location ~* ^/static/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Handle other static assets (manifest.json, favicon.ico)
    location ~* ^/us/.*\.(json|ico)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Handle root level static assets
    location ~* ^/.*\.(json|ico)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # API routes
    location /api {
        proxy_pass http://localhost:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:5001/api/health;
        proxy_set_header Host $host;
    }

    # Redirect root to /us
    location = / {
        return 301 /us;
    }
}
EOF

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration failed"
    exit 1
fi

echo ""
echo "🔄 Restarting nginx..."
systemctl restart nginx

echo ""
echo "🔍 Testing static file access..."
echo "================================"

# Test if static files are accessible
echo "🧪 Testing CSS file access..."
curl -I http://localhost/us/static/css/main.18cb73c2.css 2>/dev/null | head -1

echo "🧪 Testing JS file access..."
curl -I http://localhost/us/static/js/main.542ce4b5.js 2>/dev/null | head -1

echo "🧪 Testing manifest file access..."
curl -I http://localhost/us/manifest.json 2>/dev/null | head -1

echo ""
echo "📋 Current file permissions:"
ls -la /var/www/us-calendar/frontend/build/static/css/
ls -la /var/www/us-calendar/frontend/build/static/js/

echo ""
echo "✅ Static file fixes applied!"
echo ""
echo "🌐 Test your application at:"
echo "   http://carlevato.net/us"
echo ""
echo "💡 If issues persist:"
echo "   1. Check browser developer tools (F12) for specific errors"
echo "   2. Look at the Network tab to see which files are failing"
echo "   3. Check nginx error logs: tail -f /var/log/nginx/error.log" 