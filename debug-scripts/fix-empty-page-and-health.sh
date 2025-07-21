#!/bin/bash

echo "🔧 Fixing empty page and health endpoint issues..."

# 1. Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# 2. Check if models.py has the fix
echo "🔍 Checking models.py for extend_existing fix..."
if grep -q "extend_existing" backend/models.py; then
    echo "✅ extend_existing fix found in models.py"
else
    echo "❌ extend_existing fix NOT found - this is the problem!"
    echo "📋 Current models.py content:"
    head -20 backend/models.py
    exit 1
fi

# 3. Stop the service
echo "🛑 Stopping us-calendar service..."
sudo systemctl stop us-calendar

# 4. Kill any remaining processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "flask" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 5. Rebuild frontend
echo "🔨 Rebuilding frontend..."
cd frontend
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed!"
    exit 1
fi

# 6. Deploy frontend
echo "📦 Deploying frontend..."
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 7. Start the service
echo "🚀 Starting us-calendar service..."
sudo systemctl start us-calendar

# 8. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 9. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 10. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 2

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

echo "Testing /api/events:"
curl -s http://localhost:5001/api/events
echo ""

# 11. Test frontend
echo "🧪 Testing frontend..."
if curl -s http://localhost/ | grep -q "calendar"; then
    echo "✅ Frontend is loading properly"
else
    echo "❌ Frontend might have issues"
    echo "📋 Frontend response:"
    curl -s http://localhost/ | head -10
fi

# 12. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Fix completed!" 