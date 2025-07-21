#!/bin/bash

echo "🔍 Debugging email notifications..."

# Test the email functions directly
echo "🧪 Testing email functions directly..."
cd /opt/us-calendar/backend

python3 -c "
from email_utils import send_event_notification, should_send_notification
from models import User, Event
from app import db

# Test should_send_notification function
print('🔍 Testing should_send_notification:')
print('  Angel (lowercase):', should_send_notification({}, 'angel'))
print('  Angel (uppercase):', should_send_notification({}, 'Angel'))
print('  Andrea:', should_send_notification({}, 'Andrea'))

# Test with actual user data from database
print('\\n🔍 Testing with actual database users:')
with app.app_context():
    users = User.query.all()
    for user in users:
        print(f'  User ID {user.id}: {user.name} (type: {type(user.name)})')
        test_event = {'title': 'Test Event'}
        should_send = should_send_notification(test_event, user.name)
        print(f'    Should send notification: {should_send}')
        
        # Test email sending
        if should_send:
            print(f'    Testing email send for {user.name}...')
            send_event_notification(test_event, 'created')
"

# Test creating an event via API and check logs
echo ""
echo "🧪 Testing event creation via API..."

# Start monitoring logs in background
echo "📋 Starting log monitoring..."
sudo journalctl -u us-calendar -f --no-pager &
LOG_PID=$!

# Wait a moment
sleep 2

# Create test event as Angel (ID 1)
echo "📧 Creating test event as Angel (ID 1)..."
TEST_EVENT=$(curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Debug Email Test",
    "description": "Testing email notification debugging",
    "event_type": "holiday",
    "start_date": "2024-07-22T16:00:00Z",
    "end_date": "2024-07-22T17:00:00Z",
    "user_id": 1,
    "applies_to_both": true
  }')

echo "Test event created: $TEST_EVENT"

# Wait for logs to show
echo "⏳ Waiting for logs..."
sleep 5

# Stop log monitoring
kill $LOG_PID 2>/dev/null

echo ""
echo "🔍 Checking if email_utils is imported in routes..."
grep -n "email_utils" /opt/us-calendar/backend/routes.py

echo ""
echo "🔍 Checking if notification code is in create_event function..."
grep -A 10 -B 5 "should_send_notification" /opt/us-calendar/backend/routes.py

echo ""
echo "✅ Email notification debugging completed!"
echo "📋 Check the output above for any issues" 