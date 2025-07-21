#!/bin/bash

echo "🔍 Investigating running processes and service status..."

# 1. Check systemd service status
echo "📋 Systemd service status:"
sudo systemctl status us-calendar --no-pager

echo ""

# 2. Check if service is active
echo "🔍 Is service active?"
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Service is active"
else
    echo "❌ Service is not active"
fi

echo ""

# 3. Check all Python processes
echo "🐍 All Python processes:"
ps aux | grep python | grep -v grep || echo "No Python processes found"

echo ""

# 4. Check specific app.py processes
echo "📱 App.py processes:"
ps aux | grep -E "(app\.py|python.*app)" | grep -v grep || echo "No app.py processes found"

echo ""

# 5. Check port 5001 usage
echo "🔌 Port 5001 usage:"
if command -v lsof >/dev/null 2>&1; then
    lsof -i :5001 || echo "No processes on port 5001"
else
    echo "lsof not available, using netstat..."
    netstat -tlnp 2>/dev/null | grep :5001 || echo "No processes on port 5001"
fi

echo ""

# 6. Check all processes listening on ports
echo "🌐 All listening ports:"
if command -v lsof >/dev/null 2>&1; then
    lsof -i -P -n | grep LISTEN | head -10
else
    netstat -tlnp 2>/dev/null | head -10
fi

echo ""

# 7. Check process tree
echo "🌳 Process tree (Python related):"
pstree -p | grep -i python || echo "No Python processes in tree"

echo ""

# 8. Check systemd logs
echo "📋 Recent systemd logs:"
sudo journalctl -u us-calendar -n 20 --no-pager

echo ""

# 9. Test API endpoints
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

# 10. Check if there are any zombie processes
echo "🧟 Zombie processes:"
ps aux | grep -E "Z|defunct" | grep -v grep || echo "No zombie processes found"

echo ""

# 11. Check systemd service dependencies
echo "🔗 Service dependencies:"
sudo systemctl list-dependencies us-calendar.service

echo ""

# 12. Check if there are multiple service files
echo "📁 Service files:"
find /etc/systemd/system -name "*us-calendar*" -type f
find /lib/systemd/system -name "*us-calendar*" -type f 2>/dev/null

echo ""

echo "🔍 Investigation complete!"
echo "📋 Summary:"
echo "   - Service status shown above"
echo "   - Python processes listed above"
echo "   - Port usage shown above"
echo "   - API endpoints tested above"
echo "   - If API works but service shows failed, there's likely a manual process running" 