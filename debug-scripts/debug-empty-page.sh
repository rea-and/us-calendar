#!/bin/bash

# Debug empty page issue

echo "🔧 Debugging empty page issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking Current File States..."
echo "================================"

# Check current file states
echo "📋 Checking App.js..."
cd /opt/us-calendar/frontend/src
echo "App.js content (first 20 lines):"
head -20 App.js

echo ""
echo "📋 Checking LandingPage.js..."
cd /opt/us-calendar/frontend/src/pages
echo "LandingPage.js content (first 20 lines):"
head -20 LandingPage.js

echo ""
echo "📋 Checking LandingPage.css..."
echo "LandingPage.css content (first 20 lines):"
head -20 LandingPage.css

echo ""
echo "🔍 Step 2: Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing users endpoint..."
curl -s https://carlevato.net/api/users

echo ""
echo "📋 Testing events endpoint..."
curl -s https://carlevato.net/api/events

echo ""
echo "🔍 Step 3: Checking Backend Status..."
echo "================================"

# Check backend status
echo "📋 Checking backend service status..."
systemctl status us-calendar-backend --no-pager -l

echo ""
echo "🔍 Step 4: Creating Minimal Test Version..."
echo "================================"

# Create minimal test version
echo "📋 Creating minimal test version..."
cd /opt/us-calendar/frontend/src

# Create minimal App.js
cat > App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configure axios base URL
axios.defaults.baseURL = 'https://carlevato.net/api';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadUsers = async () => {
      try {
        const response = await axios.get('/users');
        setUsers(response.data);
      } catch (error) {
        console.error('Error loading users:', error);
      } finally {
        setLoading(false);
      }
    };

    loadUsers();
  }, []);

  if (loading) {
    return (
      <div style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'white'
      }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px'
    }}>
      <div style={{
        maxWidth: '800px',
        width: '100%',
        textAlign: 'center'
      }}>
        <h1 style={{
          fontSize: '3.5rem',
          fontWeight: '700',
          color: 'white',
          marginBottom: '60px',
          textShadow: '0 2px 4px rgba(0, 0, 0, 0.3)'
        }}>
          Our Calendar
        </h1>
        
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '30px',
          marginBottom: '60px'
        }}>
          {users.map((user) => (
            <div 
              key={user.id} 
              style={{
                background: 'white',
                borderRadius: '20px',
                padding: '40px 30px',
                boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)',
                cursor: 'pointer',
                transition: 'all 0.3s ease'
              }}
            >
              <div style={{
                width: '80px',
                height: '80px',
                borderRadius: '50%',
                background: 'linear-gradient(135deg, #667eea, #764ba2)',
                color: 'white',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '2rem',
                fontWeight: '700',
                margin: '0 auto 20px',
                boxShadow: '0 4px 15px rgba(102, 126, 234, 0.4)'
              }}>
                {user.name.charAt(0).toUpperCase()}
              </div>
              <h2 style={{
                fontSize: '1.8rem',
                color: '#333',
                marginBottom: '12px',
                fontWeight: '600'
              }}>
                {user.name}
              </h2>
              <p style={{
                color: '#666',
                fontSize: '1rem',
                lineHeight: '1.5'
              }}>
                Click to continue as {user.name}
              </p>
            </div>
          ))}
        </div>
        
        <div style={{
          color: 'rgba(255, 255, 255, 0.8)',
          fontSize: '1rem',
          fontWeight: '300'
        }}>
          <p>Our shared calendar</p>
        </div>
      </div>
    </div>
  );
}

export default App;
EOF

echo "📋 Minimal test version created"

echo ""
echo "🔍 Step 5: Rebuilding Minimal Version..."
echo "================================"

# Rebuild the minimal version
echo "📋 Rebuilding minimal version..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 6: Deploying Minimal Version..."
echo "================================"

# Deploy the minimal version
echo "📋 Deploying minimal version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 7: Testing Minimal Version..."
echo "================================"

# Test the minimal version
echo "📋 Testing minimal version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Minimal Test Version Complete!"
echo ""
echo "🌐 Your minimal test version is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 This version:"
echo "   - Uses inline styles only (no CSS files)"
echo "   - No React Router (simplified routing)"
echo "   - Direct API calls"
echo "   - Minimal dependencies"
echo ""
echo "📱 If this works, we know the issue is with:"
echo "   - CSS file loading"
echo "   - React Router configuration"
echo "   - Component imports"
echo ""
echo "🔧 If this doesn't work, the issue is with:"
echo "   - API connectivity"
echo "   - React rendering"
echo "   - Build process"
echo ""
echo "📱 Check the page now and let me know if you see the user cards!" 