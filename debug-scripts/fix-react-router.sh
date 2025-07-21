#!/bin/bash

# Fix React Router issue

echo "🔧 Fixing React Router issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Adding React Router Debug Logging..."
echo "================================"

# Add React Router debug logging to App.js
echo "📋 Adding React Router debug logging to App.js..."
cd /opt/us-calendar/frontend/src

# Create a backup
cp App.js App.js.backup

# Add React Router debug logging
cat > App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import LandingPage from './pages/LandingPage';
import CalendarPage from './pages/CalendarPage';
import './App.css';

// Configure axios base URL
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://carlevato.net/api' 
  : 'http://localhost:5001/api';

axios.defaults.baseURL = API_BASE_URL;

// Debug component to track routing
function RouteDebugger() {
  const location = useLocation();
  console.log('🔍 Current route location:', location.pathname);
  return null;
}

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
  
  // Simplified routing without React Router for debugging
  console.log('🔍 Using simplified routing for debugging');
  
  // Always render LandingPage for debugging
  if (!currentUser) {
    console.log('🔍 Rendering LandingPage directly (no currentUser)');
    return (
      <div className="App">
        <RouteDebugger />
        <LandingPage 
          users={users} 
          onUserSelect={handleUserSelect} 
        />
      </div>
    );
  } else {
    console.log('🔍 Rendering CalendarPage directly (currentUser exists)');
    return (
      <div className="App">
        <RouteDebugger />
        <CalendarPage 
          currentUser={currentUser} 
          onLogout={handleLogout}
        />
      </div>
    );
  }

  // Original React Router code (commented out for debugging)
  /*
  return (
    <Router>
      <div className="App">
        <RouteDebugger />
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
  */
}

export default App;
EOF

echo "📋 React Router debug logging added to App.js"

echo ""
echo "🔍 Step 2: Rebuilding Frontend with Router Debug..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend with router debug..."
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
echo "🔍 Step 3: Deploying Router Debug Version..."
echo "================================"

# Deploy the router debug version
echo "📋 Deploying router debug version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 4: Testing Router Debug Version..."
echo "================================"

# Test the router debug version
echo "📋 Testing router debug version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ React Router Debug Fix Complete!"
echo ""
echo "🌐 Your calendar router debug version is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Debug Instructions:"
echo "   1. Open Chrome DevTools (F12)"
echo "   2. Go to Console tab"
echo "   3. Refresh the page"
echo "   4. Look for debug messages about routing"
echo "   5. Check if LandingPage renders directly"
echo ""
echo "🔧 Expected Debug Output:"
echo "   🔍 Using simplified routing for debugging"
echo "   🔍 Rendering LandingPage directly (no currentUser)"
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
echo "📱 If you see the LandingPage debug messages and user cards, the issue was React Router!"
echo "🔧 If you still don't see LandingPage messages, there's a component rendering issue" 