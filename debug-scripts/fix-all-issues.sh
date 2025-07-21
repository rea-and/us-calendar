#!/bin/bash

echo "🔧 Fixing all identified issues..."

cd /var/www/us-calendar/backend

# 1. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 2. Kill all processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 3. Copy email_utils.py if missing
echo "📋 Checking email_utils.py..."
if [ ! -f "email_utils.py" ]; then
    echo "📋 Copying email_utils.py..."
    sudo cp /opt/us-calendar/backend/email_utils.py .
    sudo chown www-data:www-data email_utils.py
    sudo chmod 755 email_utils.py
else
    echo "✅ email_utils.py already exists"
fi

# 4. Check for syntax errors in routes.py
echo "🔍 Checking for syntax errors in routes.py..."
python3 -m py_compile routes.py
if [ $? -ne 0 ]; then
    echo "❌ Syntax error found in routes.py"
    echo "📋 Checking lines around 120..."
    sed -n '115,125p' routes.py
    echo "📋 Attempting to fix syntax error..."
    # Let's check what's wrong with the else statement
    echo "Lines around the else statement:"
    grep -n -A 5 -B 5 "else:" routes.py
    exit 1
else
    echo "✅ routes.py syntax is valid"
fi

# 5. Clear Python cache
echo "🧹 Clearing Python cache..."
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 6. Test complete import
echo "🧪 Testing complete import..."
python3 -c "
import sys
import os

# Add current directory to path
sys.path.insert(0, os.getcwd())

print('Testing complete import...')

try:
    # Import app with proper configuration
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

# 7. Test health endpoint directly
echo ""
echo "🧪 Testing health endpoint directly..."
python3 -c "
try:
    from app import app
    with app.test_client() as client:
        response = client.get('/api/health')
        print(f'Health endpoint status: {response.status_code}')
        if response.status_code == 200:
            print(f'Health endpoint response: {response.data.decode()}')
        else:
            print(f'Health endpoint error: {response.data.decode()}')
        
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

# 12. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ All issues fix completed!" 