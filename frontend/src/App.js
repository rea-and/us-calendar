import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import LandingPage from './pages/LandingPage';
import CalendarPage from './pages/CalendarPage';
import './App.css';

// Configure axios base URL
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? 'https://carlaveto.net/api' 
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