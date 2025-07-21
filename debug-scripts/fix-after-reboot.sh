#!/bin/bash

echo "🔧 Fixing port conflict after server reboot..."

# Stop the service first
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# Kill any existing Python processes that might be using port 5001
echo "🧹 Killing all Python processes..."
sudo pkill -f "python.*app.py" || true
sudo pkill -f "flask" || true
sudo pkill -f "python.*5001" || true

# Wait for processes to be killed
echo "⏳ Waiting for processes to be killed..."
sleep 3

# Double-check port 5001 is free
echo "🔍 Checking if port 5001 is free..."
if lsof -ti:5001 > /dev/null 2>&1; then
    echo "❌ Port 5001 is still in use!"
    echo "🔍 Current processes using port 5001:"
    lsof -i:5001
    echo "🛑 Force killing processes on port 5001..."
    sudo lsof -ti:5001 | xargs -r sudo kill -9
    sleep 2
else
    echo "✅ Port 5001 is now free"
fi

# Verify port is free
if lsof -ti:5001 > /dev/null 2>&1; then
    echo "❌ Port 5001 is still in use after cleanup!"
    exit 1
fi

# Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
API_RESPONSE=$(curl -s http://localhost:5001/api/health)
if [ $? -eq 0 ]; then
    echo "✅ API is responding: $API_RESPONSE"
else
    echo "❌ API is not responding"
    echo "📋 Recent logs:"
    sudo journalctl -u us-calendar -n 10 --no-pager
    exit 1
fi

echo ""
echo "✅ Post-reboot fix completed!"
echo "🎯 Service should now be running properly"
echo "📧 Email notifications should be working" 