#!/bin/bash

# Fix landing page import and rendering issue

echo "🔧 Fixing landing page import and rendering issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking LandingPage Import Path..."
echo "================================"

# Check if LandingPage.js exists
echo "📋 Checking LandingPage.js file..."
cd /opt/us-calendar/frontend/src/pages
if [ -f "LandingPage.js" ]; then
    echo "✅ LandingPage.js exists"
    ls -la LandingPage.js
else
    echo "❌ LandingPage.js not found!"
    exit 1
fi

echo ""
echo "🔍 Step 2: Adding Fallback Rendering to App.js..."
echo "================================"

# Add fallback rendering to App.js
echo "📋 Adding fallback rendering to App.js..."
cd /opt/us-calendar/frontend/src

# Create a backup
cp App.js App.js.backup

# Add fallback rendering
cat > App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import LandingPage from './pages/LandingPage';
import CalendarPage from './pages/CalendarPage';
import './App.css';

// Configure axios base URL
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://carlevato.net/api' 
  : 'http://localhost:5001/api';

axios.defaults.baseURL = API_BASE_URL;

function App() {
  const [currentUser, setCurrentUser] = useState(null);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load users on app start
    const loadUsers = async () => {
      console.log('🔍 Starting to load users...');
      try {
        console.log('🔍 Making API request to:', axios.defaults.baseURL + '/users');
        const response = await axios.get('/users');
        console.log('🔍 API response received:', response.data);
        setUsers(response.data);
        console.log('🔍 Users state set to:', response.data);
      } catch (error) {
        console.error('❌ Error loading users:', error);
      } finally {
        console.log('🔍 Setting loading to false');
        setLoading(false);
      }
    };

    loadUsers();
  }, []);

  const handleUserSelect = (user) => {
    console.log('🔍 User selected:', user);
    setCurrentUser(user);
  };

  const handleLogout = () => {
    console.log('🔍 User logging out');
    setCurrentUser(null);
  };

  console.log('🔍 Current state - loading:', loading, 'users:', users, 'currentUser:', currentUser);

  if (loading) {
    console.log('🔍 Rendering loading screen');
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading...</p>
        <p style={{fontSize: '12px', marginTop: '10px'}}>Debug: Loading users...</p>
      </div>
    );
  }

  console.log('🔍 Rendering main app');
  
  // Debug: Check if LandingPage component is available
  console.log('🔍 LandingPage component:', typeof LandingPage);
  console.log('🔍 CalendarPage component:', typeof CalendarPage);
  
  // Fallback rendering if LandingPage fails to import
  if (typeof LandingPage === 'undefined') {
    console.log('🔍 LandingPage component is undefined, using fallback');
    return (
      <div className="App">
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
            textAlign: 'center',
            background: 'rgba(255, 255, 255, 0.1)',
            padding: '20px',
            borderRadius: '10px',
            border: '2px solid red'
          }}>
            <div style={{border: '2px solid green'}}>
              <h1 style={{
                fontSize: '3.5rem',
                fontWeight: '700',
                color: 'white',
                marginBottom: '16px',
                textShadow: '0 2px 4px rgba(0, 0, 0, 0.3)'
              }}>Our Calendar</h1>
              <p style={{color: 'white', fontSize: '14px'}}>Debug: LandingPage component failed to import</p>
            </div>
            
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
              gap: '30px',
              marginBottom: '60px',
              border: '2px solid yellow'
            }}>
              {users && users.length > 0 ? (
                users.map((user, index) => {
                  console.log(`🔍 Fallback rendering user ${index}:`, user);
                  return (
                    <div 
                      key={user.id} 
                      style={{
                        background: 'white',
                        borderRadius: '20px',
                        padding: '40px 30px',
                        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)',
                        cursor: 'pointer',
                        border: '2px solid orange'
                      }}
                      onClick={() => handleUserSelect(user)}
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
                      }}>{user.name}</h2>
                      <p style={{
                        color: '#666',
                        fontSize: '1rem',
                        lineHeight: '1.5'
                      }}>Click to continue as {user.name}</p>
                      <p style={{fontSize: '12px', color: '#999'}}>Debug: User ID {user.id}</p>
                    </div>
                  );
                })
              ) : (
                <p style={{color: 'white', fontSize: '18px'}}>Debug: No users available</p>
              )}
            </div>
            
            <div style={{border: '2px solid purple'}}>
              <p style={{
                color: 'rgba(255, 255, 255, 0.8)',
                fontSize: '1rem',
                fontWeight: '300'
              }}>Our shared calendar</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <Router>
      <div className="App">
        <Routes>
          <Route 
            path="/" 
            element={
              currentUser ? (
                <Navigate to="/calendar" replace />
              ) : (
                <LandingPage 
                  users={users} 
                  onUserSelect={handleUserSelect} 
                />
              )
            } 
          />
          <Route 
            path="/calendar" 
            element={
              currentUser ? (
                <CalendarPage 
                  currentUser={currentUser} 
                  onLogout={handleLogout}
                />
              ) : (
                <Navigate to="/" replace />
              )
            } 
          />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
EOF

echo "📋 Fallback rendering added to App.js"

echo ""
echo "🔍 Step 3: Rebuilding Frontend with Fallback..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend with fallback rendering..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    cp App.js.backup App.js
    exit 1
fi

echo ""
echo "🔍 Step 4: Deploying Fallback Version..."
echo "================================"

# Deploy the fallback version
echo "📋 Deploying fallback version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 5: Testing Fallback Version..."
echo "================================"

# Test the fallback version
echo "📋 Testing fallback version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Landing Page Import Fix Complete!"
echo ""
echo "🌐 Your calendar fallback version is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Debug Instructions:"
echo "   1. Open Chrome DevTools (F12)"
echo "   2. Go to Console tab"
echo "   3. Refresh the page"
echo "   4. Look for debug messages about component imports"
echo "   5. Check if fallback rendering is used"
echo ""
echo "🔧 Expected Debug Output:"
echo "   🔍 LandingPage component: function"
echo "   🔍 CalendarPage component: function"
echo "   OR"
echo "   🔍 LandingPage component is undefined, using fallback"
echo "   🔍 Fallback rendering user 0: {id: 1, name: 'Angel', ...}"
echo "   🔍 Fallback rendering user 1: {id: 2, name: 'Andrea', ...}"
echo ""
echo "🎨 Visual Debug Features:"
echo "   - Red border around main container"
echo "   - Green border around header"
echo "   - Yellow border around user selection"
echo "   - Orange border around each user card"
echo "   - Purple border around footer"
echo "   - Debug text showing component status"
echo ""
echo "📱 If you see the fallback rendering with user cards, the issue was component import!"
echo "🔧 If you still see nothing, there's a deeper React rendering issue" 