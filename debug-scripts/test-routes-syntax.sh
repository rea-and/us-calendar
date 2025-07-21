#!/bin/bash

echo "🔍 Testing routes.py syntax and import..."

cd /var/www/us-calendar/backend

# Test Python syntax
echo "🧪 Testing Python syntax:"
python3 -m py_compile routes.py
if [ $? -eq 0 ]; then
    echo "✅ routes.py syntax is valid"
else
    echo "❌ routes.py has syntax errors"
    exit 1
fi

# Test importing routes directly
echo ""
echo "🧪 Testing routes import:"
python3 -c "
try:
    from routes import *
    print('✅ routes.py imported successfully')
except Exception as e:
    print(f'❌ Error importing routes: {e}')
    import traceback
    traceback.print_exc()
"

# Test if health_check function exists
echo ""
echo "🧪 Testing if health_check function exists:"
python3 -c "
try:
    from routes import health_check
    print('✅ health_check function imported successfully')
    print(f'Function: {health_check}')
except Exception as e:
    print(f'❌ Error importing health_check: {e}')
"

# Test app import and routes after routes import
echo ""
echo "🧪 Testing app routes after routes import:"
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

echo ""
echo "✅ Routes syntax testing completed!" 