#!/bin/bash

echo "🔧 Fixing systemd service configuration..."

# Stop the service first
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# Kill any existing processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" || true

# Wait for cleanup
sleep 2

# Check current service file
echo "📋 Current service file:"
sudo cat /etc/systemd/system/us-calendar.service

# Create new service file with correct configuration
echo "📝 Creating new service file..."
sudo tee /etc/systemd/system/us-calendar.service > /dev/null << 'EOF'
[Unit]
Description=Our Calendar Flask Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/us-calendar/backend
Environment=PATH=/opt/us-calendar/venv/bin
ExecStart=/opt/us-calendar/venv/bin/python app.py
Environment=FLASK_ENV=production
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# Wait for service to start
sleep 3

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
curl -s http://localhost:5001/api/health

echo ""
echo "✅ Service configuration fixed!"
echo "🎯 The service should now show as 'active (running)'" 