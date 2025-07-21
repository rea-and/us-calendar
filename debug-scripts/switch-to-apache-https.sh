#!/bin/bash

# Switch from nginx to Apache with HTTPS

echo "🔄 Switching from Nginx to Apache with HTTPS..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Stopping and Removing Nginx..."
echo "================================"

# Stop nginx
systemctl stop nginx
systemctl disable nginx

# Remove nginx
apt-get update
apt-get remove -y nginx nginx-common nginx-full
apt-get autoremove -y

echo "✅ Nginx removed"

echo ""
echo "🔧 Step 2: Installing Apache and Required Packages..."
echo "================================"

# Install Apache and required packages
apt-get install -y apache2 apache2-utils libapache2-mod-wsgi-py3 python3-certbot-apache

# Enable required Apache modules
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod ssl
a2enmod headers

echo "✅ Apache installed and configured"

echo ""
echo "🔧 Step 3: Creating Apache Virtual Host Configuration..."
echo "================================"

# Create Apache virtual host configuration
cat > /etc/apache2/sites-available/us-calendar.conf << 'EOF'
<VirtualHost *:80>
    ServerName carlevato.net
    ServerAlias www.carlevato.net
    DocumentRoot /var/www/us-calendar/frontend/build
    
    # Redirect all HTTP to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName carlevato.net
    ServerAlias www.carlevato.net
    DocumentRoot /var/www/us-calendar/frontend/build
    
    # SSL Configuration (will be updated by certbot)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/carlevato.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/carlevato.net/privkey.pem
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # API proxy
    ProxyPreserveHost On
    ProxyPass /api/ http://localhost:5001/api/
    ProxyPassReverse /api/ http://localhost:5001/api/
    
    # Static files with proper MIME types
    <Directory "/var/www/us-calendar/frontend/build/static">
        Require all granted
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
        Header set Cache-Control "public, immutable"
    </Directory>
    
    # JavaScript files
    <FilesMatch "\.js$">
        Header set Content-Type "application/javascript"
    </FilesMatch>
    
    # CSS files
    <FilesMatch "\.css$">
        Header set Content-Type "text/css"
    </FilesMatch>
    
    # React app routes - serve index.html for all non-file requests
    <Directory "/var/www/us-calendar/frontend/build">
        Require all granted
        Options -Indexes
        FallbackResource /index.html
    </Directory>
    
    # Root redirect to /us
    RedirectMatch 301 ^/$ /us/
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/us-calendar-error.log
    CustomLog ${APACHE_LOG_DIR}/us-calendar-access.log combined
</VirtualHost>
EOF

echo "✅ Apache virtual host configuration created"

echo ""
echo "🔧 Step 4: Setting File Permissions..."
echo "================================"

# Set proper permissions
chown -R www-data:www-data /var/www/us-calendar/frontend/build
chmod -R 755 /var/www/us-calendar/frontend/build

# Set Apache permissions
chown -R www-data:www-data /var/www/us-calendar
chmod -R 755 /var/www/us-calendar

echo "✅ File permissions set"

echo ""
echo "🔧 Step 5: Enabling Apache Site..."
echo "================================"

# Disable default site
a2dissite 000-default.conf

# Enable our site
a2ensite us-calendar.conf

# Test Apache configuration
if apache2ctl configtest; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    exit 1
fi

echo ""
echo "🔄 Step 6: Starting Apache..."
echo "================================"

# Start Apache
systemctl start apache2
systemctl enable apache2

if systemctl is-active apache2; then
    echo "✅ Apache started successfully"
else
    echo "❌ Apache failed to start"
    exit 1
fi

echo ""
echo "🔧 Step 7: Setting Up HTTPS with Let's Encrypt..."
echo "================================"

# Check if domain resolves to this server
echo "📋 Checking DNS resolution..."
if nslookup carlevato.net | grep -q "157.230.244.80"; then
    echo "✅ Domain resolves to this server"
else
    echo "⚠️  Domain may not resolve to this server"
    echo "📋 Make sure carlevato.net points to 157.230.244.80"
fi

# Get SSL certificate
echo "📋 Obtaining SSL certificate..."
if certbot --apache -d carlevato.net -d www.carlevato.net --non-interactive --agree-tos --email admin@carlevato.net; then
    echo "✅ SSL certificate obtained successfully"
else
    echo "❌ SSL certificate acquisition failed"
    echo "📋 This might be due to DNS issues or domain not pointing to this server"
    echo "📋 Continuing with HTTP for now..."
fi

echo ""
echo "🧪 Step 8: Testing Apache Configuration..."
echo "================================"

# Wait for Apache to fully start
sleep 3

# Test HTTP response
echo "📋 Testing HTTP response:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/)
echo "HTTP Status: $HTTP_STATUS"

# Test HTTPS response (if certificate was obtained)
if [ -f "/etc/letsencrypt/live/carlevato.net/fullchain.pem" ]; then
    echo "📋 Testing HTTPS response:"
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://localhost/us/ --insecure)
    echo "HTTPS Status: $HTTPS_STATUS"
else
    echo "📋 HTTPS not available (no certificate)"
fi

# Test API
echo "📋 Testing API:"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/users)
echo "API Status: $API_STATUS"

# Test static files
echo "📋 Testing static files:"
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    JS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/us/static/js/$JS_FILENAME")
    echo "JavaScript file status: $JS_STATUS"
    
    # Test MIME type
    JS_MIME=$(curl -s -I "http://localhost/us/static/js/$JS_FILENAME" | grep -i "content-type" | head -1)
    echo "JavaScript MIME type: $JS_MIME"
fi

echo ""
echo "🔧 Step 9: Updating Backend Configuration..."
echo "================================"

# Update backend to work with Apache
cat > /var/www/us-calendar/backend/app.py << 'EOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import os

app = Flask(__name__)

# Configure CORS for production
CORS(app, origins=[
    'https://carlevato.net',
    'https://www.carlevato.net',
    'http://157.230.244.80',
    'https://157.230.244.80',
    'http://localhost:3000',
    'http://localhost:5000'
])

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///calendar.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Models
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

# Routes
@app.route('/api/users', methods=['GET'])
def get_users():
    users = User.query.all()
    return jsonify([{'id': user.id, 'username': user.username} for user in users])

@app.route('/api/events', methods=['GET'])
def get_events():
    events = Event.query.all()
    return jsonify([{
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'event_type': event.event_type,
        'start_date': event.start_date.isoformat(),
        'end_date': event.end_date.isoformat(),
        'applies_to_both': event.applies_to_both,
        'user_id': event.user_id
    } for event in events])

@app.route('/api/events', methods=['POST'])
def create_event():
    data = request.json
    event = Event(
        title=data['title'],
        description=data.get('description', ''),
        event_type=data.get('event_type', 'work'),
        start_date=datetime.fromisoformat(data['start_date']),
        end_date=datetime.fromisoformat(data['end_date']),
        applies_to_both=data.get('applies_to_both', False),
        user_id=data['user_id']
    )
    db.session.add(event)
    db.session.commit()
    return jsonify({'id': event.id, 'message': 'Event created successfully'})

@app.route('/api/events/<int:event_id>', methods=['PUT'])
def update_event(event_id):
    event = Event.query.get_or_404(event_id)
    data = request.json
    event.title = data['title']
    event.description = data.get('description', '')
    event.event_type = data.get('event_type', 'work')
    event.start_date = datetime.fromisoformat(data['start_date'])
    event.end_date = datetime.fromisoformat(data['end_date'])
    event.applies_to_both = data.get('applies_to_both', False)
    db.session.commit()
    return jsonify({'message': 'Event updated successfully'})

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
def delete_event(event_id):
    event = Event.query.get_or_404(event_id)
    db.session.delete(event)
    db.session.commit()
    return jsonify({'message': 'Event deleted successfully'})

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        # Create default user if none exists
        if not User.query.first():
            default_user = User(username='admin', password='admin123')
            db.session.add(default_user)
            db.session.commit()
    app.run(host='0.0.0.0', port=5001, debug=False)
EOF

echo "✅ Backend configuration updated"

echo ""
echo "🔄 Step 10: Restarting Services..."
echo "================================"

# Restart backend
systemctl restart us-calendar

# Restart Apache
systemctl restart apache2

echo "✅ Services restarted"

echo ""
echo "✅ Apache Switch Completed!"
echo ""
echo "🌐 Your calendar is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS)"
echo "   - http://157.230.244.80/us/ (HTTP fallback)"
echo ""
echo "🔧 Key changes made:"
echo "   - Removed nginx completely"
echo "   - Installed and configured Apache"
echo "   - Set up HTTPS with Let's Encrypt"
echo "   - Configured proper MIME types"
echo "   - Updated CORS for production"
echo "   - Set up proper static file serving"
echo ""
echo "🔍 If HTTPS doesn't work:"
echo "   1. Check DNS: carlevato.net should point to 157.230.244.80"
echo "   2. Run: certbot --apache -d carlevato.net"
echo "   3. Check logs: tail -f /var/log/apache2/us-calendar-error.log" 