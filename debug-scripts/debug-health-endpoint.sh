#!/bin/bash

echo "🔍 Debugging health endpoint registration..."

cd /var/www/us-calendar/backend

# 1. Check the exact line numbers of the health endpoint
echo "🔍 Checking health endpoint in routes.py..."
echo "Lines containing 'health':"
grep -n "health" routes.py

echo ""
echo "Lines around health endpoint (lines 115-125):"
sed -n '115,125p' routes.py

# 2. Check if there are any syntax errors before the health endpoint
echo ""
echo "🧪 Testing routes.py syntax up to line 120..."
python3 -c "
import ast
with open('routes.py', 'r') as f:
    content = f.read()
    lines = content.split('\\n')
    # Test syntax up to line 120
    test_content = '\\n'.join(lines[:120])
    try:
        ast.parse(test_content)
        print('✅ Syntax is valid up to line 120')
    except SyntaxError as e:
        print(f'❌ Syntax error at line {e.lineno}: {e.text}')
"

# 3. Test importing routes step by step
echo ""
echo "🧪 Testing routes import step by step..."
python3 -c "
import sys
import os

# Add current directory to path
sys.path.insert(0, os.getcwd())

print('Testing step-by-step import...')

try:
    # Import Flask and create app
    from flask import Flask
    app = Flask(__name__)
    print('✅ Flask app created')
    
    # Import database
    from flask_sqlalchemy import SQLAlchemy
    db = SQLAlchemy(app)
    print('✅ Database initialized')
    
    # Import models
    from models import User, Event
    print('✅ Models imported')
    
    # Import email_utils
    from email_utils import send_event_notification, should_send_notification
    print('✅ Email utils imported')
    
    # Now import routes
    print('Importing routes...')
    from routes import *
    print('✅ Routes imported successfully')
    
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

# 4. Check if health_check function exists in routes module
echo ""
echo "🧪 Checking if health_check function exists..."
python3 -c "
try:
    import routes
    print('✅ Routes module imported')
    
    if hasattr(routes, 'health_check'):
        print('✅ health_check function exists in routes module')
        print(f'Function: {routes.health_check}')
    else:
        print('❌ health_check function NOT found in routes module')
        print('Available functions:')
        for attr in dir(routes):
            if not attr.startswith('_'):
                print(f'  {attr}')
                
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

# 5. Test the health endpoint directly
echo ""
echo "🧪 Testing health endpoint directly..."
python3 -c "
try:
    from app import app
    with app.test_client() as client:
        response = client.get('/api/health')
        print(f'Health endpoint status: {response.status_code}')
        print(f'Health endpoint response: {response.data.decode()}')
        
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
"

echo ""
echo "✅ Health endpoint debugging completed!" 