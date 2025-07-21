#!/bin/bash

# Fix database schema issue

echo "🔧 Fixing database schema issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Database..."
echo "================================"

# Check if the database file exists
echo "📋 Checking database file:"
ls -la /opt/us-calendar/backend/calendar.db 2>/dev/null || echo "Database file not found"

echo ""
echo "📋 Checking database tables (if exists):"
cd /opt/us-calendar/backend
sqlite3 calendar.db ".tables" 2>/dev/null || echo "Cannot access database"

echo ""
echo "🔍 Step 2: Backing Up Current Database..."
echo "================================"

# Backup the current database if it exists
if [ -f "/opt/us-calendar/backend/calendar.db" ]; then
    echo "📋 Backing up current database..."
    cp /opt/us-calendar/backend/calendar.db /opt/us-calendar/backend/calendar.db.backup
    echo "✅ Database backed up to calendar.db.backup"
else
    echo "📋 No existing database to backup"
fi

echo ""
echo "🔍 Step 3: Checking Models File..."
echo "================================"

# Check the models file to understand the schema
echo "📋 Models file content:"
cat /opt/us-calendar/backend/models.py

echo ""
echo "🔍 Step 4: Creating Database Schema..."
echo "================================"

# Create a Python script to recreate the database
echo "📋 Creating database recreation script..."
cat > /opt/us-calendar/backend/recreate_db.py << 'EOF'
#!/usr/bin/env python3

import os
import sqlite3
from app import app, db
from models import User, Event

# Remove existing database
if os.path.exists('calendar.db'):
    os.remove('calendar.db')
    print("Removed existing database")

# Create new database
with app.app_context():
    # Create all tables
    db.create_all()
    print("Created database tables")
    
    # Create default user
    default_user = User(name='Angel')
    db.session.add(default_user)
    db.session.commit()
    print("Created default user: Angel")
    
    # Verify tables exist
    cursor = db.engine.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cursor]
    print(f"Tables in database: {tables}")
    
    # Verify user exists
    user = User.query.filter_by(name='Angel').first()
    if user:
        print(f"Verified user exists: {user.name}")
    else:
        print("ERROR: User not found after creation")

print("Database recreation complete!")
EOF

echo "📋 Database recreation script created"

echo ""
echo "🔍 Step 5: Running Database Recreation..."
echo "================================"

# Run the database recreation script
echo "📋 Running database recreation..."
cd /opt/us-calendar/backend
python3 recreate_db.py

echo ""
echo "🔍 Step 6: Verifying Database Schema..."
echo "================================"

# Verify the database was created correctly
echo "📋 Checking database tables:"
sqlite3 calendar.db ".tables"

echo ""
echo "📋 Checking user table:"
sqlite3 calendar.db "SELECT * FROM user;"

echo ""
echo "📋 Checking event table:"
sqlite3 calendar.db "PRAGMA table_info(event);"

echo ""
echo "🔍 Step 7: Testing Backend with New Database..."
echo "================================"

# Test if the backend can start with the new database
echo "📋 Testing backend startup..."
cd /opt/us-calendar/backend
timeout 10 python3 app.py &
sleep 3

echo "📋 Testing backend connection:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

# Stop the test process
pkill -f "python3 app.py"

echo ""
echo "🔍 Step 8: Restarting Backend Service..."
echo "================================"

# Restart the backend service
echo "📋 Restarting backend service..."
systemctl restart us-calendar-backend

# Wait for the service to start
sleep 5

echo "📋 Checking service status:"
systemctl status us-calendar-backend

echo ""
echo "🔍 Step 9: Testing Full Application..."
echo "================================"

# Test the full application
echo "📋 Testing backend connection:"
curl -I http://localhost:5001/api/events 2>/dev/null | head -5

echo "📋 Testing API through Apache:"
curl -I http://localhost/api/events 2>/dev/null | head -5

echo "📋 Testing calendar access:"
curl -I http://localhost/us/ 2>/dev/null | head -5

echo "📋 Testing external access:"
curl -I http://157.230.244.80/us/ 2>/dev/null | head -5

echo ""
echo "🔍 Step 10: Checking Logs..."
echo "================================"

# Check backend logs
echo "📋 Backend service logs:"
journalctl -u us-calendar-backend --no-pager -n 10

echo "📋 Apache error logs:"
tail -5 /var/log/apache2/us-calendar-error.log

echo ""
echo "✅ Database Schema Fix Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - http://carlevato.net/us/ (domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If both HTTP and API show 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check backend logs: journalctl -u us-calendar-backend -f"
echo "   2. Check Apache logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   3. Test backend directly: curl http://localhost:5001/api/events"
echo "   4. Restore backup: cp /opt/us-calendar/backend/calendar.db.backup /opt/us-calendar/backend/calendar.db" 