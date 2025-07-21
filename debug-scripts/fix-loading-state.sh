#!/bin/bash

# Fix loading state issue

echo "🔧 Fixing loading state issue..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Adding Debug Logging to Frontend..."
echo "================================"

# Add debug logging to App.js
echo "📋 Adding debug logging to App.js..."
cd /opt/us-calendar/frontend/src

# Create a backup
cp App.js App.js.backup

# Add debug logging
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

echo "📋 Debug logging added to App.js"

echo ""
echo "🔍 Step 2: Rebuilding Frontend with Debug..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend with debug logging..."
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
echo "🔍 Step 3: Deploying Debug Version..."
echo "================================"

# Deploy the debug version
echo "📋 Deploying debug version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 4: Testing Debug Version..."
echo "================================"

# Test the debug version
echo "📋 Testing debug version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Loading State Debug Fix Complete!"
echo ""
echo "🌐 Your calendar debug version is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Debug Instructions:"
echo "   1. Open Chrome DevTools (F12)"
echo "   2. Go to Console tab"
echo "   3. Refresh the page"
echo "   4. Look for debug messages starting with 🔍"
echo "   5. Check if loading state changes from true to false"
echo "   6. Check if users data is received"
echo ""
echo "🔧 Expected Debug Output:"
echo "   🔍 Starting to load users..."
echo "   🔍 Making API request to: https://carlevato.net/api/users"
echo "   🔍 API response received: [array of users]"
echo "   🔍 Users state set to: [array of users]"
echo "   🔍 Setting loading to false"
echo "   🔍 Current state - loading: false, users: [array], currentUser: null"
echo "   🔍 Rendering main app"
echo ""
echo "📱 If you see the debug messages, the issue will be clear!"
echo "🔧 If loading stays true, there's an API issue"
echo "🔧 If users is empty, there's a data issue"
echo "🔧 If rendering fails, there's a component issue" 