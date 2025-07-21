#!/bin/bash

# Our Calendar Ubuntu Deployment Script
# Deploys to carlevato.net/us

echo "🚀 Deploying Our Calendar to Ubuntu Server..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

# Update system packages
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Remove conflicting npm package if it exists
echo "🧹 Removing conflicting npm package..."
apt remove -y npm 2>/dev/null || true

# Install required packages
echo "📦 Installing required packages..."
apt install -y python3 python3-pip python3-venv apache2 apache2-utils libapache2-mod-wsgi-py3 curl certbot python3-certbot-apache

# Install Node.js 18.x from NodeSource
echo "📦 Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verify installations
echo "✅ Verifying installations..."
python3 --version
node --version
npm --version
apache2 -v

# Get the current directory where the script is running from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /var/www/us-calendar

# Copy application files from the script directory
echo "📋 Copying application files from $SCRIPT_DIR..."
if [ -d "$SCRIPT_DIR" ]; then
    cp -r "$SCRIPT_DIR"/* /var/www/us-calendar/ 2>/dev/null || true
    cp -r "$SCRIPT_DIR"/.* /var/www/us-calendar/ 2>/dev/null || true
else
    echo "❌ Could not find source directory"
    exit 1
fi

# Change to application directory
cd /var/www/us-calendar

# Verify files were copied
echo "📋 Verifying files..."
if [ ! -f "/var/www/us-calendar/requirements.txt" ]; then
    echo "❌ requirements.txt not found. Please ensure you're running this script from the project directory."
    exit 1
fi

if [ ! -d "/var/www/us-calendar/frontend" ]; then
    echo "❌ frontend directory not found. Please ensure you're running this script from the project directory."
    exit 1
fi

# Set up Python environment
echo "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Set up React frontend
echo "⚛️  Building React frontend..."
cd frontend
npm install
npm run build
cd ..

# Verify React build was created
echo "📋 Verifying React build..."
if [ ! -d "/var/www/us-calendar/frontend/build" ]; then
    echo "❌ React build directory not found. Build may have failed."
    exit 1
fi

if [ ! -f "/var/www/us-calendar/frontend/build/index.html" ]; then
    echo "❌ React build index.html not found. Build may have failed."
    exit 1
fi

echo "✅ React build verified successfully"

# Create systemd service for Flask backend
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/us-calendar.service << EOF
[Unit]
Description=Our Calendar Flask Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/us-calendar/backend
Environment=PATH=/var/www/us-calendar/venv/bin
ExecStart=/var/www/us-calendar/venv/bin/python app.py
Environment=FLASK_ENV=production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
echo "🔐 Setting permissions..."
chown -R www-data:www-data /var/www/us-calendar
chmod -R 755 /var/www/us-calendar

# Enable required Apache modules
echo "🔧 Enabling Apache modules..."
a2enmod proxy
a2enmod proxy_http
a2enmod rewrite
a2enmod ssl
a2enmod headers

# Configure Apache
echo "🌐 Configuring Apache..."
cat > /etc/apache2/sites-available/us-calendar.conf << EOF
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
    ErrorLog \${APACHE_LOG_DIR}/us-calendar-error.log
    CustomLog \${APACHE_LOG_DIR}/us-calendar-access.log combined
</VirtualHost>
EOF

# Disable default site and enable our site
echo "🔗 Enabling Apache site..."
a2dissite 000-default.conf
a2ensite us-calendar.conf

# Test Apache configuration
echo "🧪 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration failed"
    exit 1
fi

# Start and enable services
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable us-calendar
systemctl start us-calendar
systemctl enable apache2
systemctl start apache2

# Set up SSL certificate
echo "🔒 Setting up SSL certificate..."
if command -v certbot &> /dev/null; then
    echo "📋 Checking DNS resolution for carlevato.net..."
    if nslookup carlevato.net >/dev/null 2>&1; then
        echo "✅ DNS resolution successful"
        echo "📋 Obtaining SSL certificate for carlevato.net..."
        certbot --apache -d carlevato.net -d www.carlevato.net --non-interactive --agree-tos --email admin@carlevato.net
        
        if [ $? -eq 0 ]; then
            echo "✅ SSL certificate obtained successfully"
            echo "🔄 Restarting Apache with SSL configuration..."
            systemctl restart apache2
        else
            echo "⚠️  SSL certificate setup failed. Site will run on HTTP only."
            echo "💡 Common issues:"
            echo "   - DNS not pointing to this server"
            echo "   - Port 80 not accessible from internet"
            echo "   - Domain not registered or expired"
            echo "💡 You can manually run: certbot --apache -d carlevato.net"
        fi
    else
        echo "❌ DNS resolution failed for carlevato.net"
        echo "💡 Please ensure:"
        echo "   1. Domain carlevato.net is registered"
        echo "   2. DNS A record points to this server's IP"
        echo "   3. DNS propagation has completed (can take up to 48 hours)"
        echo "💡 Site will run on HTTP only until DNS is configured"
    fi
else
    echo "⚠️  Certbot not available. Site will run on HTTP only."
    echo "💡 Install certbot manually: apt install certbot python3-certbot-apache"
fi

# Check service status
echo "📊 Checking service status..."
systemctl status us-calendar --no-pager
systemctl status apache2 --no-pager

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🌐 Your application is now available at:"
echo "   HTTPS: https://carlevato.net/us (recommended)"
echo "   HTTP:  http://carlevato.net/us (fallback)"
echo ""
echo "🔒 SSL Status:"
if [ -f "/etc/letsencrypt/live/carlevato.net/fullchain.pem" ]; then
    echo "   ✅ SSL certificate installed and active"
else
    echo "   ⚠️  SSL certificate not installed - site runs on HTTP"
    echo "   💡 To install SSL manually: certbot --apache -d carlevato.net"
fi
echo ""
echo "📋 Useful commands:"
echo "   Check backend logs: journalctl -u us-calendar -f"
echo "   Check Apache logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   Restart backend: systemctl restart us-calendar"
echo "   Restart Apache: systemctl restart apache2"
echo "   Renew SSL: certbot renew"
echo ""
echo "🔧 To update the application:"
echo "   1. Copy new files to /var/www/us-calendar"
echo "   2. Run: cd /var/www/us-calendar/frontend && npm run build"
echo "   3. Run: systemctl restart us-calendar"
echo ""
echo "🔄 If you need to switch from nginx to Apache:"
echo "   cd debug-scripts && sudo ./switch-to-apache-https.sh" 