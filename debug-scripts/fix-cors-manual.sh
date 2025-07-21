#!/bin/bash

# Manual CORS fix script

echo "🔧 Manual CORS Fix..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Flask App..."
echo "================================"

# Check current app.py content
echo "📋 Current app.py CORS configuration:"
grep -n -A 10 -B 5 "CORS\|cors" /var/www/us-calendar/backend/app.py

echo ""
echo "📋 Full app.py content:"
cat /var/www/us-calendar/backend/app.py

echo ""
echo "🔧 Step 2: Creating New CORS Configuration..."
echo "================================"

# Create backup
cp /var/www/us-calendar/backend/app.py /var/www/us-calendar/backend/app.py.backup.$(date +%Y%m%d_%H%M%S)

# Create a completely new app.py with proper CORS
cat > /var/www/us-calendar/backend/app.py << 'EOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os

app = Flask(__name__)

# Configure CORS to allow all origins for production
CORS(app, origins=[
    "http://localhost:3000",
    "http://carlevato.net", 
    "https://carlevato.net",
    "http://www.carlevato.net",
    "https://www.carlevato.net",
    "http://157.230.244.80",
    "http://localhost",
    "http://127.0.0.1"
], supports_credentials=True)

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///calendar.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    user = db.relationship('User', backref=db.backref('events', lazy=True))

# Routes
@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()})

@app.route('/api/users', methods=['GET'])
def get_users():
    users = User.query.all()
    return jsonify([{
        'id': user.id,
        'name': user.name,
        'created_at': user.created_at.isoformat()
    } for user in users])

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({'error': 'Name is required'}), 400
    
    user = User(name=data['name'])
    db.session.add(user)
    db.session.commit()
    
    return jsonify({
        'id': user.id,
        'name': user.name,
        'created_at': user.created_at.isoformat()
    }), 201

@app.route('/api/events', methods=['GET'])
def get_events():
    events = Event.query.all()
    return jsonify([{
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'start_time': event.start_time.isoformat(),
        'end_time': event.end_time.isoformat(),
        'user_id': event.user_id,
        'user_name': event.user.name,
        'created_at': event.created_at.isoformat()
    } for event in events])

@app.route('/api/events', methods=['POST'])
def create_event():
    data = request.get_json()
    if not data or not all(key in data for key in ['title', 'start_time', 'end_time', 'user_id']):
        return jsonify({'error': 'Title, start_time, end_time, and user_id are required'}), 400
    
    try:
        start_time = datetime.fromisoformat(data['start_time'].replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(data['end_time'].replace('Z', '+00:00'))
    except ValueError:
        return jsonify({'error': 'Invalid date format'}), 400
    
    event = Event(
        title=data['title'],
        description=data.get('description', ''),
        start_time=start_time,
        end_time=end_time,
        user_id=data['user_id']
    )
    
    db.session.add(event)
    db.session.commit()
    
    return jsonify({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'start_time': event.start_time.isoformat(),
        'end_time': event.end_time.isoformat(),
        'user_id': event.user_id,
        'user_name': event.user.name,
        'created_at': event.created_at.isoformat()
    }), 201

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
def delete_event(event_id):
    event = Event.query.get_or_404(event_id)
    db.session.delete(event)
    db.session.commit()
    return jsonify({'message': 'Event deleted'})

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        
        # Create default users if they don't exist
        if not User.query.filter_by(name='Angel').first():
            angel = User(name='Angel')
            db.session.add(angel)
        
        if not User.query.filter_by(name='Andrea').first():
            andrea = User(name='Andrea')
            db.session.add(andrea)
        
        db.session.commit()
    
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF

echo "✅ New app.py created with proper CORS configuration"

echo ""
echo "🔍 Step 3: Checking New Configuration..."
echo "================================"

echo "📋 New CORS configuration:"
grep -n -A 10 -B 5 "CORS\|cors" /var/www/us-calendar/backend/app.py

echo ""
echo "🔄 Step 4: Restarting Backend Service..."
echo "================================"

# Restart the backend service
systemctl restart us-calendar
if systemctl is-active us-calendar; then
    echo "✅ Backend restarted successfully"
else
    echo "❌ Backend failed to restart"
    exit 1
fi

echo ""
echo "🧪 Step 5: Testing CORS Headers..."
echo "================================"

# Wait a moment for the service to fully start
sleep 3

# Test CORS headers
echo "📋 Testing CORS headers from localhost..."
curl -s -I http://localhost/api/users | grep -i "access-control"

echo "📋 Testing CORS headers from domain..."
curl -s -I http://carlevato.net/api/users | grep -i "access-control"

echo "📋 Testing CORS headers with Origin header..."
curl -s -H "Origin: http://carlevato.net" \
     -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -I http://localhost/api/users | grep -i "access-control"

echo ""
echo "🔍 Step 6: Testing API Access..."
echo "================================"

# Test API access
echo "📋 Testing API from localhost..."
curl -s http://localhost/api/users | head -3

echo "📋 Testing API from domain..."
curl -s http://carlevato.net/api/users | head -3

echo ""
echo "✅ Manual CORS Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 If still having issues:"
echo "   1. Clear browser cache completely"
echo "   2. Check browser console for errors"
echo "   3. Try different browser (Chrome, Firefox)"
echo "   4. Check if React app is making API calls"
echo ""
echo "📱 Test on mobile:"
echo "   - Try from mobile data (not WiFi)"
echo "   - Clear mobile browser cache" 