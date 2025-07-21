#!/bin/bash

echo "🔧 Fixing persistent port conflict with simple approach..."

# 1. Kill any existing processes
echo "🧹 Killing existing processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null

# 2. Stop the service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 3. Create a simple systemd service file
echo "🔧 Creating simple systemd service file..."
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
ExecStartPre=/bin/bash -c 'pkill -f "python.*app.py" 2>/dev/null || true'
ExecStartPre=/bin/bash -c 'pkill -f "app.py" 2>/dev/null || true'
ExecStartPre=/bin/sleep 3
ExecStart=/var/www/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=15
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 4. Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# 5. Enable the service
echo "✅ Enabling service..."
sudo systemctl enable us-calendar

# 6. Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 7. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 8

# 8. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 9. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 3

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

# 10. Show recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo ""
echo "✅ Simple reboot-safe service configuration applied!"
echo "🎯 The service should now start properly after every reboot."
echo "📋 Key improvements:"
echo "   - Simple pkill commands for cleanup"
echo "   - Full PATH environment variable"
echo "   - Increased RestartSec to 15 seconds"
echo "   - No dependency on external tools" 