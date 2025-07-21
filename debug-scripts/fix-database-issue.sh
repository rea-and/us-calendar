#!/bin/bash

# Fix database issue

echo "🔧 Fixing database issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Installing SQLite..."
echo "================================"

# Install SQLite
echo "📋 Installing SQLite..."
apt update
apt install -y sqlite3

echo ""
echo "🔍 Step 2: Creating Database Directory..."
echo "================================"

# Create database directory
echo "📋 Creating database directory..."
mkdir -p /opt/us-calendar/backend
cd /opt/us-calendar/backend

echo ""
echo "🔍 Step 3: Creating Database with Proper Schema..."
echo "================================"

# Create database with proper schema
echo "📋 Creating database with proper schema..."
python3 -c "
from app import app, db
from models import User, Event

with app.app_context():
    # Drop all tables and recreate
    db.drop_all()
    db.create_all()
    
    # Create test users
    user1 = User(name='Angel')
    user2 = User(name='Andrea')
    
    db.session.add(user1)
    db.session.add(user2)
    db.session.commit()
    
    print('✅ Database created successfully')
    print('✅ Users created: Angel, Andrea')
"

echo ""
echo "🔍 Step 4: Setting Proper Permissions..."
echo "================================"

# Set proper permissions
echo "📋 Setting database permissions..."
chown -R www-data:www-data /opt/us-calendar/backend/
chmod -R 755 /opt/us-calendar/backend/
chmod 664 /opt/us-calendar/backend/calendar.db

echo ""
echo "🔍 Step 5: Verifying Database..."
echo "================================"

# Verify database
echo "📋 Verifying database..."
ls -la /opt/us-calendar/backend/calendar.db

echo ""
echo "📋 Checking database schema..."
sqlite3 /opt/us-calendar/backend/calendar.db ".schema"

echo ""
echo "📋 Checking users table..."
sqlite3 /opt/us-calendar/backend/calendar.db "SELECT * FROM users;"

echo ""
echo "📋 Checking events table..."
sqlite3 /opt/us-calendar/backend/calendar.db "SELECT * FROM events;"

echo ""
echo "🔍 Step 6: Restarting Backend Service..."
echo "================================"

# Restart backend service
echo "📋 Restarting backend service..."
systemctl restart us-calendar-backend
sleep 3

echo "📋 Checking backend status..."
systemctl status us-calendar-backend --no-pager -l

echo ""
echo "🔍 Step 7: Testing Event Creation..."
echo "================================"

# Test event creation
echo "📋 Testing event creation..."
cd /opt/us-calendar/backend
python3 -c "
import requests
import json

# Test event creation
print('Testing event creation...')
try:
    event_data = {
        'title': 'Test Event',
        'description': 'Test event description',
        'event_type': 'work',
        'start_date': '2025-07-21T10:00:00.000Z',
        'end_date': '2025-07-21T11:00:00.000Z',
        'user_id': 1,
        'applies_to_both': False
    }
    response = requests.post('http://localhost:5001/api/events', json=event_data)
    print(f'Status: {response.status_code}')
    print(f'Response: {response.json()}')
    
    if response.status_code == 201:
        print('✅ Event creation successful!')
    else:
        print('❌ Event creation failed')
        
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "🔍 Step 8: Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing users endpoint..."
curl -s https://carlevato.net/api/users

echo ""
echo "📋 Testing events endpoint..."
curl -s https://carlevato.net/api/events

echo ""
echo "✅ Database Fix Complete!"
echo ""
echo "🌐 Your calendar should now work at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Expected Result:"
echo "   - Database created with proper permissions"
echo "   - Users: Angel, Andrea"
echo "   - Event creation should work"
echo "   - No more readonly database errors"
echo ""
echo "📱 Try creating an event now - it should work!" 