#!/bin/bash

# Add full calendar functionality to working version

echo "🔧 Adding full calendar functionality to working version..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Adding Full Calendar Component..."
echo "================================"

# Create Calendar component
echo "📋 Creating Calendar component..."
cd /opt/us-calendar/frontend/src

# Create Calendar component
cat > Calendar.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Calendar({ currentUser }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showEventForm, setShowEventForm] = useState(false);
  const [currentDate, setCurrentDate] = useState(new Date());
  const [newEvent, setNewEvent] = useState({
    title: '',
    description: '',
    date: '',
    time: '',
    user_id: currentUser.id
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const response = await axios.get('/events');
      setEvents(response.data);
    } catch (error) {
      console.error('Error loading events:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateEvent = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/events', newEvent);
      setNewEvent({
        title: '',
        description: '',
        date: '',
        time: '',
        user_id: currentUser.id
      });
      setShowEventForm(false);
      loadEvents();
    } catch (error) {
      console.error('Error creating event:', error);
    }
  };

  const handleDeleteEvent = async (eventId) => {
    try {
      await axios.delete(`/events/${eventId}`);
      loadEvents();
    } catch (error) {
      console.error('Error deleting event:', error);
    }
  };

  const getDaysInMonth = (date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDay = firstDay.getDay();
    
    const days = [];
    for (let i = 0; i < startingDay; i++) {
      days.push(null);
    }
    for (let i = 1; i <= daysInMonth; i++) {
      days.push(new Date(year, month, i));
    }
    return days;
  };

  const getEventsForDate = (date) => {
    if (!date) return [];
    const dateStr = date.toISOString().split('T')[0];
    return events.filter(event => event.date === dateStr);
  };

  const formatDate = (date) => {
    return date.toISOString().split('T')[0];
  };

  const days = getDaysInMonth(currentDate);
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  if (loading) {
    return (
      <div style={{
        textAlign: 'center',
        padding: '40px',
        color: '#666'
      }}>
        Loading calendar...
      </div>
    );
  }

  return (
    <div style={{
      maxWidth: '1200px',
      margin: '0 auto'
    }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '30px',
        flexWrap: 'wrap',
        gap: '20px'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          color: '#333',
          margin: 0
        }}>
          Welcome, {currentUser.name}!
        </h1>
        <div style={{
          display: 'flex',
          gap: '15px',
          alignItems: 'center'
        }}>
          <button 
            onClick={() => setShowEventForm(true)}
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
            + Add Event
          </button>
        </div>
      </div>

      {/* Month Navigation */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '30px',
        background: 'white',
        padding: '20px',
        borderRadius: '15px',
        boxShadow: '0 4px 15px rgba(0, 0, 0, 0.1)'
      }}>
        <button 
          onClick={() => setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1))}
          style={{
            background: 'linear-gradient(135deg, #667eea, #764ba2)',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '1rem'
          }}
        >
          ← Previous
        </button>
        <h2 style={{
          fontSize: '2rem',
          color: '#333',
          margin: 0,
          fontWeight: '600'
        }}>
          {monthNames[currentDate.getMonth()]} {currentDate.getFullYear()}
        </h2>
        <button 
          onClick={() => setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1))}
          style={{
            background: 'linear-gradient(135deg, #667eea, #764ba2)',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '1rem'
          }}
        >
          Next →
        </button>
      </div>

      {/* Calendar Grid */}
      <div style={{
        background: 'white',
        borderRadius: '15px',
        padding: '30px',
        boxShadow: '0 4px 15px rgba(0, 0, 0, 0.1)',
        marginBottom: '30px'
      }}>
        {/* Day Headers */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(7, 1fr)',
          gap: '10px',
          marginBottom: '20px'
        }}>
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
            <div key={day} style={{
              textAlign: 'center',
              fontWeight: '600',
              color: '#666',
              padding: '15px 10px',
              fontSize: '1.1rem'
            }}>
              {day}
            </div>
          ))}
        </div>

        {/* Calendar Days */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(7, 1fr)',
          gap: '10px'
        }}>
          {days.map((day, index) => {
            const dayEvents = getEventsForDate(day);
            const isToday = day && formatDate(day) === formatDate(new Date());
            
            return (
              <div 
                key={index}
                style={{
                  minHeight: '120px',
                  border: '1px solid #e0e0e0',
                  borderRadius: '10px',
                  padding: '10px',
                  background: day ? 'white' : '#f8f9fa',
                  position: 'relative',
                  ...(isToday && {
                    border: '2px solid #667eea',
                    background: '#f0f4ff'
                  })
                }}
              >
                {day && (
                  <>
                    <div style={{
                      fontWeight: '600',
                      color: isToday ? '#667eea' : '#333',
                      marginBottom: '8px',
                      fontSize: '1.1rem'
                    }}>
                      {day.getDate()}
                    </div>
                    <div style={{
                      maxHeight: '80px',
                      overflowY: 'auto'
                    }}>
                      {dayEvents.map(event => (
                        <div 
                          key={event.id}
                          style={{
                            background: 'linear-gradient(135deg, #667eea, #764ba2)',
                            color: 'white',
                            padding: '4px 8px',
                            borderRadius: '6px',
                            fontSize: '0.8rem',
                            marginBottom: '4px',
                            cursor: 'pointer',
                            position: 'relative'
                          }}
                          title={`${event.title} - ${event.time}`}
                        >
                          <div style={{
                            fontWeight: '600',
                            marginBottom: '2px'
                          }}>
                            {event.title}
                          </div>
                          <div style={{
                            fontSize: '0.7rem',
                            opacity: '0.9'
                          }}>
                            {event.time}
                          </div>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteEvent(event.id);
                            }}
                            style={{
                              position: 'absolute',
                              top: '2px',
                              right: '2px',
                              background: 'rgba(255, 255, 255, 0.2)',
                              border: 'none',
                              color: 'white',
                              borderRadius: '50%',
                              width: '16px',
                              height: '16px',
                              fontSize: '10px',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}
                          >
                            ×
                          </button>
                        </div>
                      ))}
                    </div>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Event Form Modal */}
      {showEventForm && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000
        }}>
          <div style={{
            background: 'white',
            borderRadius: '15px',
            padding: '40px',
            maxWidth: '500px',
            width: '90%',
            maxHeight: '90vh',
            overflowY: 'auto'
          }}>
            <h2 style={{
              fontSize: '2rem',
              color: '#333',
              marginBottom: '30px',
              textAlign: 'center'
            }}>
              Add New Event
            </h2>
            
            <form onSubmit={handleCreateEvent}>
              <div style={{ marginBottom: '20px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#333'
                }}>
                  Event Title
                </label>
                <input
                  type="text"
                  value={newEvent.title}
                  onChange={(e) => setNewEvent({...newEvent, title: e.target.value})}
                  required
                  style={{
                    width: '100%',
                    padding: '12px',
                    border: '2px solid #e0e0e0',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#333'
                }}>
                  Description
                </label>
                <textarea
                  value={newEvent.description}
                  onChange={(e) => setNewEvent({...newEvent, description: e.target.value})}
                  rows="3"
                  style={{
                    width: '100%',
                    padding: '12px',
                    border: '2px solid #e0e0e0',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    boxSizing: 'border-box',
                    resize: 'vertical'
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#333'
                }}>
                  Date
                </label>
                <input
                  type="date"
                  value={newEvent.date}
                  onChange={(e) => setNewEvent({...newEvent, date: e.target.value})}
                  required
                  style={{
                    width: '100%',
                    padding: '12px',
                    border: '2px solid #e0e0e0',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '30px' }}>
                <label style={{
                  display: 'block',
                  marginBottom: '8px',
                  fontWeight: '600',
                  color: '#333'
                }}>
                  Time
                </label>
                <input
                  type="time"
                  value={newEvent.time}
                  onChange={(e) => setNewEvent({...newEvent, time: e.target.value})}
                  required
                  style={{
                    width: '100%',
                    padding: '12px',
                    border: '2px solid #e0e0e0',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{
                display: 'flex',
                gap: '15px',
                justifyContent: 'center'
              }}>
                <button
                  type="button"
                  onClick={() => setShowEventForm(false)}
                  style={{
                    background: '#6c757d',
                    color: 'white',
                    border: 'none',
                    padding: '12px 24px',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '1rem',
                    fontWeight: '600'
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{
                    background: 'linear-gradient(135deg, #667eea, #764ba2)',
                    color: 'white',
                    border: 'none',
                    padding: '12px 24px',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    fontSize: '1rem',
                    fontWeight: '600'
                  }}
                >
                  Create Event
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Calendar;
EOF

echo "📋 Calendar component created"

echo ""
echo "🔍 Step 2: Updating App.js with Calendar Integration..."
echo "================================"

# Update App.js to use the Calendar component
cat > App.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import Calendar from './Calendar';
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
              ← Back to Users
            </button>
          </div>
          
          <Calendar currentUser={currentUser} />
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

echo "📋 App.js updated with Calendar integration"

echo ""
echo "🔍 Step 3: Rebuilding with Full Calendar..."
echo "================================"

# Rebuild with full calendar
echo "📋 Rebuilding with full calendar..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 4: Deploying Full Calendar..."
echo "================================"

# Deploy the full calendar
echo "📋 Deploying full calendar..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 5: Testing Full Calendar..."
echo "================================"

# Test the full calendar
echo "📋 Testing full calendar:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Full Calendar Added Successfully!"
echo ""
echo "🌐 Your full calendar is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 New Features Added:"
echo "   - ✅ Full calendar grid with month navigation"
echo "   - ✅ Event creation form with modal"
echo "   - ✅ Event display on calendar days"
echo "   - ✅ Event deletion (click × on events)"
echo "   - ✅ Today highlighting"
echo "   - ✅ Month navigation (Previous/Next)"
echo "   - ✅ Responsive design for mobile"
echo ""
echo "📱 Test the Full Functionality:"
echo "   1. Click on Angel or Andrea user card"
echo "   2. See full calendar with month navigation"
echo "   3. Click '+ Add Event' to create events"
echo "   4. Fill form: Title, Description, Date, Time"
echo "   5. Events appear on calendar days"
echo "   6. Click × on events to delete them"
echo "   7. Use Previous/Next to navigate months"
echo ""
echo "🎯 Full calendar functionality is now complete!" 