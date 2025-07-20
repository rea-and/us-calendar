#!/bin/bash

# Troubleshooting script for Our Calendar deployment issues

echo "🔍 Troubleshooting Our Calendar Deployment Issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📊 Checking service status..."
echo "================================"

# Check backend service
echo "🔧 Backend Service (us-calendar):"
systemctl status us-calendar --no-pager

echo ""
echo "📋 Backend logs (last 20 lines):"
echo "================================"
journalctl -u us-calendar -n 20 --no-pager

echo ""
echo "🌐 Nginx Service:"
echo "================================"
systemctl status nginx --no-pager

echo ""
echo "📋 Nginx error logs:"
echo "================================"
tail -n 20 /var/log/nginx/error.log

echo ""
echo "🔍 Checking file permissions and structure..."
echo "================================"

# Check if files exist
echo "📁 Checking application files:"
if [ -f "/var/www/us-calendar/backend/app.py" ]; then
    echo "✅ backend/app.py exists"
else
    echo "❌ backend/app.py missing"
fi

if [ -f "/var/www/us-calendar/requirements.txt" ]; then
    echo "✅ requirements.txt exists"
else
    echo "❌ requirements.txt missing"
fi

if [ -d "/var/www/us-calendar/frontend/build" ]; then
    echo "✅ frontend/build directory exists"
    echo "   Files in build: $(ls /var/www/us-calendar/frontend/build | wc -l)"
else
    echo "❌ frontend/build directory missing"
fi

# Check permissions
echo ""
echo "🔐 Checking permissions:"
ls -la /var/www/us-calendar/ | head -5
ls -la /var/www/us-calendar/backend/ | head -5

# Check Python environment
echo ""
echo "🐍 Checking Python environment:"
if [ -f "/var/www/us-calendar/venv/bin/python" ]; then
    echo "✅ Python virtual environment exists"
    echo "   Python version: $(/var/www/us-calendar/venv/bin/python --version)"
else
    echo "❌ Python virtual environment missing"
fi

# Check if backend can start manually
echo ""
echo "🧪 Testing backend startup..."
cd /var/www/us-calendar/backend
source ../venv/bin/activate
echo "   Testing Python import..."
python -c "from app import app; print('✅ App imports successfully')" 2>/dev/null || echo "❌ App import failed"

echo ""
echo "🌐 Checking network and ports..."
echo "================================"

# Check if port 5001 is in use
if netstat -tlnp | grep :5001; then
    echo "✅ Port 5001 is in use"
else
    echo "❌ Port 5001 is not in use"
fi

# Check if port 80 is in use
if netstat -tlnp | grep :80; then
    echo "✅ Port 80 is in use"
else
    echo "❌ Port 80 is not in use"
fi

echo ""
echo "🔧 Suggested fixes:"
echo "================================"

# Check backend logs for specific errors
if journalctl -u us-calendar -n 5 | grep -q "ModuleNotFoundError"; then
    echo "💡 Backend issue: Missing Python dependencies"
    echo "   Fix: cd /var/www/us-calendar && source venv/bin/activate && pip install -r requirements.txt"
fi

if journalctl -u us-calendar -n 5 | grep -q "Permission denied"; then
    echo "💡 Backend issue: Permission problems"
    echo "   Fix: chown -R www-data:www-data /var/www/us-calendar"
fi

if journalctl -u us-calendar -n 5 | grep -q "Address already in use"; then
    echo "💡 Backend issue: Port 5001 already in use"
    echo "   Fix: lsof -ti:5001 | xargs kill -9"
fi

echo ""
echo "🚀 Quick fixes to try:"
echo "================================"
echo "1. Restart backend: systemctl restart us-calendar"
echo "2. Restart nginx: systemctl restart nginx"
echo "3. Check logs: journalctl -u us-calendar -f"
echo "4. Rebuild frontend: cd /var/www/us-calendar/frontend && npm run build"
echo "5. Reinstall Python deps: cd /var/www/us-calendar && source venv/bin/activate && pip install -r requirements.txt" 