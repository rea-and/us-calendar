#!/bin/bash

echo "🔍 Finding virtual environment and fixing service..."

# Stop the service first
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# Find virtual environment
echo "🔍 Looking for virtual environment..."
echo "Checking common locations:"

# Check /opt/us-calendar/venv
if [ -f "/opt/us-calendar/venv/bin/python" ]; then
    echo "✅ Found: /opt/us-calendar/venv/bin/python"
    VENV_PATH="/opt/us-calendar/venv/bin/python"
elif [ -f "/var/www/us-calendar/venv/bin/python" ]; then
    echo "✅ Found: /var/www/us-calendar/venv/bin/python"
    VENV_PATH="/var/www/us-calendar/venv/bin/python"
elif [ -f "/opt/us-calendar/backend/venv/bin/python" ]; then
    echo "✅ Found: /opt/us-calendar/backend/venv/bin/python"
    VENV_PATH="/opt/us-calendar/backend/venv/bin/python"
else
    echo "❌ Virtual environment not found in common locations"
    echo "🔍 Searching for python in venv directories..."
    find /opt /var/www -name "python" -path "*/venv/bin/*" 2>/dev/null
    echo "🔍 Searching for python3 in venv directories..."
    find /opt /var/www -name "python3" -path "*/venv/bin/*" 2>/dev/null
    
    # Try to find any python executable
    echo "🔍 Searching for any python executable..."
    find /opt /var/www -name "python*" -type f -executable 2>/dev/null | head -10
    
    echo "❌ Could not find virtual environment automatically"
    echo "💡 Please check where your virtual environment is located"
    exit 1
fi

# Get the directory containing the venv
VENV_DIR=$(dirname $(dirname "$VENV_PATH"))
echo "📁 Virtual environment directory: $VENV_DIR"

# Check if app.py exists in the backend directory
echo "🔍 Checking for app.py..."
if [ -f "/opt/us-calendar/backend/app.py" ]; then
    echo "✅ Found: /opt/us-calendar/backend/app.py"
    WORKING_DIR="/opt/us-calendar/backend"
elif [ -f "/var/www/us-calendar/backend/app.py" ]; then
    echo "✅ Found: /var/www/us-calendar/backend/app.py"
    WORKING_DIR="/var/www/us-calendar/backend"
else
    echo "❌ app.py not found in expected locations"
    echo "🔍 Searching for app.py..."
    find /opt /var/www -name "app.py" 2>/dev/null
    exit 1
fi

echo "📁 Working directory: $WORKING_DIR"

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
sleep 3

# Check status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Test API
echo "🧪 Testing API..."
curl -s http://localhost:5001/api/health

echo ""
echo "✅ Service configuration updated with correct paths!" 