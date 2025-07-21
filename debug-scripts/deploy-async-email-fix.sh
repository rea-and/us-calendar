#!/bin/bash

echo "🔧 Deploying async email fix to resolve UI blocking..."

# 1. Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# 2. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 3. Kill all processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 4. Copy updated email_utils.py to deployment
echo "📋 Copying updated email_utils.py..."
sudo cp /opt/us-calendar/backend/email_utils.py /var/www/us-calendar/backend/email_utils.py
sudo chown www-data:www-data /var/www/us-calendar/backend/email_utils.py
sudo chmod 755 /var/www/us-calendar/backend/email_utils.py

# 5. Verify the async fix is present
echo "🔍 Verifying async email fix..."
if grep -q "threading" /var/www/us-calendar/backend/email_utils.py; then
    echo "✅ Threading import found in email_utils.py"
else
    echo "❌ Threading import NOT found in email_utils.py"
    exit 1
fi

if grep -q "_send_email_sync" /var/www/us-calendar/backend/email_utils.py; then
    echo "✅ Async email function found in email_utils.py"
else
    echo "❌ Async email function NOT found in email_utils.py"
    exit 1
fi

# 6. Clear Python cache
echo "🧹 Clearing Python cache..."
cd /var/www/us-calendar/backend
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 7. Test backend import
echo "🧪 Testing backend import..."
python3 -c "
try:
    from app import app
    print('✅ App imported successfully')
    
    # Test email utils import
    from email_utils import send_event_notification, should_send_notification
    print('✅ Email utils imported successfully')
    
    print('Available routes:')
    for rule in app.url_map.iter_rules():
        print(f'  {rule.rule} -> {rule.endpoint}')
        
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

# 8. Start service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 9. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 10. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 11. Test API endpoints
echo "🧪 Testing API endpoints..."
sleep 2

echo "Testing /api/health:"
curl -s http://localhost:5001/api/health
echo ""

echo "Testing /api/users:"
curl -s http://localhost:5001/api/users
echo ""

echo "Testing /api/events:"
curl -s http://localhost:5001/api/events
echo ""

# 12. Test event creation speed
echo "🧪 Testing event creation speed..."
START_TIME=$(date +%s.%N)
curl -s -X POST http://localhost:5001/api/events \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Speed Test Event",
    "description": "Testing async email performance",
    "event_type": "other",
    "start_date": "2025-07-22T10:00:00",
    "end_date": "2025-07-22T11:00:00",
    "user_id": 1,
    "applies_to_both": false
  }' > /dev/null
END_TIME=$(date +%s.%N)

RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
echo "Event creation response time: ${RESPONSE_TIME}s"

if (( $(echo "$RESPONSE_TIME < 0.5" | bc -l) )); then
    echo "✅ Fast response time - async email working!"
else
    echo "⚠️  Response time might still be slow"
fi

# 13. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Async email fix deployment completed!"
echo ""
echo "🎯 The UI should now respond immediately when creating events!"
echo "📧 Email notifications will be sent in the background." 