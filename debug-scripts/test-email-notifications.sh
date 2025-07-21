#!/bin/bash

echo "📧 Testing email notifications..."

# Start monitoring logs in background
echo "📋 Starting log monitoring..."
sudo journalctl -u us-calendar -f --no-pager &
LOG_PID=$!

# Wait a moment
sleep 2

# Test creating an event as Angel via API
echo "🧪 Creating test event as Angel..."

# First, get users to find Angel's ID
USERS_RESPONSE=$(curl -s http://localhost:5001/api/users)
echo "Users: $USERS_RESPONSE"

# Extract Angel's ID (assuming Angel is the second user, ID 2)
ANGEL_ID=2

# Create test event
TEST_EVENT=$(curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Email Notification",
    "description": "Testing email notifications for Andrea",
    "event_type": "holiday",
    "start_date": "2024-07-22T10:00:00Z",
    "end_date": "2024-07-22T11:00:00Z",
    "user_id": 2,
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
echo "🎯 Look for:"
echo "   - '📧 Event created by user: Angel'"
echo "   - '🔍 Checking notification for user: Angel'"
echo "   - '📧 Sending email notification'"
echo "   - '📧 EMAIL NOTIFICATION'" 