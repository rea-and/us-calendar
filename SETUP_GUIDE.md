# Our Calendar - Setup Guide

## 🎯 Project Overview

A modern, mobile-responsive shared calendar application for couples built with:
- **Backend**: Flask (Python) with SQLite database and RESTful API
- **Frontend**: React with modern hooks, mobile-first responsive design
- **Web Server**: Apache with HTTPS (Let's Encrypt)
- **Features**: User recognition, touch interactions, enhanced UX
- **Deployment**: Production-ready at https://carlevato.net/us

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
├── debug-scripts/          # Server debugging and maintenance scripts
│   ├── switch-to-apache-https.sh    # Apache + HTTPS setup
│   ├── client-diagnostic-mac.sh     # Client-side diagnostics
│   ├── monitor-request.sh           # Real-time request monitoring
│   └── *.sh                        # Other debugging scripts
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
- Domain: carlevato.net

### 1. Upload Files
Upload the project files to your Ubuntu server.

### 2. Run Deployment Script
```bash
sudo chmod +x deploy_ubuntu.sh
sudo ./deploy_ubuntu.sh
```

This script will:
- 📦 Install system dependencies (Python3, Node.js, Apache)
- 🏗️ Build React frontend with mobile optimizations
- 🔧 Configure Apache to serve at carlevato.net/us
- 🔒 Set up HTTPS with Let's Encrypt SSL certificate
- 🚀 Create systemd service for Flask backend
- ✅ Start all services

### 3. Access Production Application
- **Production URL**: https://carlevato.net/us
- **HTTP Fallback**: http://carlevato.net/us

### 4. Server Configuration (Automatic)
The deployment script automatically configures:
- **Apache Virtual Host**: Document root at `/var/www/us-calendar/frontend/build`
- **API Proxy**: `/api/` routes to Flask backend on port 5001
- **SSL Certificate**: Let's Encrypt for carlevato.net
- **Security Headers**: HSTS, X-Content-Type-Options, X-Frame-Options
- **Static File Serving**: Proper MIME types for JavaScript and CSS
- **React Routing**: Fallback to index.html for SPA routes

## 🔧 Server Management

### Debug Scripts
The project includes comprehensive debugging and maintenance scripts:

#### Apache Switch Script
```bash
cd debug-scripts
sudo ./switch-to-apache-https.sh
```
- Removes nginx completely
- Installs and configures Apache
- Sets up HTTPS with Let's Encrypt
- Configures proper MIME types
- Updates backend CORS for production

#### Client Diagnostics (Mac)
```bash
cd debug-scripts
./client-diagnostic-mac.sh
```
- Tests network connectivity
- Validates main page loading
- Checks API responses
- Simulates browser requests
- Generates detailed diagnostic report

#### Request Monitoring
```bash
cd debug-scripts
sudo ./monitor-request.sh
```
- Real-time server monitoring
- Captures logs during requests
- Shows HTTP responses
- Monitors system resources
- Provides console summary

### Common Server Commands
```bash
# Check service status
sudo systemctl status us-calendar
sudo systemctl status apache2

# View logs
sudo journalctl -u us-calendar -f
sudo tail -f /var/log/apache2/us-calendar-error.log

# Restart services
sudo systemctl restart us-calendar
sudo systemctl restart apache2

# SSL certificate renewal
sudo certbot renew

# Update application
cd /var/www/us-calendar/frontend && npm run build
sudo systemctl restart us-calendar
```

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
- CORS configured for localhost and production HTTPS domains
- Input validation on all forms (client and server-side)
- SQL injection protection via SQLAlchemy ORM
- XSS protection via React
- CSRF protection for forms
- HTTPS enforcement with automatic redirect
- Security headers (HSTS, X-Content-Type-Options, X-Frame-Options)

### Performance
- React build optimization for production
- SQLite for simple, fast data storage
- Apache caching headers for static assets
- Responsive images and lazy loading
- Mobile-optimized bundle sizes
- Proper MIME types for JavaScript and CSS files

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
sudo systemctl status apache2

# Check logs
sudo journalctl -u us-calendar -f
sudo tail -f /var/log/apache2/us-calendar-error.log

# Test Apache configuration
sudo apache2ctl configtest

# Check SSL certificate
sudo certbot certificates
```

**Static file issues:**
```bash
# Check Apache MIME types
sudo apache2ctl -M | grep mime

# Verify file permissions
sudo chown -R www-data:www-data /var/www/us-calendar
sudo chmod -R 755 /var/www/us-calendar

# Test static file serving
curl -I http://localhost/us/static/js/main.js
```

### Mobile Testing
- **iOS Safari**: Test on iPhone/iPad
- **Android Chrome**: Test on Android devices
- **Desktop**: Test responsive design in browser dev tools
- **Touch Interactions**: Verify swipe and long-press work correctly

### Debug Scripts Usage
```bash
# Run client diagnostics (on Mac)
cd debug-scripts
./client-diagnostic-mac.sh

# Monitor server requests (on Ubuntu)
cd debug-scripts
sudo ./monitor-request.sh

# Switch to Apache (if needed)
cd debug-scripts
sudo ./switch-to-apache-https.sh
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Run the appropriate debug script for your platform
3. Verify all dependencies are installed
4. Check service logs for error messages
5. Ensure ports 3000 (dev) and 80/443 (prod) are available
6. Test mobile functionality on actual devices
7. Verify SSL certificate is valid and DNS is configured

## 🎉 Success!

Your modern, mobile-responsive shared calendar application is now ready! Enjoy managing your events together with:
- ✅ **Intuitive user recognition** with visual indicators
- ✅ **Touch-friendly mobile experience** with swipe and long-press
- ✅ **Enhanced UX** with click-to-create and auto-sync
- ✅ **Beautiful responsive design** that works on all devices
- ✅ **Secure HTTPS deployment** with Apache and Let's Encrypt
- ✅ **Comprehensive debugging tools** for troubleshooting 