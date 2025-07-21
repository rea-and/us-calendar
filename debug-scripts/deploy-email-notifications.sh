#!/bin/bash

# Deploy email notifications and test them
echo "🚀 Deploying email notifications..."

# Navigate to project directory
cd /opt/us-calendar

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Check if email_utils.py exists
if [ ! -f "backend/email_utils.py" ]; then
    echo "❌ Error: email_utils.py not found!"
    exit 1
fi

# Test the email module
echo "🧪 Testing email module..."
python3 -c "
from backend.email_utils import send_event_notification, should_send_notification
test_event = {
    'title': 'Test Email Notification',
    'event_type': 'holiday',
    'start_date': '2024-01-15T10:00:00Z',
    'end_date': '2024-01-15T11:00:00Z',
    'description': 'Testing email notifications',
    'applies_to_both': True
}
print('✅ Email module imported successfully')
print('✅ Should send notification for Angel:', should_send_notification(test_event, 'Angel'))
print('✅ Should send notification for Andrea:', should_send_notification(test_event, 'Andrea'))
send_event_notification(test_event, 'created')
print('✅ Email notification test completed')
"

# Restart the backend service
echo "🔄 Restarting backend service..."
sudo systemctl restart us-calendar

# Check service status
echo "📊 Service status:"
sudo systemctl status us-calendar --no-pager

# Show recent logs
echo "📋 Recent backend logs:"
sudo journalctl -u us-calendar -n 20 --no-pager

echo "✅ Email notifications deployed!"
echo ""
echo "🎯 To test:"
echo "1. Create an event as Angel in the calendar"
echo "2. Check the backend logs: sudo journalctl -u us-calendar -f"
echo "3. You should see email notification logs in the console" 