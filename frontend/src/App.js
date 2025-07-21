import React, { useState, useEffect } from 'react';
import axios from 'axios';
import CalendarPage from './pages/CalendarPage';
import LandingPage from './pages/LandingPage';
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

  // If user is selected, show calendar page
  if (currentUser) {
    return (
      <CalendarPage 
        currentUser={currentUser} 
        onLogout={handleLogout}
      />
    );
  }

  // Show landing page
  return (
    <LandingPage 
      users={users} 
      onUserSelect={handleUserSelect} 
    />
  );
}

export default App; 