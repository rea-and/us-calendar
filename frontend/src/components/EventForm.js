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
      // Set default values for new event with selected date
      const now = new Date();
      setFormData({
        title: '',
        description: '',
        event_type: 'work',
        start_date: format(selectedDate, 'yyyy-MM-dd'),
        start_time: '08:00',
        end_date: format(selectedDate, 'yyyy-MM-dd'),
        end_time: '09:00', // 1 hour later
        applies_to_both: false
      });
    } else {
      // Set default values for new event
      const now = new Date();
      setFormData({
        title: '',
        description: '',
        event_type: 'work',
        start_date: format(now, 'yyyy-MM-dd'),
        start_time: '08:00',
        end_date: format(now, 'yyyy-MM-dd'),
        end_time: '09:00', // 1 hour later
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

    // Check if end date/time is after start date/time
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

    // Create dates and preserve local time by adjusting for timezone offset
    const startDateTime = new Date(`${formData.start_date}T${formData.start_time}:00`);
    const endDateTime = new Date(`${formData.end_date}T${formData.end_time}:00`);
    
    // Adjust for timezone offset to preserve local time
    const timezoneOffset = startDateTime.getTimezoneOffset() * 60000;
    const startDateAdjusted = new Date(startDateTime.getTime() + timezoneOffset);
    const endDateAdjusted = new Date(endDateTime.getTime() + timezoneOffset);

    const eventData = {
      title: formData.title.trim(),
      description: formData.description.trim(),
      event_type: formData.event_type,
      start_date: startDateAdjusted.toISOString(),
      end_date: endDateAdjusted.toISOString(),
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

    // Auto-update end date when start date changes
    if (name === 'start_date') {
      const currentStartTime = formData.start_time;
      const currentEndTime = formData.end_time;
      
      // Calculate time difference between start and end
      const startDateTime = new Date(`${formData.start_date}T${currentStartTime}`);
      const endDateTime = new Date(`${formData.end_date}T${currentEndTime}`);
      const timeDifference = endDateTime.getTime() - startDateTime.getTime();
      
      // Set end date to same as start date, preserving time difference
      const newEndDateTime = new Date(`${value}T${currentStartTime}`);
      newEndDateTime.setTime(newEndDateTime.getTime() + timeDifference);
      
      setFormData(prev => ({
        ...prev,
        end_date: value,
        end_time: format(newEndDateTime, 'HH:mm')
      }));
    }

    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
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
                This event applies to us
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
                onChange={handleInputChange}
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