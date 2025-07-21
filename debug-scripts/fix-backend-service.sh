#!/bin/bash

# Fix backend service issue

echo "🔧 Fixing backend service issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Backend Service Status..."
echo "================================"

# Check if the backend service exists and its status
echo "📋 Checking backend service status..."
systemctl status us-calendar-backend 2>/dev/null

echo ""
echo "📋 Checking if service file exists..."
ls -la /etc/systemd/system/us-calendar-backend.service 2>/dev/null

echo ""
echo "🔍 Step 2: Checking Backend Process..."
echo "================================"

# Check if there's any process running on port 5001
echo "📋 Checking processes on port 5001:"
netstat -tlnp 2>/dev/null | grep :5001 || echo "No process found on port 5001"

echo ""
echo "📋 Checking for Python processes:"
ps aux | grep python | grep -v grep

echo ""
echo "🔍 Step 3: Checking Backend Directory..."
echo "================================"

# Check if the backend directory and files exist
echo "📋 Checking backend directory:"
ls -la /opt/us-calendar/backend/

echo ""
echo "📋 Checking if app.py exists:"
ls -la /opt/us-calendar/backend/app.py

echo ""
echo "🔍 Step 4: Creating Backend Service..."
echo "================================"

# Create the systemd service file for the backend
echo "📋 Creating backend service file..."
cat > /etc/systemd/system/us-calendar-backend.service << 'EOF'
[Unit]
Description=US Calendar Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/us-calendar/backend
Environment=PATH=/opt/us-calendar/venv/bin
ExecStart=/opt/us-calendar/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "📋 Backend service file created:"
cat /etc/systemd/system/us-calendar-backend.service

echo ""
echo "🔍 Step 5: Enabling and Starting Backend Service..."
echo "================================"

# Reload systemd and enable the service
echo "📋 Reloading systemd..."
systemctl daemon-reload

echo "📋 Enabling backend service..."
systemctl enable us-calendar-backend

echo "📋 Starting backend service..."
systemctl start us-calendar-backend

# Wait a moment for the service to start
sleep 3

echo "📋 Checking service status:"
systemctl status us-calendar-backend

echo ""
echo "🔍 Step 6: Testing Backend Connection..."
echo "================================"

# Test if the backend is responding
echo "📋 Testing backend connection:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

# Test with a small delay to ensure it's fully started
sleep 2
echo "📋 Testing backend again:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

echo ""
echo "🔍 Step 7: Testing Full Application..."
echo "================================"

# Test the full application through Apache
echo "📋 Testing calendar access:"
curl -I http://localhost/us/ 2>/dev/null | head -5

echo "📋 Testing API through Apache:"
curl -I http://localhost/api/events 2>/dev/null | head -5

echo "📋 Testing external access:"
curl -I http://157.230.244.80/us/ 2>/dev/null | head -5

echo ""
echo "🔍 Step 8: Checking Logs..."
echo "================================"

# Check backend logs
echo "📋 Backend service logs:"
journalctl -u us-calendar-backend --no-pager -n 10

echo "📋 Apache error logs:"
tail -5 /var/log/apache2/us-calendar-error.log

echo ""
echo "✅ Backend Service Fix Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - http://carlevato.net/us/ (domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If both HTTP and API show 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check backend logs: journalctl -u us-calendar-backend -f"
echo "   2. Check Apache logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   3. Test backend directly: curl http://localhost:5001/api/events" 