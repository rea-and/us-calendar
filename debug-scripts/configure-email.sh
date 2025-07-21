#!/bin/bash

echo "📧 Configuring email notifications..."

# 1. Check current email configuration
echo "🔍 Current email configuration:"
echo "Sender email: $(grep 'sender_email =' /opt/us-calendar/backend/email_utils.py | cut -d'"' -f2)"
echo "App password: $(grep 'your-app-password-here' /opt/us-calendar/backend/email_utils.py | wc -l) placeholder(s) found"

echo ""

# 2. Prompt for Gmail configuration
echo "📝 Please provide your Gmail configuration:"
echo ""

read -p "Enter your Gmail address (e.g., yourname@gmail.com): " GMAIL_ADDRESS
read -s -p "Enter your Gmail App Password: " GMAIL_APP_PASSWORD
echo ""

# 3. Validate inputs
if [[ -z "$GMAIL_ADDRESS" || -z "$GMAIL_APP_PASSWORD" ]]; then
    echo "❌ Error: Both Gmail address and App Password are required!"
    exit 1
fi

# 4. Update email_utils.py
echo "🔧 Updating email configuration..."
cd /opt/us-calendar/backend

# Create backup
cp email_utils.py email_utils.py.backup

# Update sender email
sed -i "s/sender_email = \"your-gmail@gmail.com\"/sender_email = \"$GMAIL_ADDRESS\"/" email_utils.py

# Update app password
sed -i "s/\"your-app-password-here\"/\"$GMAIL_APP_PASSWORD\"/" email_utils.py

# 5. Verify changes
echo "✅ Email configuration updated:"
echo "Sender email: $(grep 'sender_email =' email_utils.py | cut -d'"' -f2)"
echo "App password: $(grep -o '"[^"]*"' email_utils.py | grep -v 'your-app-password-here' | grep -v 'your-gmail@gmail.com' | grep -v 'andrea.carlevato@gmail.com' | head -1 | sed 's/"//g' | cut -c1-4)****"

echo ""

# 6. Copy to deployment
echo "📋 Copying to deployment directory..."
sudo cp email_utils.py /var/www/us-calendar/backend/email_utils.py
sudo chown www-data:www-data /var/www/us-calendar/backend/email_utils.py
sudo chmod 755 /var/www/us-calendar/backend/email_utils.py

# 7. Restart service
echo "🔄 Restarting service..."
sudo systemctl restart us-calendar
sleep 5

# 8. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 9. Test email functionality
echo "🧪 Testing email functionality..."
echo "Creating a test event to trigger email notification..."

# Create test event
curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Email Test Event",
    "description": "Testing email notifications after configuration",
    "event_type": "other",
    "start_date": "2025-07-22T10:00:00",
    "end_date": "2025-07-22T11:00:00",
    "user_id": 1,
    "applies_to_both": false
  }' > /dev/null

echo "✅ Test event created!"

# 10. Check logs for email activity
echo "📋 Checking recent logs for email activity..."
sleep 3
sudo journalctl -u us-calendar -n 10 --no-pager | grep -E "(📧|Email|SMTP|Gmail)"

echo ""
echo "✅ Email configuration completed!"
echo "📧 You should now receive email notifications when Angel creates events."
echo "📋 To check if emails are being sent, monitor the logs with:"
echo "   sudo journalctl -u us-calendar -f"
echo ""
echo "📝 If you need to update the configuration later, run this script again." 