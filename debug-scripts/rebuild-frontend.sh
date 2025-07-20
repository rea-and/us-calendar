#!/bin/bash

# Rebuild frontend with updated API configuration

echo "🏗️  Rebuilding Frontend with Updated Configuration..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📁 Checking current frontend build..."
echo "================================"

# Check current build timestamp
echo "📋 Current build timestamp:"
ls -la /var/www/us-calendar/frontend/build/index.html

echo ""
echo "🔧 Rebuilding frontend..."
echo "================================"

# Navigate to frontend directory
cd /var/www/us-calendar/frontend

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf build

# Install dependencies (if needed)
echo "📦 Installing dependencies..."
npm install

# Build the frontend
echo "🏗️  Building frontend..."
npm run build

# Check if build was successful
if [ ! -d "build" ]; then
    echo "❌ Build failed - build directory not created"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo "================================"

# Check new build timestamp
echo "📋 New build timestamp:"
ls -la build/index.html

# Check the API configuration in the new build
echo ""
echo "🔍 Verifying API configuration in new build..."
echo "📋 Checking if HTTPS was changed to HTTP:"
grep -o "https://carlaveto.net/api\|http://carlaveto.net/api" build/static/js/main.*.js || echo "No API URL found in JS (minified)"

echo ""
echo "🔐 Setting correct permissions..."
chown -R www-data:www-data build
chmod -R 755 build

echo ""
echo "🌐 Restarting nginx..."
systemctl restart nginx

echo ""
echo "🧪 Testing static file access..."
echo "================================"

# Test if static files are accessible
echo "📋 Testing CSS file:"
curl -I http://localhost/us/static/css/main.*.css 2>/dev/null | head -1

echo "📋 Testing JS file:"
curl -I http://localhost/us/static/js/main.*.js 2>/dev/null | head -1

echo ""
echo "✅ Frontend rebuild completed!"
echo ""
echo "🌐 Test your application at:"
echo "   http://carlevato.net/us"
echo ""
echo "💡 The app should now:"
echo "   - Load without the spinner getting stuck"
echo "   - Show the user selection page (Andrea/Angel)"
echo "   - Connect to the API via HTTP instead of HTTPS" 