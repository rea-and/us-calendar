#!/bin/bash

# Fix port conflict and restart the backend service
echo "🔧 Fixing port conflict on port 5001..."

# Find processes using port 5001
echo "🔍 Finding processes using port 5001..."
lsof -ti:5001

# Kill any processes using port 5001
echo "🛑 Stopping processes using port 5001..."
sudo lsof -ti:5001 | xargs -r sudo kill -9

# Wait a moment for the port to be freed
echo "⏳ Waiting for port to be freed..."
sleep 2

# Check if port is now free
if lsof -ti:5001 > /dev/null 2>&1; then
    echo "❌ Port 5001 is still in use!"
    echo "🔍 Current processes using port 5001:"
    lsof -i:5001
    exit 1
else
    echo "✅ Port 5001 is now free"
fi

# Restart the service
echo "🔄 Restarting us-calendar service..."
sudo systemctl restart us-calendar

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 3

# Check service status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Check if service is running
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Service is running successfully!"
    
    # Test the API
    echo "🧪 Testing API endpoint..."
    curl -s http://localhost:5001/api/health || echo "❌ API not responding"
    
else
    echo "❌ Service failed to start"
    echo "📋 Recent logs:"
    sudo journalctl -u us-calendar -n 10 --no-pager
fi

echo ""
echo "🎯 Next steps:"
echo "1. Monitor logs: sudo journalctl -u us-calendar -f"
echo "2. Create an event as Angel to test email notifications"
echo "3. Check for email notification logs in the output" 