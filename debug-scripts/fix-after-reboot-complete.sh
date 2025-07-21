#!/bin/bash

echo "🔧 Complete fix after reboot..."

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

# 4. Copy latest backend files to deployment
echo "📋 Copying latest backend files..."
sudo cp /opt/us-calendar/backend/routes.py /var/www/us-calendar/backend/routes.py
sudo cp /opt/us-calendar/backend/models.py /var/www/us-calendar/backend/models.py
sudo cp /opt/us-calendar/backend/email_utils.py /var/www/us-calendar/backend/email_utils.py
sudo cp /opt/us-calendar/backend/app.py /var/www/us-calendar/backend/app.py

# 5. Set correct permissions
echo "🔐 Setting permissions..."
sudo chown -R www-data:www-data /var/www/us-calendar/backend/
sudo chmod -R 755 /var/www/us-calendar/backend/

# 6. Verify the files
echo "🔍 Verifying files..."
if grep -q "health_check" /var/www/us-calendar/backend/routes.py; then
    echo "✅ health_check function found in deployment routes.py"
else
    echo "❌ health_check function NOT found in deployment routes.py"
    exit 1
fi

if grep -q "extend_existing" /var/www/us-calendar/backend/models.py; then
    echo "✅ extend_existing fix found in deployment models.py"
else
    echo "❌ extend_existing fix NOT found in deployment models.py"
    exit 1
fi

if [ -f "/var/www/us-calendar/backend/email_utils.py" ]; then
    echo "✅ email_utils.py found in deployment directory"
else
    echo "❌ email_utils.py NOT found in deployment directory"
    exit 1
fi

# 7. Clear Python cache
echo "🧹 Clearing Python cache..."
cd /var/www/us-calendar/backend
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 8. Test backend import
echo "🧪 Testing backend import..."
python3 -c "
try:
    from app import app
    print('✅ App imported successfully')
    print('Available routes:')
    for rule in app.url_map.iter_rules():
        print(f'  {rule.rule} -> {rule.endpoint}')
    
    # Check specifically for health endpoint
    health_rules = [rule for rule in app.url_map.iter_rules() if 'health' in rule.rule]
    if health_rules:
        print('✅ Health endpoint found in routes:')
        for rule in health_rules:
            print(f'  {rule.rule} -> {rule.endpoint}')
    else:
        print('❌ Health endpoint NOT found in routes')
        
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

# 9. Start service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 10. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 11. Rebuild frontend
echo "🔨 Rebuilding frontend..."
cd /opt/us-calendar/frontend
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed!"
    exit 1
fi

# 12. Deploy frontend
echo "📦 Deploying frontend..."
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 13. Test all endpoints
echo "🧪 Testing all endpoints..."
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

# 14. Test frontend
echo "🧪 Testing frontend..."
if curl -s http://localhost/ | grep -q "calendar"; then
    echo "✅ Frontend is loading properly"
else
    echo "❌ Frontend might have issues"
    echo "📋 Frontend response:"
    curl -s http://localhost/ | head -10
fi

# 15. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 16. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Complete fix after reboot completed!" 