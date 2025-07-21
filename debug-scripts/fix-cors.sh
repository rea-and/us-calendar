#!/bin/bash

# Fix CORS configuration

echo "🔧 Fixing CORS Configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current CORS Configuration..."
echo "================================"

# Check current CORS settings in the Flask app
echo "📋 Current CORS configuration in app.py:"
grep -n -A 5 -B 5 "CORS\|cors" /var/www/us-calendar/backend/app.py

echo ""
echo "🔧 Step 2: Updating CORS Configuration..."
echo "================================"

# Create backup
cp /var/www/us-calendar/backend/app.py /var/www/us-calendar/backend/app.py.backup.$(date +%Y%m%d_%H%M%S)

# Update the CORS configuration
echo "📋 Updating CORS to allow production domain..."

# Check if CORS is already configured
if grep -q "CORS" /var/www/us-calendar/backend/app.py; then
    echo "✅ CORS is already configured, updating origins..."
    
    # Update CORS origins to include production domain
    sed -i 's/origins=\["http:\/\/localhost:3000"\]/origins=["http:\/\/localhost:3000", "http:\/\/carlevato.net", "https:\/\/carlevato.net", "http:\/\/157.230.244.80"]/g' /var/www/us-calendar/backend/app.py
    
    # Also update if it's a single string
    sed -i 's/origins=\["http:\/\/localhost:3000"\]/origins=["http:\/\/localhost:3000", "http:\/\/carlevato.net", "https:\/\/carlevato.net", "http:\/\/157.230.244.80"]/g' /var/www/us-calendar/backend/app.py
else
    echo "❌ CORS not found, adding CORS configuration..."
    
    # Add CORS import if not present
    if ! grep -q "from flask_cors import CORS" /var/www/us-calendar/backend/app.py; then
        sed -i '1i from flask_cors import CORS' /var/www/us-calendar/backend/app.py
    fi
    
    # Add CORS configuration after app creation
    sed -i '/app = Flask(__name__)/a CORS(app, origins=["http://localhost:3000", "http://carlevato.net", "https://carlevato.net", "http://157.230.244.80"])' /var/www/us-calendar/backend/app.py
fi

echo "✅ CORS configuration updated"

echo ""
echo "🔍 Step 3: Checking Updated Configuration..."
echo "================================"

# Check the updated configuration
echo "📋 Updated CORS configuration:"
grep -n -A 5 -B 5 "CORS\|cors" /var/www/us-calendar/backend/app.py

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

# Test CORS headers
echo "📋 Testing CORS headers from localhost..."
curl -s -I http://localhost/api/users | grep -i "access-control"

echo "📋 Testing CORS headers from domain..."
curl -s -I http://carlevato.net/api/users | grep -i "access-control"

echo ""
echo "🔍 Step 6: Testing API Access..."
echo "================================"

# Test API access
echo "📋 Testing API from localhost..."
curl -s http://localhost/api/users | head -3

echo "📋 Testing API from domain..."
curl -s http://carlevato.net/api/users | head -3

echo ""
echo "🔍 Step 7: Testing with Browser Headers..."
echo "================================"

# Test with browser-like headers
echo "📋 Testing with browser headers..."
curl -s -H "Origin: http://carlevato.net" \
     -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
     -I http://localhost/api/users | grep -i "access-control"

echo ""
echo "✅ CORS Fix Completed!"
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