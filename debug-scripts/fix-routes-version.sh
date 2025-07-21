#!/bin/bash

echo "🔧 Fixing routes.py version mismatch..."

# 1. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 2. Kill all processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 3. Backup old routes.py
echo "📦 Backing up old routes.py..."
sudo cp /var/www/us-calendar/backend/routes.py /var/www/us-calendar/backend/routes.py.backup

# 4. Copy latest routes.py
echo "📋 Copying latest routes.py..."
sudo cp /opt/us-calendar/backend/routes.py /var/www/us-calendar/backend/routes.py

# 5. Set correct permissions
echo "🔐 Setting permissions..."
sudo chown www-data:www-data /var/www/us-calendar/backend/routes.py
sudo chmod 755 /var/www/us-calendar/backend/routes.py

# 6. Verify the copy
echo "🔍 Verifying routes.py copy..."
if grep -q "health_check" /var/www/us-calendar/backend/routes.py; then
    echo "✅ health_check function found in deployment routes.py"
else
    echo "❌ health_check function NOT found in deployment routes.py"
    exit 1
fi

if grep -q "email_utils" /var/www/us-calendar/backend/routes.py; then
    echo "✅ email_utils import found in deployment routes.py"
else
    echo "❌ email_utils import NOT found in deployment routes.py"
    exit 1
fi

# 7. Clear Python cache
echo "🧹 Clearing Python cache..."
cd /var/www/us-calendar/backend
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 8. Test Python import
echo "🧪 Testing Python import..."
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

# 11. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 12. Test API endpoints
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

# 13. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Routes version fix completed!" 