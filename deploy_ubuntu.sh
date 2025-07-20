#!/bin/bash

# Our Calendar Ubuntu Deployment Script
# Deploys to carlaveto.net/us

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
apt install -y python3 python3-pip python3-venv nginx curl certbot python3-certbot-nginx

# Install Node.js 18.x from NodeSource
echo "📦 Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Verify installations
echo "✅ Verifying installations..."
python3 --version
node --version
npm --version
nginx -v

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

# Create nginx directories if they don't exist
echo "📁 Creating nginx directories..."
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/us-calendar << EOF
server {
    listen 80;
    server_name carlaveto.net;

    # Serve React frontend at /us
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files \$uri \$uri/ /us/index.html;
        
        # Add headers for SPA routing
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Handle static assets for React build
    location ~* ^/us/.*\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        alias /var/www/us-calendar/frontend/build;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API routes
    location /api {
        proxy_pass http://localhost:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:5001/api/health;
        proxy_set_header Host \$host;
    }

    # Redirect root to /us
    location = / {
        return 301 /us;
    }
}
EOF

# Enable the site
echo "🔗 Enabling nginx site..."
ln -sf /etc/nginx/sites-available/us-calendar /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration failed"
    exit 1
fi

# Start and enable services
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable us-calendar
systemctl start us-calendar
systemctl restart nginx

# Set up SSL certificate
echo "🔒 Setting up SSL certificate..."
if command -v certbot &> /dev/null; then
    echo "📋 Obtaining SSL certificate for carlaveto.net..."
    certbot --nginx -d carlaveto.net --non-interactive --agree-tos --email admin@carlaveto.net
    
    if [ $? -eq 0 ]; then
        echo "✅ SSL certificate obtained successfully"
        echo "🔄 Restarting nginx with SSL configuration..."
        systemctl restart nginx
    else
        echo "⚠️  SSL certificate setup failed. Site will run on HTTP only."
        echo "💡 You can manually run: certbot --nginx -d carlaveto.net"
    fi
else
    echo "⚠️  Certbot not available. Site will run on HTTP only."
    echo "💡 Install certbot manually: apt install certbot python3-certbot-nginx"
fi

# Check service status
echo "📊 Checking service status..."
systemctl status us-calendar --no-pager
systemctl status nginx --no-pager

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🌐 Your application is now available at:"
echo "   HTTPS: https://carlaveto.net/us (recommended)"
echo "   HTTP:  http://carlaveto.net/us (fallback)"
echo ""
echo "🔒 SSL Status:"
if [ -f "/etc/letsencrypt/live/carlaveto.net/fullchain.pem" ]; then
    echo "   ✅ SSL certificate installed and active"
else
    echo "   ⚠️  SSL certificate not installed - site runs on HTTP"
    echo "   💡 To install SSL manually: certbot --nginx -d carlaveto.net"
fi
echo ""
echo "📋 Useful commands:"
echo "   Check backend logs: journalctl -u us-calendar -f"
echo "   Check nginx logs: tail -f /var/log/nginx/access.log"
echo "   Restart backend: systemctl restart us-calendar"
echo "   Restart nginx: systemctl restart nginx"
echo "   Renew SSL: certbot renew"
echo ""
echo "🔧 To update the application:"
echo "   1. Copy new files to /var/www/us-calendar"
echo "   2. Run: cd /var/www/us-calendar/frontend && npm run build"
echo "   3. Run: systemctl restart us-calendar" 