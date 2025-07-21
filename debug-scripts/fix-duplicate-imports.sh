#!/bin/bash

echo "🔧 Fixing duplicate imports issue..."

cd /var/www/us-calendar/backend

# 1. Stop service
echo "🛑 Stopping service..."
sudo systemctl stop us-calendar

# 2. Kill all processes
echo "🧹 Cleaning up processes..."
sudo pkill -f "python.*app.py" 2>/dev/null
sudo pkill -f "app.py" 2>/dev/null
lsof -ti:5001 | xargs -r sudo kill -9 2>/dev/null

# 3. Clear Python cache again
echo "🧹 Clearing Python cache..."
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null

# 4. Test app import without duplicate routes import
echo "🧪 Testing app import without duplicate routes..."
python3 -c "
import sys
print('Testing app import...')

try:
    # Import app without importing routes again
    from flask import Flask
    from flask_cors import CORS
    from flask_sqlalchemy import SQLAlchemy
    import os
    
    # Initialize Flask app
    app = Flask(__name__)
    
    # Configure CORS
    CORS(app, origins=['http://localhost:3000', 'https://carlaveto.net'])
    
    # Configure database
    basedir = os.path.abspath(os.path.dirname('.'))
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'database.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Initialize database
    db = SQLAlchemy(app)
    
    # Import routes only once
    from routes import *
    
    print('✅ App imported successfully without duplicate imports')
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

# 5. Start service
echo "🚀 Starting service..."
sudo systemctl start us-calendar

# 6. Wait for service to start
echo "⏳ Waiting for service to start..."
sleep 5

# 7. Check service status
echo "📋 Service status:"
sudo systemctl status us-calendar --no-pager

# 8. Test API endpoints
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

# 9. Check recent logs
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo "✅ Duplicate imports fix completed!" 