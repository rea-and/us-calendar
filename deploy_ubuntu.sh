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

# Install required packages
echo "📦 Installing required packages..."
apt install -y python3 python3-pip python3-venv nodejs npm nginx

# Create application directory
echo "📁 Creating application directory..."
mkdir -p /var/www/us-calendar
cd /var/www/us-calendar

# Copy application files (assuming they're in the current directory)
echo "📋 Copying application files..."
cp -r * /var/www/us-calendar/

# Set up Python environment
echo "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set up React frontend
echo "⚛️  Building React frontend..."
cd frontend
npm install
npm run build
cd ..

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

# Check service status
echo "📊 Checking service status..."
systemctl status us-calendar --no-pager
systemctl status nginx --no-pager

echo ""
echo "✅ Deployment completed!"
echo ""
echo "🌐 Your application is now available at:"
echo "   https://carlaveto.net/us"
echo ""
echo "📋 Useful commands:"
echo "   Check backend logs: journalctl -u us-calendar -f"
echo "   Check nginx logs: tail -f /var/log/nginx/access.log"
echo "   Restart backend: systemctl restart us-calendar"
echo "   Restart nginx: systemctl restart nginx"
echo ""
echo "🔧 To update the application:"
echo "   1. Copy new files to /var/www/us-calendar"
echo "   2. Run: cd /var/www/us-calendar/frontend && npm run build"
echo "   3. Run: systemctl restart us-calendar" 