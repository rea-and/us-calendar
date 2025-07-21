#!/bin/bash

echo "🔍 Debugging routes import issue..."

cd /var/www/us-calendar/backend

# 1. Check if routes.py has syntax errors
echo "🧪 Testing routes.py syntax..."
python3 -m py_compile routes.py
if [ $? -eq 0 ]; then
    echo "✅ routes.py syntax is valid"
else
    echo "❌ routes.py has syntax errors"
    exit 1
fi

# 2. Check the exact content around the health endpoint
echo "🔍 Checking health endpoint in routes.py..."
echo "Last 10 lines of routes.py:"
tail -10 routes.py

echo ""
echo "Lines containing 'health':"
grep -n "health" routes.py

# 3. Test importing routes directly
echo ""
echo "🧪 Testing direct routes import..."
python3 -c "
try:
    print('Testing import of routes module...')
    import routes
    print('✅ routes module imported successfully')
    
    # Check if health_check function exists
    if hasattr(routes, 'health_check'):
        print('✅ health_check function found in routes module')
        print(f'Function: {routes.health_check}')
    else:
        print('❌ health_check function NOT found in routes module')
        print('Available functions:')
        for attr in dir(routes):
            if not attr.startswith('_'):
                print(f'  {attr}')
                
except Exception as e:
    print(f'❌ Error importing routes: {e}')
    import traceback
    traceback.print_exc()
"

# 4. Test importing app and check routes
echo ""
echo "🧪 Testing app import and routes..."
python3 -c "
try:
    print('Testing app import...')
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
        
    # Check if there are any routes at all
    all_rules = list(app.url_map.iter_rules())
    print(f'Total routes found: {len(all_rules)}')
    
except Exception as e:
    print(f'❌ Error importing app: {e}')
    import traceback
    traceback.print_exc()
"

# 5. Check if there's a different routes.py being imported
echo ""
echo "🔍 Checking which routes.py is being imported..."
python3 -c "
import routes
print(f'Routes module location: {routes.__file__}')
"

echo ""
echo "✅ Routes import debugging completed!" 