from flask import request, jsonify
from app import app, db
from models import User, Event
from datetime import datetime
import dateutil.parser

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        users = User.query.all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/events', methods=['GET'])
def get_events():
    """Get all events"""
    try:
        events = Event.query.order_by(Event.start_date).all()
        return jsonify([event.to_dict() for event in events]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/events', methods=['POST'])
def create_event():
    """Create a new event"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'event_type', 'start_date', 'end_date', 'user_id']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Parse dates
        start_date = dateutil.parser.parse(data['start_date'])
        end_date = dateutil.parser.parse(data['end_date'])
        
        # Validate event type
        valid_types = ['work', 'holiday', 'other']
        if data['event_type'] not in valid_types:
            return jsonify({'error': f'Invalid event type. Must be one of: {valid_types}'}), 400
        
        # Check if user exists
        user = User.query.get(data['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Create event
        event = Event(
            title=data['title'],
            description=data.get('description', ''),
            event_type=data['event_type'],
            start_date=start_date,
            end_date=end_date,
            user_id=data['user_id'],
            applies_to_both=data.get('applies_to_both', False)
        )
        
        db.session.add(event)
        db.session.commit()
        
        return jsonify(event.to_dict()), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<int:event_id>', methods=['PUT'])
def update_event(event_id):
    """Update an existing event"""
    try:
        event = Event.query.get_or_404(event_id)
        data = request.get_json()
        
        # Update fields if provided
        if 'title' in data:
            event.title = data['title']
        if 'description' in data:
            event.description = data['description']
        if 'event_type' in data:
            if data['event_type'] not in ['work', 'holiday', 'other']:
                return jsonify({'error': 'Invalid event type'}), 400
            event.event_type = data['event_type']
        if 'start_date' in data:
            event.start_date = dateutil.parser.parse(data['start_date'])
        if 'end_date' in data:
            event.end_date = dateutil.parser.parse(data['end_date'])
        if 'user_id' in data:
            user = User.query.get(data['user_id'])
            if not user:
                return jsonify({'error': 'User not found'}), 404
            event.user_id = data['user_id']
        if 'applies_to_both' in data:
            event.applies_to_both = data['applies_to_both']
        
        db.session.commit()
        return jsonify(event.to_dict()), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
def delete_event(event_id):
    """Delete an event"""
    try:
        event = Event.query.get_or_404(event_id)
        db.session.delete(event)
        db.session.commit()
        return jsonify({'message': 'Event deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'message': 'Our Calendar API is running'}), 200 