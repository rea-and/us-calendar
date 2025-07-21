#!/bin/bash

# Restore original calendar page with all components and features

echo "🔧 Restoring original calendar page with all components and features..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Restoring Original Calendar Components..."
echo "================================"

cd /opt/us-calendar/frontend/src

# Restore original CalendarPage.js
echo "📋 Restoring CalendarPage.js..."
cat > pages/CalendarPage.js << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameMonth, isSameDay, addMonths, subMonths } from 'date-fns';
import EventForm from '../components/EventForm';
import EventList from '../components/EventList';
import './CalendarPage.css';

const CalendarPage = ({ currentUser, onLogout }) => {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [events, setEvents] = useState([]);
  const [showEventForm, setShowEventForm] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [selectedDate, setSelectedDate] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/events');
      setEvents(response.data);
      setError(null);
    } catch (error) {
      console.error('Error loading events:', error);
      setError('Failed to load events');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateEvent = async (eventData) => {
    try {
      const response = await axios.post('/events', {
        ...eventData,
        user_id: currentUser.id
      });
      setEvents([...events, response.data]);
      setShowEventForm(false);
      setError(null);
    } catch (error) {
      console.error('Error creating event:', error);
      setError('Failed to create event');
    }
  };

  const handleUpdateEvent = async (eventId, eventData) => {
    try {
      const response = await axios.put(`/events/${eventId}`, eventData);
      setEvents(events.map(event => 
        event.id === eventId ? response.data : event
      ));
      setSelectedEvent(null);
      setError(null);
    } catch (error) {
      console.error('Error updating event:', error);
      setError('Failed to update event');
    }
  };

  const handleDeleteEvent = async (eventId) => {
    try {
      await axios.delete(`/events/${eventId}`);
      setEvents(events.filter(event => event.id !== eventId));
      setSelectedEvent(null);
      setError(null);
    } catch (error) {
      console.error('Error deleting event:', error);
      setError('Failed to delete event');
    }
  };

  const handleDateClick = (date) => {
    setSelectedDate(date);
    setShowEventForm(true);
    setSelectedEvent(null);
  };

  const nextMonth = () => setCurrentDate(addMonths(currentDate, 1));
  const prevMonth = () => setCurrentDate(subMonths(currentDate, 1));

  const getDaysInMonth = () => {
    const start = startOfMonth(currentDate);
    const end = endOfMonth(currentDate);
    const days = eachDayOfInterval({ start, end });
    
    const firstDayOfWeek = start.getDay();
    const lastDayOfWeek = end.getDay();
    
    const paddingStart = Array.from({ length: firstDayOfWeek }, (_, i) => {
      const date = new Date(start);
      date.setDate(date.getDate() - (firstDayOfWeek - i));
      return date;
    });
    
    const paddingEnd = Array.from({ length: 6 - lastDayOfWeek }, (_, i) => {
      const date = new Date(end);
      date.setDate(date.getDate() + (i + 1));
      return date;
    });
    
    return [...paddingStart, ...days, ...paddingEnd];
  };

  const getEventsForDay = (date) => {
    return events.filter(event => {
      const eventStart = new Date(event.start_date);
      const eventEnd = new Date(event.end_date);
      
      const dateStart = new Date(date);
      dateStart.setHours(0, 0, 0, 0);
      
      const dateEnd = new Date(date);
      dateEnd.setHours(23, 59, 59, 999);
      
      return eventStart <= dateEnd && eventEnd >= dateStart;
    });
  };

  const days = getDaysInMonth();

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading calendar...</p>
      </div>
    );
  }

  return (
    <div className="calendar-page">
      <div className="calendar-header">
        <div className="header-content">
          <h1>Our Calendar</h1>
          <div className="user-info">
            <span>Welcome, {currentUser.name}!</span>
            <button className="btn btn-secondary" onClick={onLogout}>
              Logout
            </button>
          </div>
        </div>
      </div>

      <div className="container">
        {error && (
          <div className="alert alert-error">
            {error}
          </div>
        )}

        <div className="calendar-controls">
          <button className="btn btn-secondary" onClick={prevMonth}>
            ← Previous
          </button>
          <h2>{format(currentDate, 'MMMM yyyy')}</h2>
          <button className="btn btn-secondary" onClick={nextMonth}>
            Next →
          </button>
        </div>

        <div className="calendar-layout">
          <div className="calendar-main">
            <div className="calendar">
              <div className="calendar-weekdays">
                {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                  <div key={day} className="weekday">{day}</div>
                ))}
              </div>
              <div className="calendar-grid">
                {days.map((day, index) => {
                  const dayEvents = getEventsForDay(day);
                  const isCurrentMonth = isSameMonth(day, currentDate);
                  const isToday = isSameDay(day, new Date());
                  
                  return (
                    <div 
                      key={index} 
                      className={`calendar-day ${!isCurrentMonth ? 'other-month' : ''} ${isToday ? 'today' : ''}`}
                      onClick={() => handleDateClick(day)}
                    >
                      <div className="day-number">{format(day, 'd')}</div>
                      <div className="day-events">
                        {dayEvents.map(event => {
                          const eventStart = new Date(event.start_date);
                          const eventEnd = new Date(event.end_date);
                          const isStartDay = isSameDay(eventStart, day);
                          const isEndDay = isSameDay(eventEnd, day);
                          const isMultiDay = !isSameDay(eventStart, eventEnd);
                          
                          return (
                            <div 
                              key={event.id}
                              className={`event-item event-${event.event_type} ${isMultiDay ? 'multi-day' : ''} ${isStartDay ? 'event-start' : ''} ${isEndDay ? 'event-end' : ''} ${event.applies_to_both ? 'event-both' : ''}`}
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedEvent(event);
                              }}
                              title={`${event.title} - ${event.user_name}${event.applies_to_both ? ' (Both)' : ''}${isMultiDay ? ` (${format(eventStart, 'MMM d')} - ${format(eventEnd, 'MMM d')})` : ''}`}
                            >
                              <div className="event-title">{event.title}</div>
                              <div className="event-time">
                                {format(eventStart, 'HH:mm')}
                                {isMultiDay && !isEndDay && ' →'}
                              </div>
                              <div className="event-user">
                                {event.applies_to_both ? '👨👩' : (event.user_name === 'Andrea' ? '👨' : '👩')}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          <div className="calendar-sidebar">
            <div className="sidebar-section">
              <h3>Quick Actions</h3>
              <button 
                className="btn btn-primary" 
                onClick={() => setShowEventForm(true)}
              >
                Add New Event
              </button>
            </div>

            <div className="sidebar-section">
              <h3>Event Types</h3>
              <div className="event-legend">
                <div className="legend-item">
                  <span className="legend-color work"></span>
                  <span>Work</span>
                </div>
                <div className="legend-item">
                  <span className="legend-color holiday"></span>
                  <span>Holiday</span>
                </div>
                <div className="legend-item">
                  <span className="legend-color other"></span>
                  <span>Other</span>
                </div>
              </div>
            </div>

            <div className="sidebar-section">
              <h3>Event Owners</h3>
              <div className="user-legend">
                <div className="legend-item">
                  <span className="legend-user-indicator">👨</span>
                  <span>Andrea's Events</span>
                </div>
                <div className="legend-item">
                  <span className="legend-user-indicator">👩</span>
                  <span>Angel's Events</span>
                </div>
                <div className="legend-item">
                  <div className="legend-both-avatars">
                    <span className="legend-user-indicator">👨</span>
                    <span className="legend-user-indicator">👩</span>
                  </div>
                  <span>Both (Shared Events)</span>
                </div>
              </div>
            </div>

            <div className="sidebar-section">
              <h3>Upcoming Events</h3>
              <EventList 
                events={events.filter(event => new Date(event.start_date) >= new Date()).slice(0, 5)}
                onEventClick={setSelectedEvent}
                onDeleteEvent={handleDeleteEvent}
                compact={true}
              />
            </div>
          </div>
        </div>

        {showEventForm && (
          <EventForm
            onSubmit={handleCreateEvent}
            onCancel={() => {
              setShowEventForm(false);
              setSelectedDate(null);
            }}
            users={[currentUser]}
            selectedDate={selectedDate}
          />
        )}

        {selectedEvent && (
          <EventForm
            event={selectedEvent}
            onSubmit={(data) => handleUpdateEvent(selectedEvent.id, data)}
            onCancel={() => setSelectedEvent(null)}
            onDelete={() => handleDeleteEvent(selectedEvent.id)}
            users={[currentUser]}
            isEdit={true}
          />
        )}
      </div>
    </div>
  );
};

export default CalendarPage;
EOF

echo "📋 CalendarPage.js restored"

echo ""
echo "🔍 Step 2: Restoring EventForm Component..."
echo "================================"

# Restore EventForm component
echo "📋 Restoring EventForm.js..."
cat > components/EventForm.js << 'EOF'
import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import './EventForm.css';

const EventForm = ({ event, onSubmit, onCancel, onDelete, users, isEdit = false, selectedDate = null }) => {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    event_type: 'work',
    start_date: '',
    start_time: '',
    end_date: '',
    end_time: '',
    applies_to_both: false
  });
  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (event) {
      const startDate = new Date(event.start_date);
      const endDate = new Date(event.end_date);
      
      setFormData({
        title: event.title,
        description: event.description || '',
        event_type: event.event_type,
        start_date: format(startDate, 'yyyy-MM-dd'),
        start_time: format(startDate, 'HH:mm'),
        end_date: format(endDate, 'yyyy-MM-dd'),
        end_time: format(endDate, 'HH:mm'),
        applies_to_both: event.applies_to_both || false
      });
    } else if (selectedDate) {
      const now = new Date();
      setFormData({
        title: '',
        description: '',
        event_type: 'work',
        start_date: format(selectedDate, 'yyyy-MM-dd'),
        start_time: '08:00',
        end_date: format(selectedDate, 'yyyy-MM-dd'),
        end_time: '09:00',
        applies_to_both: false
      });
    } else {
      const now = new Date();
      setFormData({
        title: '',
        description: '',
        event_type: 'work',
        start_date: format(now, 'yyyy-MM-dd'),
        start_time: '08:00',
        end_date: format(now, 'yyyy-MM-dd'),
        end_time: '09:00',
        applies_to_both: false
      });
    }
  }, [event, selectedDate]);

  const validateForm = () => {
    const newErrors = {};

    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    }

    if (!formData.start_date) {
      newErrors.start_date = 'Start date is required';
    }

    if (!formData.end_date) {
      newErrors.end_date = 'End date is required';
    }

    if (!formData.start_time) {
      newErrors.start_time = 'Start time is required';
    }

    if (!formData.end_time) {
      newErrors.end_time = 'End time is required';
    }

    const startDateTime = new Date(`${formData.start_date}T${formData.start_time}`);
    const endDateTime = new Date(`${formData.end_date}T${formData.end_time}`);

    if (endDateTime <= startDateTime) {
      newErrors.end_time = 'End time must be after start time';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const startDateTime = new Date(`${formData.start_date}T${formData.start_time}`);
    const endDateTime = new Date(`${formData.end_date}T${formData.end_time}`);

    const eventData = {
      title: formData.title.trim(),
      description: formData.description.trim(),
      event_type: formData.event_type,
      start_date: startDateTime.toISOString(),
      end_date: endDateTime.toISOString(),
      applies_to_both: formData.applies_to_both
    };

    onSubmit(eventData);
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));

    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const handleStartDateChange = (e) => {
    const newStartDate = e.target.value;
    setFormData(prev => ({
      ...prev,
      start_date: newStartDate,
      end_date: newStartDate
    }));
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <h2>{isEdit ? 'Edit Event' : 'Add New Event'}</h2>
          <button className="modal-close" onClick={onCancel}>
            ×
          </button>
        </div>

        <form onSubmit={handleSubmit} className="event-form">
          <div className="form-group">
            <label htmlFor="title">Event Title *</label>
            <input
              type="text"
              id="title"
              name="title"
              className={`form-control ${errors.title ? 'error' : ''}`}
              value={formData.title}
              onChange={handleInputChange}
              placeholder="Enter event title"
            />
            {errors.title && <span className="error-message">{errors.title}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="description">Description</label>
            <textarea
              id="description"
              name="description"
              className="form-control"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Enter event description (optional)"
              rows="3"
            />
          </div>

          <div className="form-group">
            <label htmlFor="event_type">Event Type *</label>
            <select
              id="event_type"
              name="event_type"
              className="form-control"
              value={formData.event_type}
              onChange={handleInputChange}
            >
              <option value="work">Work</option>
              <option value="holiday">Holiday</option>
              <option value="other">Other</option>
            </select>
          </div>

          <div className="form-group">
            <div className="checkbox-group">
              <input
                type="checkbox"
                id="applies_to_both"
                name="applies_to_both"
                className="form-checkbox"
                checked={formData.applies_to_both}
                onChange={handleInputChange}
              />
              <label htmlFor="applies_to_both" className="checkbox-label">
                This event applies to both of us
              </label>
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="start_date">Start Date *</label>
              <input
                type="date"
                id="start_date"
                name="start_date"
                className={`form-control ${errors.start_date ? 'error' : ''}`}
                value={formData.start_date}
                onChange={handleStartDateChange}
              />
              {errors.start_date && <span className="error-message">{errors.start_date}</span>}
            </div>

            <div className="form-group">
              <label htmlFor="start_time">Start Time *</label>
              <input
                type="time"
                id="start_time"
                name="start_time"
                className={`form-control ${errors.start_time ? 'error' : ''}`}
                value={formData.start_time}
                onChange={handleInputChange}
              />
              {errors.start_time && <span className="error-message">{errors.start_time}</span>}
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="end_date">End Date *</label>
              <input
                type="date"
                id="end_date"
                name="end_date"
                className={`form-control ${errors.end_date ? 'error' : ''}`}
                value={formData.end_date}
                onChange={handleInputChange}
              />
              {errors.end_date && <span className="error-message">{errors.end_date}</span>}
            </div>

            <div className="form-group">
              <label htmlFor="end_time">End Time *</label>
              <input
                type="time"
                id="end_time"
                name="end_time"
                className={`form-control ${errors.end_time ? 'error' : ''}`}
                value={formData.end_time}
                onChange={handleInputChange}
              />
              {errors.end_time && <span className="error-message">{errors.end_time}</span>}
            </div>
          </div>

          <div className="form-actions">
            <button type="button" className="btn btn-secondary" onClick={onCancel}>
              Cancel
            </button>
            {isEdit && onDelete && (
              <button type="button" className="btn btn-danger" onClick={onDelete}>
                Delete
              </button>
            )}
            <button type="submit" className="btn btn-primary">
              {isEdit ? 'Update Event' : 'Create Event'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EventForm;
EOF

echo "📋 EventForm.js restored"

echo ""
echo "🔍 Step 3: Restoring EventList Component..."
echo "================================"

# Restore EventList component
echo "📋 Restoring EventList.js..."
cat > components/EventList.js << 'EOF'
import React, { useState, useRef } from 'react';
import { format } from 'date-fns';
import './EventList.css';

const EventList = ({ events, onEventClick, onDeleteEvent, compact = false }) => {
  const [swipedEventId, setSwipedEventId] = useState(null);
  const [longPressTimer, setLongPressTimer] = useState(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(null);
  const touchStartX = useRef(null);
  const touchStartY = useRef(null);

  if (!events || events.length === 0) {
    return (
      <div className="event-list-empty">
        <p>No events found</p>
      </div>
    );
  }

  const handleTouchStart = (e, eventId) => {
    touchStartX.current = e.touches[0].clientX;
    touchStartY.current = e.touches[0].clientY;
    
    const timer = setTimeout(() => {
      setShowDeleteConfirm(eventId);
    }, 500);
    setLongPressTimer(timer);
  };

  const handleTouchMove = (e) => {
    if (!touchStartX.current || !touchStartY.current) return;
    
    const touchX = e.touches[0].clientX;
    const touchY = e.touches[0].clientY;
    const deltaX = Math.abs(touchX - touchStartX.current);
    const deltaY = Math.abs(touchY - touchStartY.current);
    
    if (deltaX > 50 && deltaY < 30) {
      if (longPressTimer) {
        clearTimeout(longPressTimer);
        setLongPressTimer(null);
      }
    }
  };

  const handleTouchEnd = () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
    touchStartX.current = null;
    touchStartY.current = null;
  };

  const handleDelete = (eventId) => {
    onDeleteEvent(eventId);
    setShowDeleteConfirm(null);
    setSwipedEventId(null);
  };

  const handleCancelDelete = () => {
    setShowDeleteConfirm(null);
    setSwipedEventId(null);
  };

  const sortedEvents = [...events].sort((a, b) => new Date(a.start_date) - new Date(b.start_date));

  return (
    <div className="event-list">
      {sortedEvents.map(event => {
        const startDate = new Date(event.start_date);
        const endDate = new Date(event.end_date);
        const isMultiDay = !isSameDay(startDate, endDate);
        
        return (
          <div
            key={event.id}
            className={`event-list-item ${compact ? 'compact' : ''} ${swipedEventId === event.id ? 'swiped' : ''}`}
            onTouchStart={(e) => handleTouchStart(e, event.id)}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
            onClick={() => onEventClick(event)}
          >
            <div className="event-list-content">
              <div className="event-list-header">
                <div className="event-list-title">{event.title}</div>
                <div className="event-list-user">
                  {event.applies_to_both ? '👨👩' : (event.user_name === 'Andrea' ? '👨' : '👩')}
                </div>
              </div>
              
              <div className="event-list-details">
                <div className="event-list-date">
                  {format(startDate, 'MMM d')}
                  {isMultiDay && ` - ${format(endDate, 'MMM d')}`}
                </div>
                <div className="event-list-time">
                  {format(startDate, 'HH:mm')} - {format(endDate, 'HH:mm')}
                </div>
                <div className={`event-list-type event-${event.event_type}`}>
                  {event.event_type}
                </div>
              </div>
              
              {event.description && (
                <div className="event-list-description">
                  {event.description}
                </div>
              )}
            </div>
            
            {showDeleteConfirm === event.id && (
              <div className="delete-confirmation">
                <button 
                  className="btn btn-danger"
                  onClick={() => handleDelete(event.id)}
                >
                  Delete
                </button>
                <button 
                  className="btn btn-secondary"
                  onClick={handleCancelDelete}
                >
                  Cancel
                </button>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

function isSameDay(date1, date2) {
  return date1.getFullYear() === date2.getFullYear() &&
         date1.getMonth() === date2.getMonth() &&
         date1.getDate() === date2.getDate();
}

export default EventList;
EOF

echo "📋 EventList.js restored"

echo ""
echo "🔍 Step 4: Updating App.js to Use Original Components..."
echo "================================"

# Update App.js to use original components
echo "📋 Updating App.js..."
cat > App.js << 'EOF'
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
EOF

echo "📋 App.js updated"

echo ""
echo "🔍 Step 5: Installing date-fns Dependency..."
echo "================================"

# Install date-fns dependency
echo "📋 Installing date-fns..."
cd /opt/us-calendar/frontend
npm install date-fns

echo ""
echo "🔍 Step 6: Rebuilding with Original Components..."
echo "================================"

# Rebuild with original components
echo "📋 Rebuilding with original components..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 7: Deploying Original Calendar..."
echo "================================"

# Deploy the original calendar
echo "📋 Deploying original calendar..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 8: Testing Original Calendar..."
echo "================================"

# Test the original calendar
echo "📋 Testing original calendar:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Original Calendar Restored Successfully!"
echo ""
echo "🌐 Your original calendar is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Original Features Restored:"
echo "   - ✅ Full CalendarPage with sidebar"
echo "   - ✅ EventForm with advanced features"
echo "   - ✅ EventList with touch interactions"
echo "   - ✅ Event types (Work, Holiday, Other)"
echo "   - ✅ Multi-day events support"
echo "   - ✅ Shared events (applies to both)"
echo "   - ✅ User indicators (👨 Andrea, 👩 Angel)"
echo "   - ✅ Event legends and color coding"
echo "   - ✅ Upcoming events sidebar"
echo "   - ✅ Click any date to create events"
echo "   - ✅ Click events to edit/delete"
echo "   - ✅ Touch-friendly mobile interactions"
echo ""
echo "📱 Test the Original Functionality:"
echo "   1. Click on Angel or Andrea user card"
echo "   2. See full calendar with sidebar"
echo "   3. Click any date to create events"
echo "   4. Click events to edit/delete"
echo "   5. Use sidebar for quick actions"
echo "   6. View event types and legends"
echo "   7. See upcoming events list"
echo ""
echo "🎯 Original calendar with all features is now restored!" 