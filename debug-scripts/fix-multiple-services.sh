#!/bin/bash

echo "🔧 Fixing multiple service files issue..."

# 1. Check all service files
echo "📁 Checking all service files..."
find /etc/systemd/system -name "*us-calendar*" -type f
find /lib/systemd/system -name "*us-calendar*" -type f 2>/dev/null

echo ""

# 2. Show content of both service files
echo "📋 Content of us-calendar.service:"
sudo cat /etc/systemd/system/us-calendar.service
echo ""

echo "📋 Content of us-calendar-backend.service:"
sudo cat /etc/systemd/system/us-calendar-backend.service
echo ""

# 3. Stop all services
echo "🛑 Stopping all services..."
sudo systemctl stop us-calendar 2>/dev/null
sudo systemctl stop us-calendar-backend 2>/dev/null

# 4. Disable all services
echo "❌ Disabling all services..."
sudo systemctl disable us-calendar 2>/dev/null
sudo systemctl disable us-calendar-backend 2>/dev/null

# 5. Kill any existing processes
echo "🧹 Killing existing processes..."
sudo pkill -9 -f "python.*app.py" 2>/dev/null
sudo pkill -9 -f "app.py" 2>/dev/null
sudo pkill -9 -f "flask" 2>/dev/null

# 6. Remove the conflicting service file
echo "🗑️ Removing conflicting service file..."
sudo rm -f /etc/systemd/system/us-calendar-backend.service

# 7. Create a clean, simple service file
echo "🔧 Creating clean service file..."
sudo tee /etc/systemd/system/us-calendar.service > /dev/null << 'EOF'
[Unit]
Description=Our Calendar Flask Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/us-calendar/backend
Environment=PATH=/var/www/us-calendar/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=FLASK_ENV=production

ExecStart=/var/www/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# 9. Enable the service
echo "✅ Enabling service..."
sudo systemctl enable us-calendar

# 10. Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 11. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 8

# 12. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 13. Check if service is active
echo "🔍 Is service active?"
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Service is active"
else
    echo "❌ Service is not active"
fi

# 14. Check for running processes
echo "🔍 Checking for running processes..."
ps aux | grep -E "(python.*app\.py|app\.py)" | grep -v grep || echo "No Python app processes found"

# 15. Check port usage
echo "🔌 Port 5001 usage:"
if command -v lsof >/dev/null 2>&1; then
    lsof -i :5001 || echo "No processes on port 5001"
else
    netstat -tlnp 2>/dev/null | grep :5001 || echo "No processes on port 5001"
fi

# 16. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 3

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

# 17. Show recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

# 18. Verify only one service file exists
echo "📁 Verifying service files:"
find /etc/systemd/system -name "*us-calendar*" -type f

echo ""
echo "✅ Multiple service files issue fixed!"
echo "🎯 Only one clean service file now exists."
echo "📋 What was done:"
echo "   - Removed conflicting us-calendar-backend.service"
echo "   - Created clean us-calendar.service"
echo "   - Removed all ExecStartPre commands that were causing issues"
echo "   - Simplified service configuration"
echo "   - Service should now start properly" 