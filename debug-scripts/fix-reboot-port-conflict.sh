#!/bin/bash

echo "🔧 Fixing persistent port conflict after reboot..."

# 1. First, let's see what's using port 5001
echo "🔍 Checking what's using port 5001..."
lsof -i :5001 || echo "No processes found on port 5001"

# 2. Kill any existing processes
echo "🧹 Killing existing processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 3. Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 4. Check current systemd service file
echo "📋 Current systemd service configuration:"
sudo systemctl cat us-calendar

# 5. Create a new systemd service file with proper startup sequence
echo "🔧 Creating improved systemd service file..."
sudo tee /etc/systemd/system/us-calendar.service > /dev/null << 'EOF'
[Unit]
Description=Our Calendar Flask Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/us-calendar/backend
Environment=PATH=/var/www/us-calendar/venv/bin
ExecStartPre=/bin/bash -c 'lsof -ti:5001 | xargs -r kill -9 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'sleep 2'
ExecStart=/var/www/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Kill any existing processes before starting
ExecStartPre=/bin/bash -c 'pkill -f "python.*app.py" 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'pkill -f "app.py" 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# 7. Enable the service
echo "✅ Enabling service..."
sudo systemctl enable us-calendar

# 8. Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 9. Wait a moment
echo "⏳ Waiting for service to start..."
sleep 5

# 10. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 11. Check if port is now free
echo "🔍 Checking port 5001 status:"
if lsof -i :5001 > /dev/null 2>&1; then
    echo "⚠️  Port 5001 is still in use:"
    lsof -i :5001
else
    echo "✅ Port 5001 is now free"
fi

# 12. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 3

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

# 13. Show recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo ""
echo "✅ Reboot-safe service configuration applied!"
echo "🎯 The service should now start properly after every reboot."
echo "📋 Key improvements:"
echo "   - ExecStartPre commands to kill existing processes"
echo "   - Proper cleanup before starting"
echo "   - Increased RestartSec to 10 seconds"
echo "   - Better error handling and process management" 