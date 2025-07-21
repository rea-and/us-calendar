#!/bin/bash

echo "🔧 Fixing empty frontend page..."

# Navigate to project directory
cd /opt/us-calendar

# Check if backend is running
echo "🔍 Checking backend status..."
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Backend service is running"
else
    echo "❌ Backend service is not running"
    sudo systemctl status us-calendar --no-pager
    exit 1
fi

# Test API endpoint
echo "🧪 Testing API endpoint..."
API_RESPONSE=$(curl -s http://localhost:5001/api/health)
if [ $? -eq 0 ]; then
    echo "✅ API is responding: $API_RESPONSE"
else
    echo "❌ API is not responding"
    exit 1
fi

# Rebuild frontend
echo "🔨 Rebuilding frontend..."
cd frontend
npm run build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Frontend build successful"
else
    echo "❌ Frontend build failed"
    exit 1
fi

# Deploy frontend
echo "📦 Deploying frontend..."
cd ..
cp -r frontend/build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

# Check nginx configuration
echo "🔍 Checking nginx configuration..."
sudo nginx -t

# Restart nginx
echo "🔄 Restarting nginx..."
sudo systemctl restart nginx

# Check nginx status
echo "📊 Nginx status:"
sudo systemctl status nginx --no-pager

# Test frontend access
echo "🧪 Testing frontend access..."
FRONTEND_RESPONSE=$(curl -s -I https://carlevato.net | head -1)
echo "Frontend response: $FRONTEND_RESPONSE"

echo ""
echo "✅ Frontend fix completed!"
echo "🎯 Try accessing https://carlevato.net now"
echo "📋 If still empty, check browser console for errors" 