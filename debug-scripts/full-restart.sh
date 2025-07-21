#!/bin/bash

echo "🔄 Full restart: shutdown, rebuild, redeploy"

# Navigate to project directory
cd /opt/us-calendar

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Stop backend service
echo "🛑 Stopping backend service..."
sudo systemctl stop us-calendar

# Kill any remaining processes on port 5001
echo "🧹 Cleaning up port 5001..."
sudo pkill -f "python.*app.py" || true
sudo pkill -f "flask" || true

# Wait for cleanup
sleep 2

# Rebuild frontend
echo "🔨 Rebuilding frontend..."
cd frontend
npm run build

# Deploy frontend
echo "📦 Deploying frontend..."
cd ..
cp -r frontend/build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

# Start backend service
echo "🚀 Starting backend service..."
sudo systemctl start us-calendar

# Wait for backend to start
sleep 3

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
curl -s http://localhost:5001/api/health

echo ""
echo "✅ Full restart completed!"
echo "🎯 Try accessing https://carlevato.net now" 