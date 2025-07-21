#!/bin/bash

# Fix backend Python path issue

echo "🔧 Fixing backend Python path issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Python Installation..."
echo "================================"

# Check what Python versions are available
echo "📋 Checking Python installations:"
which python3
which python
ls -la /usr/bin/python*

echo ""
echo "📋 Checking virtual environment:"
ls -la /opt/us-calendar/venv/ 2>/dev/null || echo "Virtual environment not found"

echo ""
echo "🔍 Step 2: Checking Current Flask Process..."
echo "================================"

# I noticed there's already a Flask process running
echo "📋 Current Flask process:"
ps aux | grep flask | grep -v grep

echo ""
echo "🔍 Step 3: Testing Python and Flask..."
echo "================================"

# Test if we can run the Flask app directly
echo "📋 Testing Python app directly:"
cd /opt/us-calendar/backend
python3 app.py &
sleep 3

echo "📋 Testing if Flask app is running:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

# Stop the test process
pkill -f "python3 app.py"

echo ""
echo "🔍 Step 4: Creating Fixed Backend Service..."
echo "================================"

# Create a fixed service file using the correct Python path
echo "📋 Creating fixed backend service file..."
cat > /etc/systemd/system/us-calendar-backend.service << 'EOF'
[Unit]
Description=US Calendar Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/us-calendar/backend
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "📋 Fixed backend service file:"
cat /etc/systemd/system/us-calendar-backend.service

echo ""
echo "🔍 Step 5: Restarting Backend Service..."
echo "================================"

# Reload systemd and restart the service
echo "📋 Reloading systemd..."
systemctl daemon-reload

echo "📋 Stopping old service..."
systemctl stop us-calendar-backend

echo "📋 Starting fixed service..."
systemctl start us-calendar-backend

# Wait for the service to start
sleep 5

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
echo "✅ Backend Python Path Fix Complete!"
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