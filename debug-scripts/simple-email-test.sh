#!/bin/bash

echo "🧪 Simple email notification test..."

# Test 1: Check if email_utils can be imported
echo "🔍 Test 1: Importing email_utils..."
cd /opt/us-calendar/backend
python3 -c "from email_utils import send_event_notification, should_send_notification; print('✅ email_utils imported successfully')"

# Test 2: Test the should_send_notification function
echo ""
echo "🔍 Test 2: Testing should_send_notification function..."
python3 -c "
from email_utils import should_send_notification
print('Angel (lowercase):', should_send_notification({}, 'angel'))
print('Angel (uppercase):', should_send_notification({}, 'Angel'))
print('Andrea:', should_send_notification({}, 'Andrea'))
"

# Test 3: Test email sending function
echo ""
echo "🔍 Test 3: Testing email sending function..."
python3 -c "
from email_utils import send_event_notification
test_event = {'title': 'Test Event', 'event_type': 'holiday', 'start_date': '2024-07-22T10:00:00Z', 'end_date': '2024-07-22T11:00:00Z'}
send_event_notification(test_event, 'created')
"

# Test 4: Create event via API and check for logs
echo ""
echo "🔍 Test 4: Creating event via API and checking logs..."

# Start monitoring logs
echo "📋 Monitoring logs for email notifications..."
sudo journalctl -u us-calendar -f --no-pager &
LOG_PID=$!

# Wait a moment
sleep 2

# Create event as Angel
echo "📧 Creating event as Angel..."
curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Simple Email Test",
    "description": "Testing email notifications",
    "event_type": "holiday",
    "start_date": "2024-07-22T18:00:00Z",
    "end_date": "2024-07-22T19:00:00Z",
    "user_id": 1,
    "applies_to_both": true
  }'

echo ""
echo "⏳ Waiting for logs to appear..."
sleep 3

# Stop log monitoring
kill $LOG_PID 2>/dev/null

echo ""
echo "✅ Simple email test completed!"
echo "📋 If you didn't see email notification logs, there might be an issue with:"
echo "   1. The should_send_notification function logic"
echo "   2. The user name comparison"
echo "   3. The print statements not being captured by systemd" 