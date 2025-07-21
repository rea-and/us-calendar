#!/bin/bash

echo "🧪 Testing email configuration..."

# 1. Check current email settings
echo "🔍 Current email configuration:"
echo "Sender email: $(grep 'sender_email =' /var/www/us-calendar/backend/email_utils.py | cut -d'"' -f2)"
echo "Receiver email: $(grep 'receiver_email =' /var/www/us-calendar/backend/email_utils.py | cut -d'"' -f2)"

# Check if still using placeholders
if grep -q "your-gmail@gmail.com" /var/www/us-calendar/backend/email_utils.py; then
    echo "❌ Still using placeholder Gmail address!"
    echo "Run ./configure-email.sh to set up your Gmail credentials"
    exit 1
fi

if grep -q "your-app-password-here" /var/www/us-calendar/backend/email_utils.py; then
    echo "❌ Still using placeholder app password!"
    echo "Run ./configure-email.sh to set up your Gmail credentials"
    exit 1
fi

echo "✅ Email configuration looks good!"

echo ""

# 2. Check service status
echo "📋 Service status:"
if sudo systemctl is-active --quiet us-calendar; then
    echo "✅ Service is running"
else
    echo "❌ Service is not running"
    exit 1
fi

echo ""

# 3. Test API endpoints
echo "🧪 Testing API endpoints..."
echo "Health endpoint:"
curl -s http://localhost:5001/api/health
echo ""

echo "Users endpoint:"
curl -s http://localhost:5001/api/users
echo ""

echo ""

# 4. Create test event to trigger email
echo "📧 Creating test event to trigger email notification..."
echo "Creating event as Angel (user_id: 1)..."

RESPONSE=$(curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Email Test Event",
    "description": "Testing email notifications - '$(date)'",
    "event_type": "other",
    "start_date": "2025-07-22T10:00:00",
    "end_date": "2025-07-22T11:00:00",
    "user_id": 1,
    "applies_to_both": false
  }')

echo "Event creation response: $RESPONSE"

echo ""

# 5. Check logs for email activity
echo "📋 Checking logs for email activity..."
echo "Recent logs (last 15 lines):"
sudo journalctl -u us-calendar -n 15 --no-pager

echo ""

# 6. Check for specific email-related logs
echo "🔍 Looking for email-related logs..."
sudo journalctl -u us-calendar -n 20 --no-pager | grep -E "(📧|Email|SMTP|Gmail|notification)" || echo "No email-related logs found"

echo ""

# 7. Test direct email function
echo "🧪 Testing email function directly..."
cd /var/www/us-calendar/backend
python3 -c "
import sys
sys.path.append('/var/www/us-calendar/backend')
from email_utils import send_event_notification, should_send_notification

test_event = {
    'title': 'Direct Test Event',
    'user_name': 'Angel',
    'event_type': 'test',
    'start_date': '2025-07-22T10:00:00',
    'end_date': '2025-07-22T11:00:00',
    'applies_to_both': False
}

print('Testing should_send_notification...')
should_send = should_send_notification(test_event, 'Angel')
print(f'Should send notification: {should_send}')

if should_send:
    print('Testing send_event_notification...')
    result = send_event_notification(test_event, 'created')
    print(f'Send notification result: {result}')
    print('Check logs for email activity...')
else:
    print('Notification not sent (user is not Angel)')
"

echo ""

echo "✅ Email test completed!"
echo "📧 Check your email at andrea.carlevato@gmail.com for notifications"
echo "📋 Monitor logs with: sudo journalctl -u us-calendar -f" 