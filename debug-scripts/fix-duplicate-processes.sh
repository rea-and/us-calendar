#!/bin/bash

echo "🔧 Fixing duplicate processes issue..."

# 1. Stop the systemd service first
echo "🛑 Stopping systemd service..."
sudo systemctl stop us-calendar

# 2. Kill the manual processes that are using port 5001
echo "💀 Killing manual processes using port 5001..."
lsof -ti:5001 | while read pid; do
    echo "Killing process $pid"
    sudo kill -9 $pid
done

# 3. Additional cleanup
echo "🧹 Additional cleanup..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null

# 4. Wait for processes to die
echo "⏳ Waiting for processes to die..."
sleep 3

# 5. Verify port is free
echo "🔍 Verifying port 5001 is free..."
if lsof -i:5001 >/dev/null 2>&1; then
    echo "❌ Port 5001 is still in use!"
    lsof -i:5001
    echo "💀 Force killing remaining processes..."
    sudo lsof -ti:5001 | xargs -r sudo kill -9
    sleep 2
else
    echo "✅ Port 5001 is now free!"
fi

# 6. Start the systemd service
echo "🚀 Starting systemd service..."
sudo systemctl start us-calendar

# 7. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 8. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 9. Test API endpoints
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

# 10. Check processes
echo "📋 Current processes using port 5001:"
lsof -i:5001

echo ""
echo "📋 Python processes:"
ps aux | grep python | grep -v grep

echo ""
echo "✅ Duplicate processes fix completed!" 