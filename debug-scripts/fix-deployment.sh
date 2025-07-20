#!/bin/bash

# Fix script for Our Calendar deployment issues

echo "🔧 Fixing Our Calendar Deployment Issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔧 Fixing Backend Database Issue..."
echo "================================"

# Stop the backend service
echo "🛑 Stopping backend service..."
systemctl stop us-calendar

# Navigate to backend directory
cd /var/www/us-calendar/backend

# Activate virtual environment
source ../venv/bin/activate

# Create database tables
echo "🗄️  Creating database tables..."
python -c "
from app import app, db
with app.app_context():
    db.create_all()
    print('✅ Database tables created successfully')
"

# Check if tables were created
echo "📋 Verifying database tables..."
python -c "
from app import app, db
from models import User, Event
with app.app_context():
    try:
        users = User.query.all()
        events = Event.query.all()
        print(f'✅ Database verified: {len(users)} users, {len(events)} events')
    except Exception as e:
        print(f'❌ Database verification failed: {e}')
"

echo ""
echo "🌐 Fixing Nginx Static Files Issue..."
echo "================================"

# Check current nginx configuration
echo "📋 Current nginx configuration:"
grep -A 5 -B 5 "location /us" /etc/nginx/sites-available/us-calendar

# Fix nginx configuration for static files
echo "🔧 Updating nginx configuration..."
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

    # Handle static assets for React build (CSS, JS, images)
    location ~* ^/us/static/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle other static assets (manifest.json, favicon.ico)
    location ~* ^/us/.*\.(json|ico)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
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
echo "🚀 Starting Services..."
echo "================================"

# Start backend service
echo "🔧 Starting backend service..."
systemctl start us-calendar

# Wait a moment for backend to start
sleep 3

# Check backend status
echo "📊 Backend service status:"
systemctl status us-calendar --no-pager

# Restart nginx
echo "🌐 Restarting nginx..."
systemctl restart nginx

# Check nginx status
echo "📊 Nginx service status:"
systemctl status nginx --no-pager

echo ""
echo "🔍 Verifying fixes..."
echo "================================"

# Check if port 5001 is now in use
if netstat -tlnp | grep :5001; then
    echo "✅ Backend is running on port 5001"
else
    echo "❌ Backend is not running on port 5001"
fi

# Check if static files exist
echo "📁 Checking static files:"
if [ -f "/var/www/us-calendar/frontend/build/static/js/main.js" ] || [ -f "/var/www/us-calendar/frontend/build/static/js/main.*.js" ]; then
    echo "✅ JavaScript files found"
else
    echo "❌ JavaScript files missing"
fi

if [ -f "/var/www/us-calendar/frontend/build/static/css/main.css" ] || [ -f "/var/www/us-calendar/frontend/build/static/css/main.*.css" ]; then
    echo "✅ CSS files found"
else
    echo "❌ CSS files missing"
fi

echo ""
echo "✅ Fixes applied successfully!"
echo ""
echo "🌐 Your application should now be available at:"
echo "   http://carlevato.net/us"
echo ""
echo "📋 If issues persist, check:"
echo "   - Backend logs: journalctl -u us-calendar -f"
echo "   - Nginx logs: tail -f /var/log/nginx/error.log"
echo "   - Frontend build: ls -la /var/www/us-calendar/frontend/build/" 