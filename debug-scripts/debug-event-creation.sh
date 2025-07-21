#!/bin/bash

# Debug event creation issue

echo "🔧 Debugging event creation issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Backend Service Status..."
echo "================================"

# Check backend service status
echo "📋 Checking backend service status..."
systemctl status us-calendar-backend --no-pager -l

echo ""
echo "🔍 Step 2: Checking Backend Logs..."
echo "================================"

# Check backend logs
echo "📋 Checking recent backend logs..."
journalctl -u us-calendar-backend --no-pager -l -n 20

echo ""
echo "🔍 Step 3: Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing users endpoint..."
curl -s https://carlevato.net/api/users | jq '.'

echo ""
echo "📋 Testing events endpoint (GET)..."
curl -s https://carlevato.net/api/events | jq '.'

echo ""
echo "🔍 Step 4: Testing Event Creation..."
echo "================================"

# Test event creation
echo "📋 Testing event creation with sample data..."
curl -X POST https://carlevato.net/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Event",
    "description": "Test event description",
    "event_type": "work",
    "start_date": "2025-07-21T10:00:00.000Z",
    "end_date": "2025-07-21T11:00:00.000Z",
    "user_id": 1,
    "applies_to_both": false
  }' | jq '.'

echo ""
echo "🔍 Step 5: Checking Database..."
echo "================================"

# Check database
echo "📋 Checking database file..."
ls -la /opt/us-calendar/backend/calendar.db

echo ""
echo "📋 Checking database schema..."
sqlite3 /opt/us-calendar/backend/calendar.db ".schema"

echo ""
echo "📋 Checking users table..."
sqlite3 /opt/us-calendar/backend/calendar.db "SELECT * FROM users;"

echo ""
echo "📋 Checking events table..."
sqlite3 /opt/us-calendar/backend/calendar.db "SELECT * FROM events;"

echo ""
echo "🔍 Step 6: Testing Backend Directly..."
echo "================================"

# Test backend directly
echo "📋 Testing backend on localhost..."
cd /opt/us-calendar/backend
python3 -c "
import requests
import json

# Test users endpoint
print('Testing users endpoint...')
try:
    response = requests.get('http://localhost:5001/api/users')
    print(f'Status: {response.status_code}')
    print(f'Response: {response.json()}')
except Exception as e:
    print(f'Error: {e}')

# Test events endpoint
print('\nTesting events endpoint...')
try:
    response = requests.get('http://localhost:5001/api/events')
    print(f'Status: {response.status_code}')
    print(f'Response: {response.json()}')
except Exception as e:
    print(f'Error: {e}')

# Test event creation
print('\nTesting event creation...')
try:
    event_data = {
        'title': 'Test Event',
        'description': 'Test event description',
        'event_type': 'work',
        'start_date': '2025-07-21T10:00:00.000Z',
        'end_date': '2025-07-21T11:00:00.000Z',
        'user_id': 1,
        'applies_to_both': False
    }
    response = requests.post('http://localhost:5001/api/events', json=event_data)
    print(f'Status: {response.status_code}')
    print(f'Response: {response.json()}')
except Exception as e:
    print(f'Error: {e}')
"

echo ""
echo "🔍 Step 7: Checking Apache Configuration..."
echo "================================"

# Check Apache configuration
echo "📋 Checking Apache proxy configuration..."
grep -A 10 -B 5 "ProxyPass.*api" /etc/apache2/sites-available/calendar.conf

echo ""
echo "📋 Testing Apache proxy..."
curl -I https://carlevato.net/api/health

echo ""
echo "✅ Event Creation Debug Complete!"
echo ""
echo "🔍 Analysis:"
echo "   - Check if backend service is running"
echo "   - Check backend logs for errors"
echo "   - Verify API endpoints are accessible"
echo "   - Test event creation directly"
echo "   - Check database connectivity"
echo "   - Verify Apache proxy configuration"
echo ""
echo "📱 Common Issues:"
echo "   - Backend service not running"
echo "   - Database connection issues"
echo "   - Missing required fields in request"
echo "   - Invalid date format"
echo "   - User ID not found"
echo "   - Apache proxy configuration issues" 