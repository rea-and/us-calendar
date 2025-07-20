# Our Calendar - Setup Guide

## 🎯 Project Overview

A modern, mobile-responsive shared calendar application for couples built with:
- **Backend**: Flask (Python) with SQLite database and RESTful API
- **Frontend**: React with modern hooks, mobile-first responsive design
- **Features**: User recognition, touch interactions, enhanced UX
- **Deployment**: Accessible at carlaveto.net/us

## 📁 Project Structure

```
us-calendar/
├── backend/                 # Flask backend
│   ├── app.py              # Main Flask application
│   ├── models.py           # Database models (User, Event)
│   ├── routes.py           # API endpoints with CRUD operations
│   └── database.db         # SQLite database (auto-created)
├── frontend/               # React frontend
│   ├── public/
│   │   ├── index.html      # Mobile-optimized HTML with viewport settings
│   │   └── manifest.json   # Web app manifest
│   ├── src/
│   │   ├── components/     # Reusable components
│   │   │   ├── EventForm.js    # Event creation/editing with auto-sync
│   │   │   ├── EventForm.css   # Mobile-responsive form styles
│   │   │   ├── EventList.js    # Event list with swipe/long-press delete
│   │   │   └── EventList.css   # Touch-friendly list styles
│   │   ├── pages/          # Page components
│   │   │   ├── LandingPage.js  # User selection with touch support
│   │   │   ├── LandingPage.css # Mobile-responsive landing styles
│   │   │   ├── CalendarPage.js # Main calendar with click-to-create
│   │   │   └── CalendarPage.css # Mobile-first calendar styles
│   │   ├── App.js          # Main app component
│   │   ├── App.css         # App styles with mobile support
│   │   ├── index.js        # React entry point
│   │   └── index.css       # Global styles with accessibility
│   └── package.json        # Node.js dependencies
├── requirements.txt        # Python dependencies
├── start_dev.sh           # Development startup script
├── deploy_ubuntu.sh       # Ubuntu deployment script
├── README.md              # Comprehensive project documentation
└── .gitignore             # Git ignore rules
```

## 🚀 Quick Start (MacOS Development)

### Prerequisites
- Python 3.7+
- Node.js 14+
- npm

### 1. Clone and Setup
```bash
cd us-calendar
chmod +x start_dev.sh
```

### 2. Start Development Environment
```bash
./start_dev.sh
```

This script will:
- ✅ Check dependencies (Python3, Node.js, npm)
- 📦 Create Python virtual environment
- 🔧 Install Python dependencies
- ⚛️ Install Node.js dependencies
- 🌐 Start Flask backend (port 5001)
- 📱 Start React frontend (port 3000)

### 3. Access the Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5001

## 🐧 Ubuntu Linux Deployment

### Prerequisites
- Ubuntu 20.04+ with root/sudo access
- Domain: carlaveto.net

### 1. Upload Files
Upload the project files to your Ubuntu server.

### 2. Run Deployment Script
```bash
sudo chmod +x deploy_ubuntu.sh
sudo ./deploy_ubuntu.sh
```

This script will:
- 📦 Install system dependencies (Python3, Node.js, Nginx)
- 🏗️ Build React frontend with mobile optimizations
- 🔧 Configure Nginx to serve at carlaveto.net/us
- 🚀 Create systemd service for Flask backend
- ✅ Start all services

### 3. Access Production Application
- **Production URL**: https://carlaveto.net/us

## 📱 Features

### 👥 User Recognition
- **Visual Indicators**: 👨 for Andrea, 👩 for Angel
- **Shared Events**: Both avatars shown (👨👩) for shared events
- **Color Consistency**: Same event type colors regardless of owner
- **User Legend**: Clear explanation in sidebar

### 🗓️ Event Management
- **Event Types**: Work (🟢), Holiday (🟡), Other (🟣)
- **Full CRUD Operations**: Create, Read, Update, Delete events
- **Date/Time Support**: Start and end dates with 8:00 AM default
- **Shared Events**: Events that apply to both partners
- **Multi-day Events**: Visual indicators for spanning events

### 🎯 Enhanced UX
- **Click Any Date**: Opens new event form with that date pre-filled
- **Auto-sync Dates**: End date updates when start date changes
- **Default Times**: Events start at 8:00 AM by default
- **Quick Actions**: Add new events from sidebar
- **Multiple Delete Methods**: Swipe, long-press, edit form

### 📱 Mobile-First Design
- **Touch Interactions**: Swipe-to-delete, long-press delete
- **Responsive Design**: Optimized for all screen sizes (360px+)
- **Safe Area Support**: Works with notched devices
- **Accessibility**: High contrast, reduced motion support
- **Touch Targets**: Minimum 44px for all interactive elements

### 🗓️ Calendar Interface
- **Monthly View**: Navigate between months
- **Event Display**: Events shown with type colors and user indicators
- **Clickable Dates**: Click any date to create new events
- **Real-time Updates**: Changes reflect immediately
- **Mobile Optimized**: Touch-friendly on all devices

### 🌐 API Endpoints
- `GET /api/users` - Get all users
- `GET /api/events` - Get all events
- `POST /api/events` - Create new event
- `PUT /api/events/<id>` - Update event
- `DELETE /api/events/<id>` - Delete event
- `GET /api/health` - Health check

## 🔧 Development Commands

### Backend (Flask)
```bash
cd backend
source ../venv/bin/activate
python app.py
```

### Frontend (React)
```bash
cd frontend
npm install
npm start
```

### Database
The SQLite database is automatically created at `backend/database.db` with:
- **Users table**: id, name, created_at
- **Events table**: id, title, description, event_type, start_date, end_date, user_id, applies_to_both, created_at

## 🎨 UI/UX Features

### Design System
- **Color Scheme**: Purple gradient theme (#667eea to #764ba2)
- **Event Colors**: 
  - Work: Green (#28a745)
  - Holiday: Yellow (#ffc107)
  - Other: Purple (#6f42c1)
- **Typography**: System fonts for optimal performance
- **Mobile-First**: Responsive design with touch optimization

### Components
- **Landing Page**: User selection with beautiful cards and touch support
- **Calendar View**: Monthly grid with clickable dates and event indicators
- **Event Form**: Modal with validation and auto-sync functionality
- **Event List**: Sidebar with upcoming events and delete interactions
- **Navigation**: Month navigation and user controls

### Mobile Interactions
- **Swipe Left**: Delete event (reveals delete/cancel buttons)
- **Long Press (500ms)**: Delete event with confirmation dialog
- **Tap Events**: Edit existing events
- **Tap Dates**: Create new events starting on that date
- **Touch Feedback**: Visual feedback for all interactions

## 🔒 Security & Performance

### Security
- CORS configured for localhost and production domain
- Input validation on all forms (client and server-side)
- SQL injection protection via SQLAlchemy ORM
- XSS protection via React
- CSRF protection for forms

### Performance
- React build optimization for production
- SQLite for simple, fast data storage
- Nginx caching headers
- Responsive images and lazy loading
- Mobile-optimized bundle sizes

### Accessibility
- High contrast mode support
- Reduced motion preferences
- Proper ARIA labels
- Keyboard navigation support
- Screen reader compatibility

## 🛠️ Troubleshooting

### Common Issues

**Backend won't start:**
```bash
cd backend
source ../venv/bin/activate
pip install -r ../requirements.txt
python app.py
```

**Frontend won't start:**
```bash
cd frontend
npm install
npm start
```

**Database issues:**
```bash
# Remove and recreate database
rm backend/database.db
cd backend
python -c "from app import app, db; app.app_context().push(); db.create_all()"
```

**Mobile responsiveness issues:**
```bash
# Check viewport settings in public/index.html
# Verify CSS media queries are working
# Test on actual mobile devices
```

**Production deployment issues:**
```bash
# Check service status
sudo systemctl status us-calendar
sudo systemctl status nginx

# Check logs
sudo journalctl -u us-calendar -f
sudo tail -f /var/log/nginx/error.log
```

### Mobile Testing
- **iOS Safari**: Test on iPhone/iPad
- **Android Chrome**: Test on Android devices
- **Desktop**: Test responsive design in browser dev tools
- **Touch Interactions**: Verify swipe and long-press work correctly

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify all dependencies are installed
3. Check service logs for error messages
4. Ensure ports 3000 (dev) and 80/443 (prod) are available
5. Test mobile functionality on actual devices

## 🎉 Success!

Your modern, mobile-responsive shared calendar application is now ready! Enjoy managing your events together with:
- ✅ **Intuitive user recognition** with visual indicators
- ✅ **Touch-friendly mobile experience** with swipe and long-press
- ✅ **Enhanced UX** with click-to-create and auto-sync
- ✅ **Beautiful responsive design** that works on all devices 