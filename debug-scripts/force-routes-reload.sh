#!/bin/bash

echo "🔧 Force reloading routes - clearing cache and ensuring fixes..."

# 1. Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# 2. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 3. Kill all processes
echo "🧹 Cleaning up all processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 4. Clear Python cache
echo "🧹 Clearing Python cache..."
cd /var/www/us-calendar/backend
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 5. Verify the extend_existing fix is in the actual file
echo "🔍 Verifying extend_existing fix in models.py..."
if grep -q "extend_existing" /var/www/us-calendar/backend/models.py; then
    echo "✅ extend_existing fix found in /var/www/us-calendar/backend/models.py"
else
    echo "❌ extend_existing fix NOT found in /var/www/us-calendar/backend/models.py"
    echo "📋 Copying fix from /opt/us-calendar/backend/models.py..."
    cp /opt/us-calendar/backend/models.py /var/www/us-calendar/backend/models.py
fi

# 6. Test Python import with cache cleared
echo "🧪 Testing Python import with cleared cache..."
cd /var/www/us-calendar/backend
source /var/www/us-calendar/venv/bin/activate
python -c "
import sys
print(f'Python path: {sys.path[0]}')
print('Testing import...')

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
    print(f'❌ Import error: {e}')
    import traceback
    traceback.print_exc()
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

echo "✅ Force routes reload completed!" 