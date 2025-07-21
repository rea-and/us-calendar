#!/bin/bash

echo "🎨 Deploying favicon update..."

# 1. Pull latest changes
echo "📥 Pulling latest changes..."
cd /opt/us-calendar
git pull origin main

# 2. Check if favicon was updated
echo "🔍 Checking favicon changes..."
if grep -q "👩🏻" frontend/src/pages/CalendarPage.js; then
    echo "✅ New favicon found in CalendarPage.js"
else
    echo "❌ New favicon not found in CalendarPage.js"
    exit 1
fi

# 3. Build frontend
echo "🔨 Building frontend..."
cd frontend
npm run build

# 4. Deploy to web server
echo "📋 Deploying to web server..."
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# 5. Clear browser cache (optional)
echo "🧹 Clearing browser cache..."
sudo systemctl reload apache2

# 6. Test the website
echo "🧪 Testing website..."
sleep 3
curl -s http://localhost/ | grep -o "👩🏻" | wc -l | xargs -I {} echo "Found {} instances of new favicon in HTML"

echo ""
echo "✅ Favicon update deployed!"
echo "🎨 Angel's favicon is now 👩🏻 (woman with light skin tone)"
echo "🌐 Check your website to see the updated favicon"
echo "💡 You may need to refresh your browser or clear cache to see changes" 