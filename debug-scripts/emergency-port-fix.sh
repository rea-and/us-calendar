#!/bin/bash

echo "🚨 EMERGENCY PORT FIX - Aggressively killing port 5001 processes..."

# Stop the service first
echo "🛑 Stopping us-calendar service..."
sudo systemctl stop us-calendar

# Find and kill ALL processes using port 5001
echo "🔍 Finding processes using port 5001..."
lsof -ti:5001 | while read pid; do
    echo "💀 Killing process $pid"
    sudo kill -9 $pid 2>/dev/null
done

# Additional aggressive cleanup
echo "🧹 Additional cleanup..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "flask" 2>/dev/null
sudo pkill -f "5001" 2>/dev/null

# Wait a moment
echo "⏳ Waiting for processes to die..."
sleep 3

# Check if port is free
echo "🔍 Checking if port 5001 is free..."
if lsof -i:5001 >/dev/null 2>&1; then
    echo "❌ Port 5001 is still in use!"
    echo "📋 Processes still using port 5001:"
    lsof -i:5001
    echo "💀 Force killing remaining processes..."
    sudo lsof -ti:5001 | xargs -r sudo kill -9
    sleep 2
else
    echo "✅ Port 5001 is now free!"
fi

# Start the service
echo "🚀 Starting us-calendar service..."
sudo systemctl start us-calendar

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
sleep 2
if curl -s http://localhost:5001/api/health >/dev/null; then
    echo "✅ API is responding!"
    curl -s http://localhost:5001/api/health
else
    echo "❌ API is not responding"
    echo "📋 Recent logs:"
    sudo journalctl -u us-calendar -n 10 --no-pager
fi

echo "✅ Emergency port fix completed!" 