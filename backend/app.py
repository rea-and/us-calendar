from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os

# Initialize Flask app
app = Flask(__name__)

# Configure CORS for React frontend
CORS(app, origins=["http://localhost:3000", "https://carlaveto.net"])

# Configure SQLite database
basedir = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'database.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize database
db = SQLAlchemy(app)

# Import routes after db initialization
from routes import *

# Create database tables
with app.app_context():
    db.create_all()
    
    # Initialize default users if they don't exist
    from models import User
    if not User.query.filter_by(name='Angel').first():
        angel = User(name='Angel')
        db.session.add(angel)
    
    if not User.query.filter_by(name='Andrea').first():
        andrea = User(name='Andrea')
        db.session.add(andrea)
    
    db.session.commit()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001) 