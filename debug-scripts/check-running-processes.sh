#!/bin/bash

echo "🔍 Checking running processes and port usage..."

echo "📋 Processes using port 5001:"
lsof -i:5001

echo ""
echo "📋 Python processes:"
ps aux | grep python | grep -v grep

echo ""
echo "📋 Flask processes:"
ps aux | grep flask | grep -v grep

echo ""
echo "📋 Processes with 'app.py':"
ps aux | grep "app.py" | grep -v grep

echo ""
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

echo ""
echo "🧪 Testing API endpoints:"
echo "Health endpoint:"
curl -s http://localhost:5001/api/health
echo ""

echo "Users endpoint:"
curl -s http://localhost:5001/api/users
echo ""

echo "Events endpoint:"
curl -s http://localhost:5001/api/events
echo ""

echo ""
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 15 --no-pager

echo ""
echo "✅ Process check completed!" 