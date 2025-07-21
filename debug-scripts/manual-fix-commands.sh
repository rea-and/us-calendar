#!/bin/bash

echo "🔧 Manual fix commands for port conflict..."
echo ""
echo "Run these commands one by one:"
echo ""

echo "1. Stop the service:"
echo "sudo systemctl stop us-calendar"
echo ""

echo "2. Kill all Python processes:"
echo "sudo pkill -9 -f python"
echo ""

echo "3. Check what's using port 5001:"
echo "lsof -i:5001"
echo ""

echo "4. Force kill anything on port 5001:"
echo "sudo lsof -ti:5001 | xargs -r sudo kill -9"
echo ""

echo "5. Wait a moment:"
echo "sleep 3"
echo ""

echo "6. Pull latest changes:"
echo "cd /opt/us-calendar && git pull origin main"
echo ""

echo "7. Start the service:"
echo "sudo systemctl start us-calendar"
echo ""

echo "8. Check status:"
echo "sudo systemctl status us-calendar"
echo ""

echo "9. Test API:"
echo "curl http://localhost:5001/api/health"
echo ""

echo "10. Monitor logs:"
echo "sudo journalctl -u us-calendar -f"
echo ""

echo "🎯 Run these commands in order to fix the port conflict!" 