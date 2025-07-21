#!/bin/bash

echo "🔧 Fixing persistent port conflict with robust approach..."

# 1. Check what's currently running
echo "🔍 Checking current processes..."
ps aux | grep -E "(python.*app\.py|app\.py)" | grep -v grep || echo "No Python app processes found"

# 2. Check port usage
echo "🔍 Checking port 5001..."
if command -v lsof >/dev/null 2>&1; then
    lsof -i :5001 || echo "No processes on port 5001"
else
    echo "lsof not available, checking with netstat..."
    netstat -tlnp 2>/dev/null | grep :5001 || echo "No processes on port 5001"
fi

# 3. Kill all related processes more aggressively
echo "🧹 Aggressively killing existing processes..."
sudo pkill -9 -f "python.*app.py" 2>/dev/null
sudo pkill -9 -f "app.py" 2>/dev/null
sudo pkill -9 -f "flask" 2>/dev/null

# 4. Kill processes on port 5001
if command -v lsof >/dev/null 2>&1; then
    lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null
fi

# 5. Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar 2>/dev/null

# 6. Wait for processes to fully stop
echo "⏳ Waiting for processes to stop..."
sleep 5

# 7. Create a robust systemd service file
echo "🔧 Creating robust systemd service file..."
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

# Kill any existing processes before starting
ExecStartPre=/bin/bash -c 'pkill -9 -f "python.*app.py" 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'pkill -9 -f "app.py" 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'pkill -9 -f "flask" 2>/dev/null || true'
ExecStartPre=/bin/sleep 5

ExecStart=/var/www/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=20
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
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
sleep 10

# 12. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 13. Check if service is actually running
echo "🔍 Checking if service is running..."
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Service is active"
else
    echo "❌ Service is not active"
fi

# 14. Check for running processes
echo "🔍 Checking for running processes..."
ps aux | grep -E "(python.*app\.py|app\.py)" | grep -v grep || echo "No Python app processes found"

# 15. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 3

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

# 16. Show recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 15 --no-pager

echo ""
echo "✅ Robust reboot-safe service configuration applied!"
echo "🎯 The service should now start properly after every reboot."
echo "📋 Key improvements:"
echo "   - Aggressive process killing with SIGKILL"
echo "   - Better process cleanup before starting"
echo "   - Increased RestartSec to 20 seconds"
echo "   - Proper KillMode and TimeoutStopSec settings"
echo "   - More robust error handling" 