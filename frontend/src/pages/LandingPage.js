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