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
    
    // Add padding days from previous/next month
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
      
      // Check if the date falls within the event's date range
      // For multi-day events, we need to check if the date is between start and end
      const dateStart = new Date(date);
      dateStart.setHours(0, 0, 0, 0);
      
      const dateEnd = new Date(date);
      dateEnd.setHours(23, 59, 59, 999);
      
      // Event spans this day if:
      // 1. Event starts on or before this day AND
      // 2. Event ends on or after this day
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
          <h1>The Amazing Angel+Andrea Calendar 🌏</h1>
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
                              title={`${event.title} - ${event.user_name}${event.applies_to_both ? ' (Us)' : ''}${isMultiDay ? ` (${format(eventStart, 'MMM d')} - ${format(eventEnd, 'MMM d')})` : ''}`}
                            >
                              <div className="event-content">
                                <span className="event-title-text">{event.title}</span>
                                <div className="event-indicators">
                                  {event.applies_to_both ? (
                                    <>
                                      <span className="event-user-indicator">👨</span>
                                      <span className="event-user-indicator">👩‍🦰</span>
                                    </>
                                  ) : (
                                    <span className="event-user-indicator">{event.user_name === 'Andrea' ? '👨' : '👩‍🦰'}</span>
                                  )}
                                </div>
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
                  <span className="legend-user-indicator">👩‍🦰</span>
                  <span>Angel's Events</span>
                </div>
                <div className="legend-item">
                  <div className="legend-both-avatars">
                    <span className="legend-user-indicator">👨</span>
                    <span className="legend-user-indicator">👩‍🦰</span>
                  </div>
                  <span>Us (Shared Events)</span>
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