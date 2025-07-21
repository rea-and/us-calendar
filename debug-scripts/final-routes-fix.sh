#!/bin/bash

echo "🔧 Final routes fix - ensuring latest changes are applied..."

# 1. Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# 2. Check if models.py has the fix
echo "🔍 Checking models.py for extend_existing fix..."
if grep -q "extend_existing" backend/models.py; then
    echo "✅ extend_existing fix found in models.py"
else
    echo "❌ extend_existing fix NOT found!"
    exit 1
fi

# 3. Check if routes.py has health endpoint
echo "🔍 Checking routes.py for health endpoint..."
if grep -q "health_check" backend/routes.py; then
    echo "✅ health_check function found in routes.py"
else
    echo "❌ health_check function NOT found!"
    exit 1
fi

# 4. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 5. Kill any remaining processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 6. Test Python import in virtual environment
echo "🧪 Testing Python import in virtual environment..."
cd /var/www/us-calendar/backend
source /var/www/us-calendar/venv/bin/activate
python -c "
from app import app
print('✅ App imported successfully in virtual environment')
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
"

# 7. Start service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 8. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 9. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 10. Test API endpoints
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

# 11. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Final routes fix completed!" 