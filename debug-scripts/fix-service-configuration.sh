#!/bin/bash

echo "🔧 Fixing service file configuration..."

# Stop the service first
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# Kill any remaining processes
echo "🧹 Cleaning up processes..."
sudo pkill -9 -f python || true
sleep 2

# Find the correct virtual environment
echo "🔍 Finding virtual environment..."
if [ -f "/var/www/us-calendar/venv/bin/python" ]; then
    echo "✅ Found: /var/www/us-calendar/venv/bin/python"
    VENV_PATH="/var/www/us-calendar/venv/bin/python"
    WORKING_DIR="/var/www/us-calendar/backend"
elif [ -f "/opt/us-calendar/venv/bin/python" ]; then
    echo "✅ Found: /opt/us-calendar/venv/bin/python"
    VENV_PATH="/opt/us-calendar/venv/bin/python"
    WORKING_DIR="/opt/us-calendar/backend"
else
    echo "❌ Virtual environment not found!"
    exit 1
fi

# Check if app.py exists in the working directory
echo "🔍 Checking for app.py in $WORKING_DIR..."
if [ ! -f "$WORKING_DIR/app.py" ]; then
    echo "❌ app.py not found in $WORKING_DIR"
    exit 1
fi

echo "✅ app.py found in $WORKING_DIR"

# Create new service file with correct paths
echo "📝 Creating new service file with correct paths..."
sudo tee /etc/systemd/system/us-calendar.service > /dev/null << EOF
[Unit]
Description=Our Calendar Flask Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$WORKING_DIR
Environment=PATH=$(dirname "$VENV_PATH")
ExecStart=$VENV_PATH app.py
Environment=FLASK_ENV=production
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Show the new service file
echo "📋 New service file:"
sudo cat /etc/systemd/system/us-calendar.service

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Start the service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
API_RESPONSE=$(curl -s http://localhost:5001/api/health)
if [ $? -eq 0 ]; then
    echo "✅ API is responding: $API_RESPONSE"
else
    echo "❌ API is not responding"
    echo "📋 Recent logs:"
    sudo journalctl -u us-calendar -n 10 --no-pager
    exit 1
fi

echo ""
echo "✅ Service configuration fixed!"
echo "🎯 Service should now be running properly" 