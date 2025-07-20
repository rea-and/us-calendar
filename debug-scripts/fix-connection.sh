#!/bin/bash

# Fix connection refused errors

echo "🔧 Fixing Connection Refused Errors..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current Status..."
echo "================================"

# Check if services are running
echo "📊 Service status:"
systemctl is-active nginx
systemctl is-active us-calendar

# Check if ports are listening
echo ""
echo "📋 Listening ports:"
netstat -tlnp | grep -E ':(80|443|5001)'

echo ""
echo "🔧 Step 2: Fixing Firewall..."
echo "================================"

# Configure UFW firewall
if command -v ufw &> /dev/null; then
    echo "📊 Current UFW status:"
    ufw status
    
    echo ""
    echo "🔧 Configuring UFW firewall..."
    
    # Allow SSH (if not already allowed)
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow backend port (if needed externally)
    ufw allow 5001/tcp
    
    # Enable UFW if not enabled
    if ! ufw status | grep -q "Status: active"; then
        echo "📋 Enabling UFW firewall..."
        ufw --force enable
    fi
    
    echo ""
    echo "📊 Updated UFW status:"
    ufw status
else
    echo "⚠️  UFW not installed, checking iptables..."
    # Basic iptables rules
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 5001 -j ACCEPT
fi

echo ""
echo "🔧 Step 3: Fixing Nginx Configuration..."
echo "================================"

# Check current nginx config
echo "📋 Current nginx configuration:"
grep -n "listen" /etc/nginx/sites-available/us-calendar

# Ensure nginx is listening on all interfaces
echo ""
echo "🔧 Updating nginx to listen on all interfaces..."

# Create backup
cp /etc/nginx/sites-available/us-calendar /etc/nginx/sites-available/us-calendar.backup.$(date +%Y%m%d_%H%M%S)

# Update nginx config to ensure it listens on all interfaces
cat > /etc/nginx/sites-available/us-calendar << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name carlevato.net www.carlevato.net _;

    # API proxy
    location /api/ {
        proxy_pass http://localhost:5001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files for React app
    location /us/static/ {
        alias /var/www/us-calendar/frontend/build/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # React app routes
    location /us {
        alias /var/www/us-calendar/frontend/build;
        try_files $uri $uri/ /us/index.html;
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Root redirect to /us
    location = / {
        return 301 /us/;
    }

    # Default location
    location / {
        return 301 /us/;
    }
}
EOF

echo "✅ Nginx configuration updated"

echo ""
echo "🔍 Step 4: Testing Nginx Configuration..."
echo "================================"

# Test nginx config
if nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

echo ""
echo "🔄 Step 5: Restarting Services..."
echo "================================"

# Restart nginx
systemctl restart nginx
if systemctl is-active nginx; then
    echo "✅ Nginx restarted successfully"
else
    echo "❌ Nginx failed to restart"
    exit 1
fi

# Restart backend
systemctl restart us-calendar
if systemctl is-active us-calendar; then
    echo "✅ Backend restarted successfully"
else
    echo "❌ Backend failed to restart"
    exit 1
fi

echo ""
echo "🧪 Step 6: Testing Connectivity..."
echo "================================"

# Test local access
echo "📋 Testing localhost access..."
curl -s -o /dev/null -w "Localhost: %{http_code}\n" http://localhost/us/

# Test external IP access
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📋 Testing external IP access ($SERVER_IP)..."
curl -s -o /dev/null -w "External IP: %{http_code}\n" "http://$SERVER_IP/us/"

# Test domain access
echo "📋 Testing domain access..."
curl -s -o /dev/null -w "Domain: %{http_code}\n" http://carlevato.net/us/

echo ""
echo "🔍 Step 7: Checking Network Interfaces..."
echo "================================"

# Check network interfaces
echo "📋 Network interfaces:"
ip addr show | grep -E "inet.*scope global"

echo ""
echo "📋 Listening ports after fix:"
netstat -tlnp | grep -E ':(80|443|5001)'

echo ""
echo "🔧 Step 8: Additional Network Checks..."
echo "================================"

# Check if nginx is binding to all interfaces
echo "📋 Nginx process binding:"
ss -tlnp | grep nginx

# Check if there are any conflicting services
echo ""
echo "📋 Services using port 80:"
lsof -i :80 2>/dev/null || echo "No processes found on port 80"

echo ""
echo "✅ Connection Fix Completed!"
echo ""
echo "🌐 Test your calendar now:"
echo "   - Local: http://localhost/us"
echo "   - External IP: http://$SERVER_IP/us"
echo "   - Domain: http://carlevato.net/us"
echo ""
echo "📱 Test on mobile:"
echo "   - Try from mobile data (not WiFi)"
echo "   - Try from different WiFi network"
echo "   - Clear browser cache"
echo ""
echo "🔍 If still having issues:"
echo "   1. Check cloud provider firewall settings"
echo "   2. Try accessing via IP instead of domain"
echo "   3. Check if your ISP is blocking the connection"
echo "   4. Test from a different network/device" 