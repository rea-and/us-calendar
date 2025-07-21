#!/bin/bash

# Debug landing page issue

echo "🔧 Debugging landing page issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Testing API Endpoints..."
echo "================================"

# Test the API endpoints directly
echo "📋 Testing users API endpoint:"
curl -s https://carlevato.net/api/users | jq . 2>/dev/null || curl -s https://carlevato.net/api/users

echo ""
echo "📋 Testing events API endpoint:"
curl -s https://carlevato.net/api/events | jq . 2>/dev/null || curl -s https://carlevato.net/api/events

echo ""
echo "📋 Testing backend directly:"
curl -s http://localhost:5001/api/users | jq . 2>/dev/null || curl -s http://localhost:5001/api/users

echo ""
echo "🔍 Step 2: Checking Database Content..."
echo "================================"

# Check database content
echo "📋 Checking users in database:"
cd /opt/us-calendar/backend
sqlite3 calendar.db "SELECT * FROM user;" 2>/dev/null || echo "Cannot access database"

echo ""
echo "📋 Checking events in database:"
sqlite3 calendar.db "SELECT * FROM event;" 2>/dev/null || echo "Cannot access database"

echo ""
echo "🔍 Step 3: Checking Backend Logs..."
echo "================================"

# Check backend logs for errors
echo "📋 Recent backend logs:"
journalctl -u us-calendar-backend --no-pager -n 20

echo ""
echo "🔍 Step 4: Testing Frontend Source..."
echo "================================"

# Check if the frontend is loading properly
echo "📋 Testing frontend HTML:"
curl -s https://carlevato.net/us/ | head -20

echo ""
echo "📋 Testing frontend JavaScript:"
curl -s https://carlevato.net/us/static/js/main.d577d6a3.js | grep -o "carlevato" | head -5

echo ""
echo "🔍 Step 5: Checking Apache Logs..."
echo "================================"

# Check Apache logs for errors
echo "📋 Recent Apache error logs:"
tail -10 /var/log/apache2/us-calendar-ssl-error.log

echo ""
echo "📋 Recent Apache access logs:"
tail -10 /var/log/apache2/us-calendar-ssl-access.log

echo ""
echo "🔍 Step 6: Testing API with Headers..."
echo "================================"

# Test API with proper headers
echo "📋 Testing API with Origin header:"
curl -H "Origin: https://carlevato.net" -H "Accept: application/json" -s https://carlevato.net/api/users | jq . 2>/dev/null || curl -H "Origin: https://carlevato.net" -H "Accept: application/json" -s https://carlevato.net/api/users

echo ""
echo "🔍 Step 7: Checking Backend Service Status..."
echo "================================"

# Check backend service status
echo "📋 Backend service status:"
systemctl status us-calendar-backend

echo ""
echo "📋 Backend process:"
ps aux | grep python | grep app.py

echo ""
echo "🔍 Step 8: Testing Database Connection..."
echo "================================"

# Test database connection from backend
echo "📋 Testing database connection:"
cd /opt/us-calendar/backend
python3 -c "
from app import app, db
from models import User, Event

with app.app_context():
    try:
        users = User.query.all()
        print(f'Found {len(users)} users:')
        for user in users:
            print(f'  - {user.name} (ID: {user.id})')
        
        events = Event.query.all()
        print(f'Found {len(events)} events:')
        for event in events:
            print(f'  - {event.title} (User: {event.user.name})')
    except Exception as e:
        print(f'Database error: {e}')
"

echo ""
echo "✅ Landing Page Debug Complete!"
echo ""
echo "🔍 Based on the results above:"
echo "   1. Check if users exist in the database"
echo "   2. Check if API returns proper JSON"
echo "   3. Check if frontend receives the data"
echo "   4. Check browser console for JavaScript errors"
echo ""
echo "🔧 Next steps:"
echo "   1. If no users exist, create a test user"
echo "   2. If API returns empty, check database"
echo "   3. If frontend doesn't render, check console errors"
echo "   4. Test in browser console: fetch('/api/users').then(r=>r.json()).then(console.log)" 