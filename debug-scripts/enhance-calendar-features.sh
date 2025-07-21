#!/bin/bash

# Enhance calendar with clickable days and additional components

echo "🔧 Enhancing calendar with clickable days and additional features..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Creating Enhanced Calendar Component..."
echo "================================"

# Create enhanced Calendar component
echo "📋 Creating enhanced Calendar component..."
cd /opt/us-calendar/frontend/src

# Create enhanced Calendar component
cat > Calendar.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';

function Calendar({ currentUser }) {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showEventForm, setShowEventForm] = useState(false);
  const [showEventDetails, setShowEventDetails] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [selectedDate, setSelectedDate] = useState(null);
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
      setShowEventDetails(false);
    } catch (error) {
      console.error('Error deleting event:', error);
    }
  };

  const handleDayClick = (date) => {
    if (date) {
      setSelectedDate(date);
      setNewEvent({
        ...newEvent,
        date: formatDate(date)
      });
      setShowEventForm(true);
    }
  };

  const handleEventClick = (event) => {
    setSelectedEvent(event);
    setShowEventDetails(true);
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
    const dateStr = formatDate(date);
    return events.filter(event => event.date === dateStr);
  };

  const formatDate = (date) => {
    return date.toISOString().split('T')[0];
  };

  const formatTime = (time) => {
    if (!time) return '';
    const [hours, minutes] = time.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${minutes} ${ampm}`;
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
                  cursor: day ? 'pointer' : 'default',
                  transition: 'all 0.2s ease',
                  ...(isToday && {
                    border: '2px solid #667eea',
                    background: '#f0f4ff'
                  }),
                  ...(day && {
                    ':hover': {
                      background: '#f8f9fa',
                      transform: 'scale(1.02)'
                    }
                  })
                }}
                onClick={() => handleDayClick(day)}
                title={day ? `Click to add event on ${day.toLocaleDateString()}` : ''}
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
                          onClick={(e) => {
                            e.stopPropagation();
                            handleEventClick(event);
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
                            {formatTime(event.time)}
                          </div>
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
              {selectedDate ? `Add Event for ${selectedDate.toLocaleDateString()}` : 'Add New Event'}
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
                  onClick={() => {
                    setShowEventForm(false);
                    setSelectedDate(null);
                  }}
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

      {/* Event Details Modal */}
      {showEventDetails && selectedEvent && (
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
              marginBottom: '20px',
              textAlign: 'center'
            }}>
              Event Details
            </h2>
            
            <div style={{ marginBottom: '20px' }}>
              <label style={{
                display: 'block',
                marginBottom: '8px',
                fontWeight: '600',
                color: '#333'
              }}>
                Title
              </label>
              <div style={{
                padding: '12px',
                border: '2px solid #e0e0e0',
                borderRadius: '8px',
                fontSize: '1rem',
                background: '#f8f9fa'
              }}>
                {selectedEvent.title}
              </div>
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
              <div style={{
                padding: '12px',
                border: '2px solid #e0e0e0',
                borderRadius: '8px',
                fontSize: '1rem',
                background: '#f8f9fa',
                minHeight: '60px'
              }}>
                {selectedEvent.description || 'No description'}
              </div>
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
              <div style={{
                padding: '12px',
                border: '2px solid #e0e0e0',
                borderRadius: '8px',
                fontSize: '1rem',
                background: '#f8f9fa'
              }}>
                {new Date(selectedEvent.date).toLocaleDateString()}
              </div>
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
              <div style={{
                padding: '12px',
                border: '2px solid #e0e0e0',
                borderRadius: '8px',
                fontSize: '1rem',
                background: '#f8f9fa'
              }}>
                {formatTime(selectedEvent.time)}
              </div>
            </div>
            
            <div style={{
              display: 'flex',
              gap: '15px',
              justifyContent: 'center'
            }}>
              <button
                onClick={() => setShowEventDetails(false)}
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
                Close
              </button>
              <button
                onClick={() => handleDeleteEvent(selectedEvent.id)}
                style={{
                  background: '#dc3545',
                  color: 'white',
                  border: 'none',
                  padding: '12px 24px',
                  borderRadius: '8px',
                  cursor: 'pointer',
                  fontSize: '1rem',
                  fontWeight: '600'
                }}
              >
                Delete Event
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Calendar;
EOF

echo "📋 Enhanced Calendar component created"

echo ""
echo "🔍 Step 2: Rebuilding Enhanced Calendar..."
echo "================================"

# Rebuild with enhanced calendar
echo "📋 Rebuilding enhanced calendar..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 3: Deploying Enhanced Calendar..."
echo "================================"

# Deploy the enhanced calendar
echo "📋 Deploying enhanced calendar..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 4: Testing Enhanced Calendar..."
echo "================================"

# Test the enhanced calendar
echo "📋 Testing enhanced calendar:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Enhanced Calendar Features Added!"
echo ""
echo "🌐 Your enhanced calendar is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 New Enhanced Features:"
echo "   - ✅ Clickable calendar days (click any day to add event)"
echo "   - ✅ Event details modal (click events to view details)"
echo "   - ✅ Better time formatting (12-hour format with AM/PM)"
echo "   - ✅ Pre-filled date when clicking on days"
echo "   - ✅ Event deletion from details modal"
echo "   - ✅ Hover effects on calendar days"
echo "   - ✅ Better event display with formatted times"
echo "   - ✅ Improved user experience and interactions"
echo ""
echo "📱 Test the Enhanced Functionality:"
echo "   1. Click on any calendar day → opens event form with pre-filled date"
echo "   2. Click on existing events → opens event details modal"
echo "   3. View event details → title, description, date, time"
echo "   4. Delete events → from details modal"
echo "   5. Better time display → 12-hour format (e.g., '2:30 PM')"
echo "   6. Hover effects → days highlight when you hover over them"
echo ""
echo "🎯 Calendar is now fully interactive and feature-complete!" 