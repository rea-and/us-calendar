#!/bin/bash

# Fix React Router error

echo "🔧 Fixing React Router error..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Removing RouteDebugger Component..."
echo "================================"

# Remove RouteDebugger from App.js
echo "📋 Removing RouteDebugger from App.js..."
cd /opt/us-calendar/frontend/src

# Create a backup
cp App.js App.js.backup

# Remove RouteDebugger
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
  
  // Simplified routing without React Router for debugging
  console.log('🔍 Using simplified routing for debugging');
  
  // Always render LandingPage for debugging
  if (!currentUser) {
    console.log('🔍 Rendering LandingPage directly (no currentUser)');
    return (
      <div className="App">
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
        <CalendarPage 
          currentUser={currentUser} 
          onLogout={handleLogout}
        />
      </div>
    );
  }
}

export default App;
EOF

echo "📋 RouteDebugger removed from App.js"

echo ""
echo "🔍 Step 2: Rebuilding Frontend..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend..."
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
echo "🔍 Step 3: Deploying Fixed Version..."
echo "================================"

# Deploy the fixed version
echo "📋 Deploying fixed version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 4: Testing Fixed Version..."
echo "================================"

# Test the fixed version
echo "📋 Testing fixed version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ React Router Error Fix Complete!"
echo ""
echo "🌐 Your calendar should now work at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Expected Result:"
echo "   - No more React Router errors"
echo "   - LandingPage should render with user cards"
echo "   - You should see Angel and Andrea user cards"
echo "   - Colored borders and debug text should be visible"
echo ""
echo "🎉 The landing page should now display the user cards!"
echo "📱 Try refreshing the page and you should see the user selection interface." 