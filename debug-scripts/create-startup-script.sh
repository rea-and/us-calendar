#!/bin/bash

echo "🔧 Creating comprehensive reboot-safe startup solution..."

# 1. Create a startup script that runs before the service
echo "📝 Creating startup script..."
sudo tee /usr/local/bin/us-calendar-startup.sh > /dev/null << 'EOF'
#!/bin/bash

# US Calendar Startup Script
# This script ensures clean startup after reboot

echo "$(date): Starting US Calendar cleanup..."

# Kill any existing processes
pkill -f "python.*app.py" 2>/dev/null
pkill -f "app.py" 2>/dev/null

# Kill processes on port 5001
lsof -ti:5001 | xargs -r kill -9 2>/dev/null

# Wait a moment
sleep 3

# Double-check port is free
if lsof -i :5001 > /dev/null 2>&1; then
    echo "$(date): WARNING - Port 5001 still in use after cleanup"
    lsof -i :5001
else
    echo "$(date): Port 5001 is free and ready"
fi

echo "$(date): US Calendar cleanup completed"
EOF

# 2. Make the startup script executable
sudo chmod +x /usr/local/bin/us-calendar-startup.sh

# 3. Create a systemd service that runs the startup script
echo "🔧 Creating startup service..."
sudo tee /etc/systemd/system/us-calendar-startup.service > /dev/null << 'EOF'
[Unit]
Description=US Calendar Startup Cleanup
Before=us-calendar.service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/us-calendar-startup.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

# 4. Update the main service to depend on the startup service
echo "🔧 Updating main service configuration..."
sudo tee /etc/systemd/system/us-calendar.service > /dev/null << 'EOF'
[Unit]
Description=Our Calendar Flask Backend
After=network.target us-calendar-startup.service
Requires=us-calendar-startup.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/us-calendar/backend
Environment=PATH=/var/www/us-calendar/venv/bin
ExecStart=/var/www/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 5. Enable both services
echo "✅ Enabling services..."
sudo systemctl enable us-calendar-startup.service
sudo systemctl enable us-calendar.service

# 6. Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# 7. Test the startup script
echo "🧪 Testing startup script..."
sudo /usr/local/bin/us-calendar-startup.sh

# 8. Start the services
echo "🚀 Starting services..."
sudo systemctl start us-calendar-startup.service
sudo systemctl start us-calendar.service

# 9. Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 5

# 10. Check service status
echo "📋 Service status:"
echo "Startup service:"
sudo systemctl status us-calendar-startup.service --no-pager
echo ""
echo "Main service:"
sudo systemctl status us-calendar.service --no-pager

# 11. Test API
echo "🧪 Testing API..."
sleep 3
curl -s http://localhost:5001/api/health
echo ""

# 12. Show service dependencies
echo "📋 Service dependencies:"
sudo systemctl list-dependencies us-calendar.service

echo ""
echo "✅ Comprehensive reboot-safe solution created!"
echo "🎯 This will prevent port conflicts on every reboot."
echo "📋 What was created:"
echo "   - /usr/local/bin/us-calendar-startup.sh (cleanup script)"
echo "   - us-calendar-startup.service (runs cleanup)"
echo "   - Updated us-calendar.service (depends on cleanup)"
echo "   - Both services enabled for automatic startup" 