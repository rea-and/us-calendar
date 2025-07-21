#!/bin/bash

# Fix HTTPS redirect rule in default Apache site

echo "🔧 Fixing HTTPS redirect rule in default Apache site..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Default Site Configuration..."
echo "================================"

# Check the current default site configuration
echo "📋 Current default site configuration:"
cat /etc/apache2/sites-enabled/000-default.conf

echo ""
echo "🔍 Step 2: Backing Up and Fixing Default Site..."
echo "================================"

# Backup the original configuration
echo "📋 Backing up original default site configuration..."
cp /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.backup

# Create a new configuration without the redirect rule
echo "📋 Creating new default site configuration without redirect..."
cat > /etc/apache2/sites-enabled/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName carlevato.net
    ServerAlias www.carlevato.net
    
    # Disable this virtual host - we have our own calendar site
    DocumentRoot /var/www/html
    
    # Disable all access to this site
    <Directory "/var/www/html">
        Require all denied
    </Directory>
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/default-error.log
    CustomLog ${APACHE_LOG_DIR}/default-access.log combined
</VirtualHost>
EOF

echo "📋 New default site configuration:"
cat /etc/apache2/sites-enabled/000-default.conf

echo ""
echo "🔍 Step 3: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
echo "📋 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Restoring backup..."
    cp /etc/apache2/sites-enabled/000-default.conf.backup /etc/apache2/sites-enabled/000-default.conf
    exit 1
fi

echo ""
echo "🔍 Step 4: Restarting Apache..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    echo "📋 Restoring backup..."
    cp /etc/apache2/sites-enabled/000-default.conf.backup /etc/apache2/sites-enabled/000-default.conf
    systemctl restart apache2
    exit 1
fi

echo ""
echo "🔍 Step 5: Testing Access..."
echo "================================"

# Test HTTP access
echo "📋 Testing HTTP access:"
curl -I http://localhost/us/ 2>/dev/null | head -5

# Test API access
echo "📋 Testing API access:"
curl -I http://localhost/api/events 2>/dev/null | head -5

# Test external access
echo "📋 Testing external access:"
curl -I http://157.230.244.80/us/ 2>/dev/null | head -5

echo ""
echo "✅ HTTPS Redirect Fix Complete!"
echo ""
echo "🌐 Your calendar should now be available at:"
echo "   - http://carlevato.net/us/ (domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If HTTP shows 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-error.log"
echo "   2. Test locally: curl -I http://localhost/us/"
echo "   3. Restore backup: cp /etc/apache2/sites-enabled/000-default.conf.backup /etc/apache2/sites-enabled/000-default.conf" 