#!/bin/bash

# Fix landing page display issue

echo "🔧 Fixing landing page display issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Adding Debug Logging to LandingPage Component..."
echo "================================"

# Add debug logging to LandingPage.js
echo "📋 Adding debug logging to LandingPage.js..."
cd /opt/us-calendar/frontend/src/pages

# Create a backup
cp LandingPage.js LandingPage.js.backup

# Add debug logging
cat > LandingPage.js << 'EOF'
import React from 'react';
import './LandingPage.css';

const LandingPage = ({ users, onUserSelect }) => {
  console.log('🔍 LandingPage rendering with users:', users);
  console.log('🔍 Users length:', users ? users.length : 'undefined');
  console.log('🔍 Users type:', typeof users);
  console.log('🔍 Users is array:', Array.isArray(users));

  const handleUserClick = (user) => {
    console.log('🔍 User clicked:', user);
    onUserSelect(user);
  };

  // Debug: Check if users exist and have content
  if (!users) {
    console.log('🔍 Users is null/undefined');
    return (
      <div className="landing-page">
        <div className="landing-container">
          <div className="landing-header">
            <h1>Our Calendar</h1>
          </div>
          <div className="user-selection">
            <p style={{color: 'white', fontSize: '18px'}}>Debug: Users is null/undefined</p>
          </div>
        </div>
      </div>
    );
  }

  if (!Array.isArray(users)) {
    console.log('🔍 Users is not an array:', users);
    return (
      <div className="landing-page">
        <div className="landing-container">
          <div className="landing-header">
            <h1>Our Calendar</h1>
          </div>
          <div className="user-selection">
            <p style={{color: 'white', fontSize: '18px'}}>Debug: Users is not an array - {typeof users}</p>
          </div>
        </div>
      </div>
    );
  }

  if (users.length === 0) {
    console.log('🔍 Users array is empty');
    return (
      <div className="landing-page">
        <div className="landing-container">
          <div className="landing-header">
            <h1>Our Calendar</h1>
          </div>
          <div className="user-selection">
            <p style={{color: 'white', fontSize: '18px'}}>Debug: Users array is empty</p>
          </div>
        </div>
      </div>
    );
  }

  console.log('🔍 Rendering user cards for', users.length, 'users');
  users.forEach((user, index) => {
    console.log(`🔍 User ${index}:`, user);
  });

  return (
    <div className="landing-page" style={{border: '2px solid red'}}>
      <div className="landing-container" style={{border: '2px solid blue'}}>
        <div className="landing-header" style={{border: '2px solid green'}}>
          <h1>Our Calendar</h1>
          <p style={{color: 'white', fontSize: '14px'}}>Debug: Found {users.length} users</p>
        </div>
        
        <div className="user-selection" style={{border: '2px solid yellow'}}>
          {users.map((user, index) => {
            console.log(`🔍 Rendering user card ${index}:`, user);
            return (
              <div 
                key={user.id} 
                className="user-card"
                onClick={() => handleUserClick(user)}
                style={{border: '2px solid orange'}}
              >
                <div className="user-avatar">
                  {user.name.charAt(0).toUpperCase()}
                </div>
                <h2>{user.name}</h2>
                <p>Click to continue as {user.name}</p>
                <p style={{fontSize: '12px', color: '#999'}}>Debug: User ID {user.id}</p>
              </div>
            );
          })}
        </div>
        
        <div className="landing-footer" style={{border: '2px solid purple'}}>
          <p>Our shared calendar</p>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;
EOF

echo "📋 Debug logging added to LandingPage.js"

echo ""
echo "🔍 Step 2: Adding Debug Styles to CSS..."
echo "================================"

# Add debug styles to LandingPage.css
echo "📋 Adding debug styles to LandingPage.css..."
cd /opt/us-calendar/frontend/src/pages

# Create a backup
cp LandingPage.css LandingPage.css.backup

# Add debug styles at the end
cat >> LandingPage.css << 'EOF'

/* Debug styles - remove after fixing */
.landing-page {
  min-height: 100vh !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  padding: 20px !important;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
}

.landing-container {
  max-width: 800px !important;
  width: 100% !important;
  text-align: center !important;
  background: rgba(255, 255, 255, 0.1) !important;
  padding: 20px !important;
  border-radius: 10px !important;
}

.user-selection {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
  gap: 30px !important;
  margin-bottom: 60px !important;
  min-height: 200px !important;
}

.user-card {
  background: white !important;
  border-radius: 20px !important;
  padding: 40px 30px !important;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2) !important;
  cursor: pointer !important;
  transition: all 0.3s ease !important;
  position: relative !important;
  overflow: hidden !important;
  min-height: 150px !important;
}

.user-avatar {
  width: 80px !important;
  height: 80px !important;
  border-radius: 50% !important;
  background: linear-gradient(135deg, #667eea, #764ba2) !important;
  color: white !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  font-size: 2rem !important;
  font-weight: 700 !important;
  margin: 0 auto 20px !important;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4) !important;
}

.user-card h2 {
  font-size: 1.8rem !important;
  color: #333 !important;
  margin-bottom: 12px !important;
  font-weight: 600 !important;
}

.user-card p {
  color: #666 !important;
  font-size: 1rem !important;
  line-height: 1.5 !important;
}

.landing-header h1 {
  font-size: 3.5rem !important;
  font-weight: 700 !important;
  color: white !important;
  margin-bottom: 16px !important;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3) !important;
}

.landing-footer {
  color: rgba(255, 255, 255, 0.8) !important;
  font-size: 1rem !important;
  font-weight: 300 !important;
}
EOF

echo "📋 Debug styles added to LandingPage.css"

echo ""
echo "🔍 Step 3: Rebuilding Frontend with Debug..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend with debug logging..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    cp pages/LandingPage.js.backup pages/LandingPage.js
    cp pages/LandingPage.css.backup pages/LandingPage.css
    exit 1
fi

echo ""
echo "🔍 Step 4: Deploying Debug Version..."
echo "================================"

# Deploy the debug version
echo "📋 Deploying debug version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 5: Testing Debug Version..."
echo "================================"

# Test the debug version
echo "📋 Testing debug version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Landing Page Display Debug Fix Complete!"
echo ""
echo "🌐 Your calendar debug version is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Debug Instructions:"
echo "   1. Open Chrome DevTools (F12)"
echo "   2. Go to Console tab"
echo "   3. Refresh the page"
echo "   4. Look for debug messages starting with 🔍"
echo "   5. Check for colored borders around elements"
echo "   6. Look for debug text showing user count"
echo ""
echo "🔧 Expected Debug Output:"
echo "   🔍 LandingPage rendering with users: [array]"
echo "   🔍 Users length: 2"
echo "   🔍 Users type: object"
echo "   🔍 Users is array: true"
echo "   🔍 Rendering user cards for 2 users"
echo "   🔍 User 0: {id: 1, name: 'Angel', ...}"
echo "   🔍 User 1: {id: 2, name: 'Andrea', ...}"
echo "   🔍 Rendering user card 0: {id: 1, name: 'Angel', ...}"
echo "   🔍 Rendering user card 1: {id: 2, name: 'Andrea', ...}"
echo ""
echo "🎨 Visual Debug Features:"
echo "   - Red border around landing page"
echo "   - Blue border around container"
echo "   - Green border around header"
echo "   - Yellow border around user selection"
echo "   - Orange border around each user card"
echo "   - Purple border around footer"
echo "   - Debug text showing user count"
echo "   - Debug text in each user card"
echo ""
echo "📱 If you see the colored borders and debug text, the components are rendering!"
echo "🔧 If you don't see borders, there's a CSS issue"
echo "🔧 If you see borders but no users, there's a data issue"
echo "🔧 If you see users in console but not visually, there's a styling issue" 