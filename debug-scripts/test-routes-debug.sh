#!/bin/bash

echo "🔍 Debugging routes import issue..."

# Check if routes.py exists
echo "📋 Checking if routes.py exists:"
ls -la /var/www/us-calendar/backend/routes.py

# Check if app.py exists
echo "📋 Checking if app.py exists:"
ls -la /var/www/us-calendar/backend/app.py

# Test Python import
echo "🧪 Testing Python import:"
cd /var/www/us-calendar/backend
python3 -c "
from app import app
print('✅ App imported successfully')
print('Available routes:')
for rule in app.url_map.iter_rules():
    print(f'  {rule.rule} -> {rule.endpoint}')
"

# Test health endpoint directly
echo ""
echo "🧪 Testing health endpoint directly:"
cd /var/www/us-calendar/backend
python3 -c "
from app import app
with app.test_client() as client:
    response = client.get('/api/health')
    print(f'Health endpoint status: {response.status_code}')
    print(f'Health endpoint response: {response.data.decode()}')
"

# Check if there are any Python errors
echo ""
echo "📋 Checking for Python errors in logs:"
sudo journalctl -u us-calendar -n 20 --no-pager | grep -i error

echo ""
echo "✅ Routes debugging completed!" 