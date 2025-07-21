#!/bin/bash

echo "📧 Testing email notifications for Angel (ID 1)..."

# Start monitoring logs in background
echo "📋 Starting log monitoring..."
sudo journalctl -u us-calendar -f --no-pager &
LOG_PID=$!

# Wait a moment
sleep 2

# Create test event as Angel (ID 1)
echo "🧪 Creating test event as Angel (ID 1)..."

TEST_EVENT=$(curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Email from Angel",
    "description": "Testing email notifications - Angel created this event",
    "event_type": "holiday",
    "start_date": "2024-07-22T14:00:00Z",
    "end_date": "2024-07-22T15:00:00Z",
    "user_id": 1,
    "applies_to_both": true
  }')

echo "Test event created: $TEST_EVENT"

# Wait for logs to show
echo "⏳ Waiting for email notification logs..."
sleep 5

# Stop log monitoring
kill $LOG_PID 2>/dev/null

echo ""
echo "✅ Email notification test completed!"
echo "📋 Check the logs above for email notification messages"
echo "🎯 Expected to see:"
echo "   - '📧 Event created by user: Angel'"
echo "   - '🔍 Checking notification for user: Angel'"
echo "   - '📧 Sending email notification'"
echo "   - '📧 EMAIL NOTIFICATION (would send to andrea.carlevato@gmail.com)'" 