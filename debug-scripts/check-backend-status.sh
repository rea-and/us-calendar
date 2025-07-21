#!/bin/bash

echo "🔍 Checking backend service status..."

# Check service status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Check if process is actually running
echo ""
echo "🔍 Checking for running Python processes:"
ps aux | grep python | grep -v grep

# Check port usage
echo ""
echo "🔍 Checking port 5001 usage:"
lsof -i:5001

# Test API endpoints
echo ""
echo "🧪 Testing API endpoints:"
echo "Health check:"
curl -s http://localhost:5001/api/health

echo ""
echo "Users endpoint:"
curl -s http://localhost:5001/api/users

echo ""
echo "Events endpoint:"
curl -s http://localhost:5001/api/events

# Check recent logs
echo ""
echo "📋 Recent backend logs:"
sudo journalctl -u us-calendar -n 20 --no-pager

# Check if service file is correct
echo ""
echo "📋 Service file content:"
sudo cat /etc/systemd/system/us-calendar.service

echo ""
echo "🎯 Analysis:"
if curl -s http://localhost:5001/api/health > /dev/null; then
    echo "✅ API is responding - backend is actually running"
    echo "⚠️  Service status shows failed but process is working"
    echo "💡 This might be a service file configuration issue"
else
    echo "❌ API is not responding - backend is not running"
fi 