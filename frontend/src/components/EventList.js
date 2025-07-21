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
    
    // Start long press timer
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
    
    // If horizontal swipe is significant and vertical movement is minimal
    if (deltaX > 50 && deltaY < 30) {
      // Cancel long press timer
      if (longPressTimer) {
        clearTimeout(longPressTimer);
        setLongPressTimer(null);
      }
    }
  };

  const handleTouchEnd = (e, eventId) => {
    if (!touchStartX.current || !touchStartY.current) return;
    
    const touchX = e.changedTouches[0].clientX;
    const touchY = e.changedTouches[0].clientY;
    const deltaX = touchX - touchStartX.current;
    const deltaY = Math.abs(touchY - touchStartY.current);
    
    // Clear long press timer
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
    
    // Handle swipe to delete (left swipe)
    if (deltaX < -50 && deltaY < 30) {
      setSwipedEventId(eventId);
    }
    
    // Reset touch coordinates
    touchStartX.current = null;
    touchStartY.current = null;
  };

  const handleDelete = (eventId) => {
    if (onDeleteEvent) {
      onDeleteEvent(eventId);
    }
    setShowDeleteConfirm(null);
    setSwipedEventId(null);
  };

  const handleCancelDelete = () => {
    setShowDeleteConfirm(null);
    setSwipedEventId(null);
  };

  return (
    <div className={`event-list ${compact ? 'compact' : ''}`}>
      {events.map((event) => {
        const startDate = new Date(event.start_date);
        const endDate = new Date(event.end_date);
        const isSwiped = swipedEventId === event.id;
        const isDeleteConfirm = showDeleteConfirm === event.id;
        
        return (
          <div 
            key={event.id} 
            className={`event-list-item event-${event.event_type} ${isSwiped ? 'swiped' : ''} ${isDeleteConfirm ? 'delete-confirm' : ''}`}
            onClick={() => !isSwiped && !isDeleteConfirm && onEventClick && onEventClick(event)}
            onTouchStart={(e) => handleTouchStart(e, event.id)}
            onTouchMove={handleTouchMove}
            onTouchEnd={(e) => handleTouchEnd(e, event.id)}
          >
            <div className="event-list-content">
              <div className="event-list-header">
                <h4 className="event-title">{event.title}</h4>
                <div className="event-header-indicators">
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
              
              <div className="event-list-details">
                <div className="event-time">
                  <span className="event-date">
                    {format(startDate, 'MMM d, yyyy')}
                  </span>
                  <span className="event-hours">
                    {format(startDate, 'HH:mm')} - {format(endDate, 'HH:mm')}
                  </span>
                </div>
                
                {event.description && !compact && (
                  <p className="event-description">{event.description}</p>
                )}
              </div>
            </div>
            
            {/* Swipe delete overlay */}
            {isSwiped && (
              <div className="event-delete-overlay">
                <button 
                  className="btn btn-danger event-delete-btn"
                  onClick={() => handleDelete(event.id)}
                >
                  Delete
                </button>
                <button 
                  className="btn btn-secondary event-cancel-btn"
                  onClick={handleCancelDelete}
                >
                  Cancel
                </button>
              </div>
            )}
            
            {/* Long press delete confirmation */}
            {isDeleteConfirm && (
              <div className="event-delete-confirm">
                <div className="delete-confirm-content">
                  <p>Delete "{event.title}"?</p>
                  <div className="delete-confirm-actions">
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
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default EventList; 