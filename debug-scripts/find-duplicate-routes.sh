#!/bin/bash

echo "🔍 Finding duplicate routes.py files..."

# 1. Find all routes.py files
echo "📋 Searching for all routes.py files:"
find /opt/us-calendar -name "routes.py" -type f
find /var/www/us-calendar -name "routes.py" -type f
find /usr -name "routes.py" -type f 2>/dev/null | head -5

echo ""
echo "📋 Checking Python path:"
python3 -c "import sys; print('\\n'.join(sys.path))"

echo ""
echo "📋 Checking if there's a routes module in Python path:"
python3 -c "
import sys
import os
for path in sys.path:
    if path and os.path.exists(path):
        routes_file = os.path.join(path, 'routes.py')
        if os.path.exists(routes_file):
            print(f'Found routes.py in: {routes_file}')
"

echo ""
echo "🔍 Checking for routes.py in current directory:"
ls -la /var/www/us-calendar/backend/routes.py
ls -la /opt/us-calendar/backend/routes.py

echo ""
echo "🔍 Comparing routes.py files:"
if [ -f "/var/www/us-calendar/backend/routes.py" ] && [ -f "/opt/us-calendar/backend/routes.py" ]; then
    echo "Comparing files..."
    diff /var/www/us-calendar/backend/routes.py /opt/us-calendar/backend/routes.py
    if [ $? -eq 0 ]; then
        echo "✅ Files are identical"
    else
        echo "❌ Files are different"
    fi
fi

echo ""
echo "🧪 Testing import with explicit path:"
cd /var/www/us-calendar/backend
python3 -c "
import sys
import os

# Add current directory to path
sys.path.insert(0, os.getcwd())

print('Testing import with explicit path...')
try:
    # Import routes with explicit path
    import routes
    print('✅ routes imported successfully')
    print(f'Routes module location: {routes.__file__}')
    
    # Check if health_check exists
    if hasattr(routes, 'health_check'):
        print('✅ health_check function found')
    else:
        print('❌ health_check function NOT found')
        
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

echo ""
echo "✅ Duplicate routes search completed!" 