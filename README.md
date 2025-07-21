# Our Calendar - Shared Calendar Application

A modern, mobile-responsive shared calendar application for couples to manage their events together with intuitive user recognition and enhanced UX.

## ✨ Features

### 🗓️ Core Calendar Features
- **User profile selection** (Andrea/Angel)
- **Event management** with different types (Work, Holiday, Other)
- **Real-time calendar view** with month navigation
- **Shared events** that apply to both partners
- **Multi-day events** with visual indicators

### 👥 User Recognition
- **Visual user indicators**: 👨 for Andrea, 👩 for Angel
- **Shared event display**: Both avatars shown for shared events
- **Color-coded events**: Consistent work/holiday/other colors regardless of owner
- **User legend**: Clear explanation of indicators in sidebar

### 📱 Mobile-First Design
- **Fully responsive**: Optimized for all screen sizes
- **Touch-friendly**: Swipe-to-delete and long-press delete
- **Mobile gestures**: Intuitive touch interactions
- **Safe area support**: Works with notched devices
- **Accessibility**: High contrast and reduced motion support

### 🎯 Enhanced UX
- **Click any date**: Opens new event form with that date pre-filled
- **Auto-sync dates**: End date updates when start date changes
- **Default times**: Events start at 8:00 AM by default
- **Quick actions**: Add new events from sidebar
- **Event deletion**: Multiple ways to delete events (swipe, long-press, edit form)

### 🔧 Technical Features
- **Cross-platform compatibility** (MacOS and Ubuntu Linux)
- **Real-time updates**: Changes reflect immediately
- **Error handling**: User-friendly error messages
- **Loading states**: Smooth loading indicators
- **Form validation**: Comprehensive input validation
- **HTTPS support**: Secure connections with Let's Encrypt SSL

## 🛠️ Tech Stack

- **Backend**: Flask (Python) with RESTful API
- **Database**: SQLite with SQLAlchemy ORM
- **Frontend**: React with modern hooks and functional components
- **Styling**: CSS3 with mobile-first responsive design
- **Web Server**: Apache with HTTPS (Let's Encrypt)
- **Deployment**: Production-ready at https://carlevato.net/us

## 📁 Project Structure

```
us-calendar/
├── backend/                 # Flask backend
│   ├── app.py              # Main Flask application
│   ├── models.py           # Database models (User, Event)
│   ├── routes.py           # API routes with CRUD operations
│   └── database.db         # SQLite database
├── frontend/               # React frontend
│   ├── public/
│   │   └── index.html      # Mobile-optimized HTML
│   ├── src/
│   │   ├── components/
│   │   │   ├── EventForm.js    # Event creation/editing
│   │   │   ├── EventList.js    # Event list with delete
│   │   │   └── *.css          # Component styles
│   │   ├── pages/
│   │   │   ├── CalendarPage.js # Main calendar view
│   │   │   ├── LandingPage.js  # User selection
│   │   │   └── *.css          # Page styles
│   │   ├── App.js             # Main app component
│   │   └── index.css          # Global styles
│   └── package.json
├── debug-scripts/          # Server debugging and maintenance scripts
│   ├── switch-to-apache-https.sh    # Apache + HTTPS setup
│   ├── client-diagnostic-mac.sh     # Client-side diagnostics
│   ├── monitor-request.sh           # Real-time request monitoring
│   └── *.sh                        # Other debugging scripts
├── requirements.txt        # Python dependencies
├── start_dev.sh           # Development startup script
├── deploy_ubuntu.sh       # Ubuntu deployment script
└── README.md
```

## 🚀 Quick Start

### For MacOS Development

1. **Clone and navigate to the project:**
   ```bash
   cd us-calendar
   ```

2. **Run the development script:**
   ```bash
   chmod +x start_dev.sh
   ./start_dev.sh
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5001

### Manual Setup (Alternative)

1. **Set up Python environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Set up React frontend:**
   ```bash
   cd frontend
   npm install
   ```

3. **Run the application:**
   ```bash
   # Terminal 1 - Backend
   cd backend
   python app.py
   
   # Terminal 2 - Frontend
   cd frontend
   npm start
   ```

## 🌐 API Endpoints

### Events
- `GET /api/events` - Get all events
- `POST /api/events` - Create new event
- `PUT /api/events/<id>` - Update event
- `DELETE /api/events/<id>` - Delete event

### Users
- `GET /api/users` - Get user profiles

### Health
- `GET /api/health` - Health check endpoint

## 🗄️ Database Schema

### Users Table
- `id` (Primary Key)
- `name` (String, unique)
- `created_at` (DateTime)

### Events Table
- `id` (Primary Key)
- `title` (String, required)
- `description` (Text, optional)
- `event_type` (String: 'work', 'holiday', 'other')
- `start_date` (DateTime, required)
- `end_date` (DateTime, required)
- `user_id` (Foreign Key to Users)
- `applies_to_both` (Boolean, default: false)
- `created_at` (DateTime)

## 📱 Mobile Features

### Touch Interactions
- **Swipe left**: Delete event (reveals delete/cancel buttons)
- **Long press (500ms)**: Delete event with confirmation dialog
- **Tap events**: Edit existing events
- **Tap dates**: Create new events starting on that date

### Responsive Design
- **Breakpoints**: 360px, 480px, 768px, 1024px
- **Landscape mode**: Optimized layout for mobile landscape
- **Touch targets**: Minimum 44px for all interactive elements
- **Font sizes**: Prevents zoom on iOS (16px minimum)

## 🎨 User Interface

### Event Types & Colors
- **🟢 Work Events**: Green (#28a745)
- **🟡 Holiday Events**: Yellow (#ffc107)
- **🟣 Other Events**: Purple (#6f42c1)

### User Indicators
- **👨 Andrea's Events**: Blue border in lists
- **👩 Angel's Events**: Gray border in lists
- **👨👩 Shared Events**: Both avatars shown

### Visual Features
- **Hover effects**: Visual feedback on interactive elements
- **Loading states**: Spinners and progress indicators
- **Error messages**: Clear, user-friendly error display
- **Success feedback**: Confirmation messages for actions

## 🔧 Development Notes

### Cross-Platform Support
- **MacOS**: Full development and testing support
- **Ubuntu Linux**: Production deployment support
- **Mobile**: iOS Safari, Android Chrome, all modern browsers

### Performance Optimizations
- **Lazy loading**: Components load as needed
- **Efficient rendering**: Optimized React components
- **Database indexing**: Proper SQLite indexes
- **Caching**: Browser caching for static assets

### Security Features
- **Input validation**: Server-side and client-side validation
- **SQL injection protection**: Parameterized queries
- **XSS protection**: Proper content escaping
- **CSRF protection**: Form token validation
- **HTTPS enforcement**: Automatic HTTP to HTTPS redirect
- **Security headers**: HSTS, X-Content-Type-Options, X-Frame-Options

## 🚀 Deployment

### Ubuntu Linux Production

1. **Run deployment script:**
   ```bash
   chmod +x deploy_ubuntu.sh
   ./deploy_ubuntu.sh
   ```

2. **Switch to Apache with HTTPS:**
   ```bash
   cd debug-scripts
   chmod +x switch-to-apache-https.sh
   sudo ./switch-to-apache-https.sh
   ```

3. **Access the application:**
   - **Primary**: https://carlevato.net/us/ (HTTPS)
   - **Fallback**: http://157.230.244.80/us/ (HTTP)

### Server Configuration

#### Apache Virtual Host
- **Document Root**: `/var/www/us-calendar/frontend/build`
- **API Proxy**: `/api/` → `http://localhost:5001/api/`
- **SSL Certificate**: Let's Encrypt for carlevato.net
- **Security Headers**: HSTS, X-Content-Type-Options, X-Frame-Options

#### Static File Serving
- **JavaScript**: `application/javascript` MIME type
- **CSS**: `text/css` MIME type
- **Caching**: 1 year for static assets
- **Fallback**: index.html for React routes

#### Backend Service
- **Service**: systemd service `us-calendar`
- **Port**: 5001 (internal)
- **Database**: SQLite at `/var/www/us-calendar/backend/calendar.db`
- **CORS**: Configured for production HTTPS domains

### Environment Variables
- `FLASK_ENV`: Set to 'production' for deployment
- `DATABASE_URL`: SQLite database path
- `SECRET_KEY`: Flask secret key for sessions

### Troubleshooting

#### Debug Scripts
- **Client Diagnostics**: `debug-scripts/client-diagnostic-mac.sh` (run on Mac)
- **Request Monitoring**: `debug-scripts/monitor-request.sh` (run on server)
- **Apache Switch**: `debug-scripts/switch-to-apache-https.sh` (run on server)

#### Common Issues
- **SSL Certificate**: Ensure DNS points to server IP
- **Static Files**: Check Apache MIME type configuration
- **API Issues**: Verify backend service is running
- **CORS Errors**: Check CORS configuration in backend

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both desktop and mobile
5. Submit a pull request

## 📄 License

This project is private and proprietary. 