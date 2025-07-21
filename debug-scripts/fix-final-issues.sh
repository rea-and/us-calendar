#!/bin/bash

# Fix final issues: database schema and Apache configuration

echo "🔧 Fixing final issues: database schema and Apache configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Fixing Database Schema..."
echo "================================"

# Stop backend service
systemctl stop us-calendar

# Backup existing database
if [ -f "/var/www/us-calendar/backend/calendar.db" ]; then
    echo "📋 Backing up existing database..."
    cp /var/www/us-calendar/backend/calendar.db /var/www/us-calendar/backend/calendar.db.backup
fi

# Remove old database and recreate with correct schema
echo "📋 Recreating database with correct schema..."
rm -f /var/www/us-calendar/backend/calendar.db

# Create new database with correct schema
cd /var/www/us-calendar/backend
source ../venv/bin/activate

# Create a Python script to set up the database
cat > setup_db.py << 'EOF'
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///calendar.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Models with correct schema
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    events = db.relationship('Event', backref='user', lazy=True)

class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    event_type = db.Column(db.String(50), default='work')
    start_date = db.Column(db.DateTime, nullable=False)
    end_date = db.Column(db.DateTime, nullable=False)
    applies_to_both = db.Column(db.Boolean, default=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

with app.app_context():
    db.create_all()
    # Create default user if none exists
    if not User.query.first():
        default_user = User(username='admin', password='admin123')
        db.session.add(default_user)
        db.session.commit()
        print("✅ Database created with default user")
    else:
        print("✅ Database created successfully")
EOF

# Run the database setup
python setup_db.py
rm setup_db.py

echo "✅ Database schema fixed"

echo ""
echo "🔍 Step 2: Fixing Apache Configuration..."
echo "================================"

# Check current Apache configuration
echo "📋 Current Apache configuration:"
apache2ctl -S 2>/dev/null | head -10

# Check if our site is enabled
if [ -L "/etc/apache2/sites-enabled/us-calendar.conf" ]; then
    echo "✅ Our site is enabled"
else
    echo "❌ Our site is not enabled"
    echo "📋 Enabling our site..."
    a2ensite us-calendar.conf
fi

# Check port configuration
echo "📋 Checking Apache port configuration..."
if grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "❌ Apache is configured to listen on port 8080"
    echo "📋 Fixing port configuration..."
    sed -i 's/Listen 8080/Listen 80/' /etc/apache2/ports.conf
    echo "✅ Port configuration fixed"
else
    echo "✅ Apache is configured to listen on port 80"
fi

# Check if default site is interfering
if [ -L "/etc/apache2/sites-enabled/000-default.conf" ]; then
    echo "❌ Default site is enabled and may interfere"
    echo "📋 Disabling default site..."
    a2dissite 000-default.conf
fi

# Test Apache configuration
echo "📋 Testing Apache configuration..."
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    apache2ctl configtest 2>&1
    exit 1
fi

echo ""
echo "🔍 Step 3: Restarting Services..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Start backend service
echo "📋 Starting backend service..."
systemctl start us-calendar

# Wait for services to start
sleep 3

# Check service status
if systemctl is-active apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    tail -10 /var/log/apache2/error.log
fi

if systemctl is-active us-calendar; then
    echo "✅ Backend service is running"
else
    echo "❌ Backend service failed to start"
    journalctl -u us-calendar --no-pager -n 10
fi

echo ""
echo "🔍 Step 4: Testing Everything..."
echo "================================"

# Wait for services to fully start
sleep 2

# Test Apache port
echo "📋 Testing Apache port..."
if netstat -tlnp | grep :80; then
    echo "✅ Apache is listening on port 80"
else
    echo "❌ Apache is not listening on port 80"
    netstat -tlnp | grep apache2
fi

# Test HTTP response
echo "📋 Testing HTTP response..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/ 2>/dev/null || echo "000")
echo "HTTP Status: $HTTP_STATUS"

# Test HTTPS response
echo "📋 Testing HTTPS response..."
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://localhost/us/ --insecure 2>/dev/null || echo "000")
echo "HTTPS Status: $HTTPS_STATUS"

# Test API
echo "📋 Testing API..."
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/users 2>/dev/null || echo "000")
echo "API Status: $API_STATUS"

# Test static files
echo "📋 Testing static files..."
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    JS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/us/static/js/$JS_FILENAME" 2>/dev/null || echo "000")
    echo "JavaScript file status: $JS_STATUS"
    
    # Test MIME type
    JS_MIME=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" 2>/dev/null | grep -i "content-type" | head -1)
    echo "JavaScript MIME type: $JS_MIME"
else
    echo "❌ No JavaScript files found"
fi

echo ""
echo "🔍 Step 5: Testing External Access..."
echo "================================"

# Test external access
echo "📋 Testing external HTTP access..."
EXTERNAL_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://carlevato.net/us/ 2>/dev/null || echo "000")
echo "External HTTP Status: $EXTERNAL_HTTP"

echo "📋 Testing external HTTPS access..."
EXTERNAL_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://carlevato.net/us/ 2>/dev/null || echo "000")
echo "External HTTPS Status: $EXTERNAL_HTTPS"

echo ""
echo "✅ Final Issues Fix Complete!"
echo ""
echo "🌐 Your calendar should now be available at:"
echo "   - https://carlevato.net/us/ (HTTPS - recommended)"
echo "   - http://carlevato.net/us/ (HTTP)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If everything shows 200 status codes, your calendar is working!"
echo "📱 Test on your phone and computer to verify it works everywhere."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check Apache logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Check backend logs: journalctl -u us-calendar -f"
echo "   3. Test locally: curl -I http://localhost/us/" 