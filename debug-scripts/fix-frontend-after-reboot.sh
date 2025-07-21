#!/bin/bash

echo "🔧 Fixing frontend after reboot..."

# 1. Check if backend is running
echo "🔍 Checking backend status..."
if curl -s http://localhost:5001/api/health >/dev/null; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend is not responding, starting it..."
    sudo systemctl start us-calendar
    sleep 5
fi

# 2. Rebuild frontend
echo "🔨 Rebuilding frontend..."
cd /opt/us-calendar/frontend
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed!"
    exit 1
fi

# 3. Deploy frontend
echo "📦 Deploying frontend..."
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 4. Test backend endpoints
echo "🧪 Testing backend endpoints..."
echo "Health endpoint:"
curl -s http://localhost:5001/api/health
echo ""

echo "Users endpoint:"
curl -s http://localhost:5001/api/users
echo ""

echo "Events endpoint:"
curl -s http://localhost:5001/api/events
echo ""

# 5. Test frontend
echo "🧪 Testing frontend..."
if curl -s http://localhost/ | grep -q "calendar"; then
    echo "✅ Frontend is loading properly"
else
    echo "❌ Frontend might have issues"
    echo "📋 Frontend response:"
    curl -s http://localhost/ | head -10
fi

# 6. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 7. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Frontend fix after reboot completed!" 