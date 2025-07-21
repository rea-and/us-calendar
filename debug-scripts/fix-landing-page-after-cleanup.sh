#!/bin/bash

# Fix landing page after cleanup

echo "🔧 Fixing landing page after cleanup..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Restoring Working App.js..."
echo "================================"

# Restore working App.js (without debug but with proper routing)
echo "📋 Restoring working App.js..."
cd /opt/us-calendar/frontend/src

# Create a backup
cp App.js App.js.cleanup-backup

# Restore working App.js
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

  const handleUserSelect = (user) => {
    setCurrentUser(user);
  };

  const handleLogout = () => {
    setCurrentUser(null);
  };

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading...</p>
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

echo "📋 Working App.js restored"

echo ""
echo "🔍 Step 2: Restoring Working LandingPage.js..."
echo "================================"

# Restore working LandingPage.js
echo "📋 Restoring working LandingPage.js..."
cd /opt/us-calendar/frontend/src/pages

# Create a backup
cp LandingPage.js LandingPage.js.cleanup-backup

# Restore working LandingPage.js
cat > LandingPage.js << 'EOF'
import React from 'react';
import './LandingPage.css';

const LandingPage = ({ users, onUserSelect }) => {
  const handleUserClick = (user) => {
    onUserSelect(user);
  };

  return (
    <div className="landing-page">
      <div className="landing-container">
        <div className="landing-header">
          <h1>Our Calendar</h1>
        </div>
        
        <div className="user-selection">
          {users.map((user) => (
            <div 
              key={user.id} 
              className="user-card"
              onClick={() => handleUserClick(user)}
            >
              <div className="user-avatar">
                {user.name.charAt(0).toUpperCase()}
              </div>
              <h2>{user.name}</h2>
              <p>Click to continue as {user.name}</p>
            </div>
          ))}
        </div>
        
        <div className="landing-footer">
          <p>Our shared calendar</p>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;
EOF

echo "📋 Working LandingPage.js restored"

echo ""
echo "🔍 Step 3: Restoring Working LandingPage.css..."
echo "================================"

# Restore working LandingPage.css
echo "📋 Restoring working LandingPage.css..."
cd /opt/us-calendar/frontend/src/pages

# Create a backup
cp LandingPage.css LandingPage.css.cleanup-backup

# Restore working LandingPage.css
cat > LandingPage.css << 'EOF'
.landing-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.landing-container {
  max-width: 800px;
  width: 100%;
  text-align: center;
}

.landing-header {
  margin-bottom: 60px;
}

.landing-header h1 {
  font-size: 3.5rem;
  font-weight: 700;
  color: white;
  margin-bottom: 16px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.landing-header p {
  font-size: 1.2rem;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 300;
}

.user-selection {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 30px;
  margin-bottom: 60px;
}

.user-card {
  background: white;
  border-radius: 20px;
  padding: 40px 30px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.user-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #667eea, #764ba2);
}

.user-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
}

.user-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 700;
  margin: 0 auto 20px;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.user-card h2 {
  font-size: 1.8rem;
  color: #333;
  margin-bottom: 12px;
  font-weight: 600;
}

.user-card p {
  color: #666;
  font-size: 1rem;
  line-height: 1.5;
}

.landing-footer {
  color: rgba(255, 255, 255, 0.8);
  font-size: 1rem;
  font-weight: 300;
}

/* Responsive design */
@media (max-width: 768px) {
  .landing-page {
    padding: 15px;
  }
  
  .landing-container {
    max-width: 100%;
  }
  
  .landing-header {
    margin-bottom: 40px;
  }
  
  .landing-header h1 {
    font-size: 2.5rem;
  }
  
  .landing-header p {
    font-size: 1rem;
  }
  
  .user-selection {
    grid-template-columns: 1fr;
    gap: 20px;
    margin-bottom: 40px;
  }
  
  .user-card {
    padding: 30px 20px;
  }
  
  .user-card:hover {
    transform: translateY(-5px);
  }
  
  .user-avatar {
    width: 60px;
    height: 60px;
    font-size: 1.5rem;
  }
  
  .user-card h2 {
    font-size: 1.5rem;
  }
  
  .user-card p {
    font-size: 0.9rem;
  }
  
  .landing-footer {
    font-size: 0.9rem;
  }
}

@media (max-width: 480px) {
  .landing-page {
    padding: 10px;
  }
  
  .landing-header {
    margin-bottom: 30px;
  }
  
  .landing-header h1 {
    font-size: 2rem;
  }
  
  .landing-header p {
    font-size: 0.9rem;
  }
  
  .user-card {
    padding: 25px 15px;
  }
  
  .user-avatar {
    width: 50px;
    height: 50px;
    font-size: 1.2rem;
  }
  
  .user-card h2 {
    font-size: 1.3rem;
  }
  
  .user-card p {
    font-size: 0.8rem;
  }
  
  .landing-footer {
    font-size: 0.8rem;
  }
}

@media (max-width: 360px) {
  .landing-page {
    padding: 5px;
  }
  
  .landing-header h1 {
    font-size: 1.8rem;
  }
  
  .landing-header p {
    font-size: 0.8rem;
  }
  
  .user-card {
    padding: 20px 10px;
  }
  
  .user-avatar {
    width: 45px;
    height: 45px;
    font-size: 1.1rem;
  }
  
  .user-card h2 {
    font-size: 1.2rem;
  }
  
  .user-card p {
    font-size: 0.75rem;
  }
  
  .landing-footer {
    font-size: 0.75rem;
  }
}

@media (max-width: 768px) and (orientation: landscape) {
  .landing-page {
    padding: 10px;
  }
  
  .landing-header {
    margin-bottom: 20px;
  }
  
  .landing-header h1 {
    font-size: 2rem;
  }
  
  .user-selection {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
    margin-bottom: 20px;
  }
  
  .user-card {
    padding: 20px 15px;
  }
  
  .user-avatar {
    width: 50px;
    height: 50px;
    font-size: 1.2rem;
  }
  
  .user-card h2 {
    font-size: 1.2rem;
  }
  
  .user-card p {
    font-size: 0.8rem;
  }
}

@media (hover: none) and (pointer: coarse) {
  .user-card:hover {
    transform: none;
  }
  
  .user-card:active {
    transform: scale(0.98);
  }
  
  .user-card {
    -webkit-tap-highlight-color: transparent;
  }
}

@media (prefers-contrast: high) {
  .user-card {
    border: 2px solid #333;
  }
  
  .user-card::before {
    background: #333;
  }
}

@media (prefers-reduced-motion: reduce) {
  .user-card {
    transition: none;
  }
  
  .user-card:hover {
    transform: none;
  }
  
  .user-card:active {
    transform: none;
  }
}

@media (prefers-color-scheme: dark) {
  .user-card {
    background: #2a2a2a;
  }
  
  .user-card h2 {
    color: #fff;
  }
  
  .user-card p {
    color: #ccc;
  }
}
EOF

echo "📋 Working LandingPage.css restored"

echo ""
echo "🔍 Step 4: Rebuilding Frontend..."
echo "================================"

# Rebuild the frontend
echo "📋 Rebuilding frontend..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    cp src/App.js.cleanup-backup src/App.js
    cp src/pages/LandingPage.js.cleanup-backup src/pages/LandingPage.js
    cp src/pages/LandingPage.css.cleanup-backup src/pages/LandingPage.css
    exit 1
fi

echo ""
echo "🔍 Step 5: Deploying Working Version..."
echo "================================"

# Deploy the working version
echo "📋 Deploying working version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 6: Testing Working Version..."
echo "================================"

# Test the working version
echo "📋 Testing working version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Landing Page Fix Complete!"
echo ""
echo "🌐 Your calendar should now work at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Expected Result:"
echo "   - Landing page should display with user cards"
echo "   - Angel and Andrea user cards should be visible"
echo "   - Clean, professional interface"
echo "   - No debug elements"
echo "   - All functionality working"
echo ""
echo "📱 The landing page should now display the user selection interface!" 