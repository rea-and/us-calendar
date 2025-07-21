#!/bin/bash

# Restore working version and add functionality carefully

echo "🔧 Restoring working version and adding functionality carefully..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Restoring Working Minimal Version..."
echo "================================"

# Restore the working minimal version
echo "📋 Restoring working minimal version..."
cd /opt/us-calendar/frontend/src

# Restore working minimal App.js
cat > App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configure axios base URL
axios.defaults.baseURL = 'https://carlevato.net/api';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [currentUser, setCurrentUser] = useState(null);

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

  const handleUserSelect = (user) => {
    setCurrentUser(user);
  };

  const handleLogout = () => {
    setCurrentUser(null);
  };

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

  // If user is selected, show simple calendar page
  if (currentUser) {
    return (
      <div style={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '20px'
      }}>
        <div style={{
          maxWidth: '1200px',
          margin: '0 auto',
          background: 'white',
          borderRadius: '20px',
          padding: '40px',
          boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)'
        }}>
          <div style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '30px'
          }}>
            <h1 style={{
              fontSize: '2.5rem',
              color: '#333',
              margin: 0
            }}>
              Welcome, {currentUser.name}!
            </h1>
            <button 
              onClick={handleLogout}
              style={{
                background: 'linear-gradient(135deg, #667eea, #764ba2)',
                color: 'white',
                border: 'none',
                padding: '12px 24px',
                borderRadius: '10px',
                cursor: 'pointer',
                fontSize: '1rem',
                fontWeight: '600'
              }}
            >
              Logout
            </button>
          </div>
          
          <div style={{
            textAlign: 'center',
            padding: '60px 20px'
          }}>
            <h2 style={{
              fontSize: '2rem',
              color: '#666',
              marginBottom: '20px'
            }}>
              Calendar Coming Soon
            </h2>
            <p style={{
              fontSize: '1.2rem',
              color: '#999',
              lineHeight: '1.6'
            }}>
              The full calendar functionality will be restored in the next step.
              <br />
              For now, you can create events using the API.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Show landing page
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

echo "📋 Working minimal version restored"

echo ""
echo "🔍 Step 2: Rebuilding Working Version..."
echo "================================"

# Rebuild the working version
echo "📋 Rebuilding working version..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 3: Deploying Working Version..."
echo "================================"

# Deploy the working version
echo "📋 Deploying working version..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 4: Testing Working Version..."
echo "================================"

# Test the working version
echo "📋 Testing working version:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Working Version Restored!"
echo ""
echo "🌐 Your working calendar is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 What Should Work Now:"
echo "   - Landing page with user cards (Angel & Andrea)"
echo "   - Clicking on user cards shows calendar page"
echo "   - Calendar page shows welcome message"
echo "   - Logout button returns to landing page"
echo "   - No React Router (simplified state-based navigation)"
echo ""
echo "📱 Test the functionality:"
echo "   1. Click on Angel or Andrea user card"
echo "   2. Should show calendar page with welcome message"
echo "   3. Click logout to return to landing page"
echo ""
echo "🎯 This version uses simple state management instead of React Router"
echo "   to avoid the routing issues that were causing empty pages." 