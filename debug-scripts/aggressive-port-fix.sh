#!/bin/bash

echo "🔧 Aggressive port conflict fix..."

# Stop the service first
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# Wait a moment
sleep 2

# Kill ALL Python processes aggressively
echo "🧹 Aggressively killing all Python processes..."
sudo pkill -9 -f "python" || true
sudo pkill -9 -f "flask" || true
sudo pkill -9 -f "app.py" || true

# Wait for processes to be killed
echo "⏳ Waiting for processes to be killed..."
sleep 5

# Check what's using port 5001
echo "🔍 Checking what's using port 5001..."
lsof -i:5001 || echo "No processes found on port 5001"

# Force kill anything on port 5001
echo "🛑 Force killing anything on port 5001..."
sudo lsof -ti:5001 | xargs -r sudo kill -9

# Wait again
sleep 3

# Double-check port is free
echo "🔍 Double-checking port 5001..."
if lsof -ti:5001 > /dev/null 2>&1; then
    echo "❌ Port 5001 is still in use!"
    echo "🔍 Current processes using port 5001:"
    lsof -i:5001
    echo "🛑 Force killing again..."
    sudo lsof -ti:5001 | xargs -r sudo kill -9
    sleep 2
else
    echo "✅ Port 5001 is now free"
fi

# Check if there are any remaining Python processes
echo "🔍 Checking for remaining Python processes..."
ps aux | grep python | grep -v grep || echo "No Python processes found"

# Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# Check service file
echo "📋 Checking service file..."
sudo cat /etc/systemd/system/us-calendar.service

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 10

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API multiple times
echo "🧪 Testing API..."
for i in {1..3}; do
    echo "Attempt $i:"
    API_RESPONSE=$(curl -s http://localhost:5001/api/health)
    if [ $? -eq 0 ]; then
        echo "✅ API is responding: $API_RESPONSE"
        break
    else
        echo "❌ API attempt $i failed"
        sleep 2
    fi
done

# Show recent logs
echo "📋 Recent logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo ""
echo "✅ Aggressive port fix completed!"
echo "🎯 If the service is still not running, check the logs above" 