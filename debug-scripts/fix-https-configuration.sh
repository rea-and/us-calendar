#!/bin/bash

# Fix HTTPS configuration for API access

echo "🔧 Fixing HTTPS configuration for API access..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current HTTPS Configuration..."
echo "================================"

# Check current HTTPS virtual host
echo "📋 Current HTTPS virtual host:"
cat /etc/apache2/sites-enabled/000-default-le-ssl.conf

echo ""
echo "📋 Checking SSL certificate:"
ls -la /etc/letsencrypt/live/carlevato.net/

echo ""
echo "🔍 Step 2: Creating HTTPS Virtual Host for Calendar..."
echo "================================"

# Create a proper HTTPS virtual host for the calendar
echo "📋 Creating HTTPS virtual host for calendar..."
cat > /etc/apache2/sites-available/us-calendar-ssl.conf << 'EOF'
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName carlevato.net
    ServerAlias www.carlevato.net
    DocumentRoot /var/www/us-calendar/frontend/build
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/carlevato.net/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/carlevato.net/privkey.pem
    
    # API proxy
    ProxyPreserveHost On
    ProxyPass /api/ http://localhost:5001/api/
    ProxyPassReverse /api/ http://localhost:5001/api/
    
    # Static files
    <Directory "/var/www/us-calendar/frontend/build">
        Require all granted
        Options -Indexes
        FallbackResource /index.html
    </Directory>
    
    # JavaScript files
    <FilesMatch "\.js$">
        Header set Content-Type "application/javascript"
    </FilesMatch>
    
    # CSS files
    <FilesMatch "\.css$">
        Header set Content-Type "text/css"
    </FilesMatch>
    
    # CORS headers for API
    <Location "/api/">
        Header always set Access-Control-Allow-Origin "*"
        Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
        
        # Handle preflight requests
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} OPTIONS
        RewriteRule ^(.*)$ $1 [R=200,L]
    </Location>
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/us-calendar-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/us-calendar-ssl-access.log combined
</VirtualHost>
</IfModule>
EOF

echo "📋 HTTPS virtual host created:"
cat /etc/apache2/sites-available/us-calendar-ssl.conf

echo ""
echo "🔍 Step 3: Enabling HTTPS Site..."
echo "================================"

# Disable the default HTTPS site and enable our calendar HTTPS site
echo "📋 Disabling default HTTPS site..."
a2dissite 000-default-le-ssl

echo "📋 Enabling calendar HTTPS site..."
a2ensite us-calendar-ssl

echo "📋 Enabled sites:"
ls -la /etc/apache2/sites-enabled/

echo ""
echo "🔍 Step 4: Testing Apache Configuration..."
echo "================================"

# Test Apache configuration
echo "📋 Testing Apache configuration..."
apache2ctl configtest

if [ $? -eq 0 ]; then
    echo "✅ Apache configuration is valid"
else
    echo "❌ Apache configuration has errors"
    echo "📋 Re-enabling default HTTPS site..."
    a2ensite 000-default-le-ssl
    a2dissite us-calendar-ssl
    exit 1
fi

echo ""
echo "🔍 Step 5: Restarting Apache..."
echo "================================"

# Restart Apache
echo "📋 Restarting Apache..."
systemctl restart apache2

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo "✅ Apache is running"
else
    echo "❌ Apache failed to start"
    echo "📋 Re-enabling default HTTPS site..."
    a2ensite 000-default-le-ssl
    a2dissite us-calendar-ssl
    systemctl restart apache2
    exit 1
fi

echo ""
echo "🔍 Step 6: Testing HTTPS Access..."
echo "================================"

# Test HTTPS access
echo "📋 Testing HTTPS calendar access:"
curl -I https://localhost/us/ 2>/dev/null | head -5

echo "📋 Testing HTTPS API access:"
curl -I https://localhost/api/events 2>/dev/null | head -5

echo "📋 Testing external HTTPS access:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo "📋 Testing external HTTPS API:"
curl -I https://carlevato.net/api/events 2>/dev/null | head -5

echo ""
echo "🔍 Step 7: Testing CORS Headers..."
echo "================================"

# Test CORS headers
echo "📋 Testing CORS headers on API:"
curl -H "Origin: https://carlevato.net" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS https://carlevato.net/api/events -v 2>&1 | grep -E "(Access-Control|HTTP)"

echo ""
echo "🔍 Step 8: Checking Logs..."
echo "================================"

# Check Apache logs
echo "📋 Apache error logs:"
tail -5 /var/log/apache2/error.log

echo "📋 Calendar HTTPS error logs:"
tail -5 /var/log/apache2/us-calendar-ssl-error.log

echo ""
echo "✅ HTTPS Configuration Fix Complete!"
echo ""
echo "🌐 Your calendar should now be fully working at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo "   - http://carlevato.net/us/ (HTTP domain access)"
echo "   - http://157.230.244.80/us/ (IP access)"
echo ""
echo "🔍 If HTTPS shows 200, your calendar is working!"
echo "📱 Test on your phone and computer to verify."
echo ""
echo "🔧 If issues persist:"
echo "   1. Check logs: tail -f /var/log/apache2/us-calendar-ssl-error.log"
echo "   2. Test HTTPS: curl -I https://carlevato.net/us/"
echo "   3. Test API: curl -I https://carlevato.net/api/events"
echo "   4. Re-enable default: a2ensite 000-default-le-ssl" 