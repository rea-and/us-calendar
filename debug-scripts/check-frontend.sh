#!/bin/bash

# Check frontend build directory and static files

echo "🔍 Checking Frontend Build Directory..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "📁 Frontend Build Directory Structure..."
echo "================================"

# Check if build directory exists
if [ -d "/var/www/us-calendar/frontend/build" ]; then
    echo "✅ Build directory exists"
    echo "📋 Contents of build directory:"
    ls -la /var/www/us-calendar/frontend/build/
    
    echo ""
    echo "📁 Static directory:"
    if [ -d "/var/www/us-calendar/frontend/build/static" ]; then
        echo "✅ Static directory exists"
        echo "📋 Contents of static directory:"
        ls -la /var/www/us-calendar/frontend/build/static/
        
        echo ""
        echo "📁 CSS directory:"
        if [ -d "/var/www/us-calendar/frontend/build/static/css" ]; then
            echo "✅ CSS directory exists"
            echo "📋 CSS files:"
            ls -la /var/www/us-calendar/frontend/build/static/css/
        else
            echo "❌ CSS directory missing"
        fi
        
        echo ""
        echo "📁 JS directory:"
        if [ -d "/var/www/us-calendar/frontend/build/static/js" ]; then
            echo "✅ JS directory exists"
            echo "📋 JS files:"
            ls -la /var/www/us-calendar/frontend/build/static/js/
        else
            echo "❌ JS directory missing"
        fi
    else
        echo "❌ Static directory missing"
    fi
    
    echo ""
    echo "📄 Other files in build:"
    find /var/www/us-calendar/frontend/build -maxdepth 1 -type f | head -10
    
else
    echo "❌ Build directory missing"
fi

echo ""
echo "🔧 Checking if frontend needs to be rebuilt..."
echo "================================"

# Check if we need to rebuild
cd /var/www/us-calendar/frontend

echo "📋 Package.json exists:"
if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    echo "📋 Dependencies:"
    cat package.json | grep -A 10 '"dependencies"'
else
    echo "❌ package.json missing"
fi

echo ""
echo "📦 Node modules:"
if [ -d "node_modules" ]; then
    echo "✅ node_modules exists"
    echo "📋 Size: $(du -sh node_modules | cut -f1)"
else
    echo "❌ node_modules missing"
fi

echo ""
echo "🚀 Attempting to rebuild frontend..."
echo "================================"

# Try to rebuild
echo "📦 Installing dependencies..."
npm install

echo ""
echo "🏗️  Building frontend..."
npm run build

echo ""
echo "📋 New build contents:"
if [ -d "build" ]; then
    echo "✅ Build completed"
    echo "📁 Build directory contents:"
    ls -la build/
    
    echo ""
    echo "📁 Static directory contents:"
    if [ -d "build/static" ]; then
        ls -la build/static/
        
        echo ""
        echo "📁 CSS files:"
        if [ -d "build/static/css" ]; then
            ls -la build/static/css/
        fi
        
        echo ""
        echo "📁 JS files:"
        if [ -d "build/static/js" ]; then
            ls -la build/static/js/
        fi
    fi
else
    echo "❌ Build failed"
fi

echo ""
echo "🔍 Checking nginx configuration for static files..."
echo "================================"

# Check nginx configuration
echo "📋 Current nginx static file locations:"
grep -A 10 "location.*static" /etc/nginx/sites-available/us-calendar

echo ""
echo "🧪 Testing nginx configuration..."
nginx -t

echo ""
echo "🔄 Restarting nginx..."
systemctl restart nginx

echo ""
echo "✅ Frontend check completed!"
echo ""
echo "💡 If static files are still missing, try:"
echo "   1. Check the build output above"
echo "   2. Verify nginx configuration"
echo "   3. Check browser developer tools for specific file paths" 