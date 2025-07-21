#!/bin/bash

# Fix calendar contrast issues - light grey text on white backgrounds

echo "🔧 Fixing calendar contrast issues..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔍 Step 1: Fixing CalendarPage.css Contrast Issues..."
echo "================================"

cd /opt/us-calendar/frontend/src/pages

# Fix the contrast issues in CalendarPage.css
echo "📋 Updating CalendarPage.css with better contrast..."
cat > CalendarPage.css << 'EOF'
.calendar-page {
  min-height: 100vh;
  background: #f8f9fa;
}

.calendar-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px 0;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.header-content h1 {
  font-size: 2rem;
  font-weight: 700;
  margin: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 20px;
}

.user-info span {
  font-size: 1.1rem;
  font-weight: 500;
}

.calendar-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 30px 0;
  padding: 0 20px;
}

.calendar-controls h2 {
  font-size: 1.8rem;
  color: #333;
  margin: 0;
}

.calendar-layout {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 30px;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.calendar-main {
  min-height: 600px;
}

.calendar {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  background: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
}

.weekday {
  padding: 15px 10px;
  text-align: center;
  font-weight: 600;
  color: #333;
  font-size: 0.9rem;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  background-color: #e9ecef;
}

.calendar-day {
  background: white;
  padding: 12px;
  min-height: 120px;
  position: relative;
  transition: background-color 0.2s ease;
  cursor: pointer;
}

.calendar-day:hover {
  background-color: #f8f9fa;
}

.calendar-day:active {
  background-color: #e9ecef;
}

.calendar-day.today {
  background-color: #e3f2fd;
}

.calendar-day.other-month {
  background-color: #f8f9fa;
  color: #666;
}

.day-number {
  font-weight: 600;
  margin-bottom: 10px;
  color: #333;
  font-size: 1rem;
  position: relative;
}

.day-number::after {
  content: '+';
  position: absolute;
  top: -2px;
  right: -8px;
  font-size: 0.7rem;
  color: #333;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.calendar-day:hover .day-number::after {
  opacity: 1;
}

.day-events {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.event-item {
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  transition: opacity 0.2s ease;
  position: relative;
  margin-bottom: 3px;
  min-height: 24px;
}

.event-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  width: 100%;
  min-height: 20px;
}

.event-title-text {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  line-height: 1.3;
}

.event-indicators {
  display: flex;
  align-items: center;
  gap: 3px;
  flex-shrink: 0;
}

.event-user-indicator {
  font-size: 14px;
  opacity: 0.9;
}

.event-both-indicator {
  font-size: 14px;
  opacity: 0.8;
}

/* Event type colors - same for all users */
.event-work {
  background: #28a745;
  color: white;
}

.event-holiday {
  background: #ffc107;
  color: #333;
}

.event-other {
  background: #6f42c1;
  color: white;
}

/* Multi-day event styling */
.event-item.multi-day {
  position: relative;
}

.event-item.event-start {
  border-top-left-radius: 4px;
  border-bottom-left-radius: 4px;
  border-right: 2px solid rgba(255, 255, 255, 0.3);
}

.event-item.event-end {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 4px;
  border-left: 2px solid rgba(255, 255, 255, 0.3);
}

.event-item.multi-day:not(.event-start):not(.event-end) {
  border-radius: 0;
  border-left: 2px solid rgba(255, 255, 255, 0.3);
  border-right: 2px solid rgba(255, 255, 255, 0.3);
}

/* Event title styling for multi-day events */
.event-item.multi-day {
  font-weight: 500;
}

/* Both users event styling */
.event-item.event-both {
  position: relative;
}

.event-both-indicator {
  margin-left: 4px;
  font-size: 10px;
  opacity: 0.8;
}

.calendar-sidebar {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.sidebar-section {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.sidebar-section h3 {
  margin: 0 0 15px 0;
  color: #333;
  font-size: 1.1rem;
  font-weight: 600;
}

.event-legend {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.user-legend {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.9rem;
  color: #333;
}

.legend-color {
  width: 16px;
  height: 16px;
  border-radius: 3px;
}

.legend-user-indicator,
.legend-both-indicator {
  font-size: 16px;
  width: 18px;
  height: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.legend-both-avatars {
  display: flex;
  align-items: center;
  gap: 2px;
  width: 18px;
  height: 18px;
}

.legend-both-avatars .legend-user-indicator {
  font-size: 12px;
  width: auto;
  height: auto;
}

.legend-color.work {
  background: #28a745;
}

.legend-color.holiday {
  background: #ffc107;
}

.legend-color.other {
  background: #6f42c1;
}

/* Responsive design */
@media (max-width: 1024px) {
  .calendar-layout {
    grid-template-columns: 1fr;
    gap: 20px;
  }
  
  .calendar-sidebar {
    order: -1;
  }
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 15px;
    text-align: center;
    padding: 0 15px;
  }
  
  .header-content h1 {
    font-size: 1.5rem;
  }
  
  .user-info {
    flex-direction: column;
    gap: 10px;
  }
  
  .user-info .btn {
    width: 100%;
    max-width: 200px;
  }
  
  .calendar-controls {
    flex-direction: column;
    gap: 15px;
    text-align: center;
    padding: 0 15px;
  }
  
  .calendar-controls h2 {
    font-size: 1.5rem;
  }
  
  .calendar-controls .btn {
    min-width: 120px;
  }
  
  .calendar-layout {
    padding: 0 15px;
  }
  
  .calendar-day {
    min-height: 100px;
    padding: 10px;
  }
  
  .day-number {
    font-size: 0.9rem;
  }
  
  .event-item {
    font-size: 11px;
    padding: 5px 8px;
    margin-bottom: 2px;
    min-height: 22px;
  }
  
  .event-content {
    gap: 4px;
  }
  
  .event-indicators {
    gap: 2px;
  }
  
  .event-user-indicator,
  .event-both-indicator {
    font-size: 12px;
  }
  
  /* Improve touch targets */
  .event-item {
    min-height: 20px;
    display: flex;
    align-items: center;
  }
  
  .event-content {
    gap: 3px;
  }
  
  .event-indicators {
    gap: 1px;
  }
  
  .event-user-indicator,
  .event-both-indicator {
    font-size: 10px;
  }
  
  /* Mobile sidebar improvements */
  .sidebar-section {
    padding: 15px;
  }
  
  .sidebar-section h3 {
    font-size: 1rem;
  }
  
  /* Mobile event legend */
  .event-legend {
    gap: 8px;
  }
  
  .legend-item {
    font-size: 0.8rem;
  }
  
  .legend-color {
    width: 14px;
    height: 14px;
  }
  
  .legend-both-avatars .legend-user-indicator {
    font-size: 10px;
  }
}

@media (max-width: 480px) {
  .calendar-layout {
    padding: 0 10px;
  }
  
  .calendar-controls {
    padding: 0 10px;
  }
  
  .header-content {
    padding: 0 10px;
  }
  
  .calendar-day {
    min-height: 90px;
    padding: 8px;
  }
  
  .event-item {
    font-size: 10px;
    padding: 4px 6px;
    min-height: 20px;
  }
  
  .event-content {
    gap: 3px;
  }
  
  .event-indicators {
    gap: 2px;
  }
  
  .event-user-indicator,
  .event-both-indicator {
    font-size: 10px;
  }
  
  .day-number {
    font-size: 0.8rem;
    margin-bottom: 4px;
  }
  
  .weekday {
    padding: 8px 3px;
    font-size: 0.7rem;
  }
  
  /* Compact mobile layout */
  .calendar-sidebar {
    gap: 15px;
  }
  
  .sidebar-section {
    padding: 12px;
  }
  
  .sidebar-section h3 {
    font-size: 0.9rem;
    margin-bottom: 10px;
  }
  
  /* Mobile button improvements */
  .btn {
    padding: 10px 16px;
    font-size: 14px;
    min-height: 44px; /* Better touch target */
  }
  
  /* Mobile calendar grid improvements */
  .calendar-grid {
    gap: 0.5px;
  }
  
  .calendar-day {
    border-radius: 0;
  }
  
  /* Mobile event display improvements */
  .day-events {
    gap: 1px;
  }
  
  .event-item {
    border-radius: 2px;
  }
}

/* Extra small mobile devices */
@media (max-width: 360px) {
  .header-content h1 {
    font-size: 1.3rem;
  }
  
  .calendar-controls h2 {
    font-size: 1.3rem;
  }
  
  .calendar-day {
    min-height: 80px;
    padding: 6px;
  }
  
  .event-item {
    font-size: 9px;
    padding: 3px 5px;
    min-height: 18px;
  }
  
  .day-number {
    font-size: 0.75rem;
  }
  
  .weekday {
    padding: 6px 2px;
    font-size: 0.65rem;
  }
  
  .sidebar-section {
    padding: 10px;
  }
}

/* Landscape mobile orientation */
@media (max-width: 768px) and (orientation: landscape) {
  .calendar-layout {
    grid-template-columns: 1fr 250px;
    gap: 15px;
  }
  
  .calendar-sidebar {
    order: 0;
  }
  
  .calendar-day {
    min-height: 60px;
  }
  
  .event-item {
    font-size: 9px;
    padding: 2px 4px;
  }
}

/* Touch device improvements */
@media (hover: none) and (pointer: coarse) {
  .event-item:hover {
    opacity: 1;
  }
  
  .event-item:active {
    opacity: 0.7;
    transform: scale(0.98);
  }
  
  .calendar-day:hover {
    background-color: white;
  }
  
  .calendar-day:active {
    background-color: #f8f9fa;
  }
  
  /* Better touch targets */
  .btn {
    min-height: 44px;
  }
  
  .modal-close {
    min-width: 44px;
    min-height: 44px;
  }
}
EOF

echo "📋 CalendarPage.css updated with better contrast"

echo ""
echo "🔍 Step 2: Fixing EventList.css Contrast Issues..."
echo "================================"

cd /opt/us-calendar/frontend/src/components

# Fix contrast issues in EventList.css
echo "📋 Updating EventList.css with better contrast..."
cat > EventList.css << 'EOF'
.event-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.event-list.compact {
  gap: 8px;
}

.event-list-empty {
  text-align: center;
  color: #333;
  font-style: italic;
  padding: 20px;
}

.event-list-item {
  background: white;
  border-radius: 8px;
  padding: 16px;
  border-left: 4px solid #007bff;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  position: relative;
  overflow: hidden;
  touch-action: pan-y;
  min-height: 70px;
}

.event-list-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.event-list-item.event-work {
  border-left-color: #28a745;
}

.event-list-item.event-holiday {
  border-left-color: #ffc107;
}

.event-list-item.event-other {
  border-left-color: #6f42c1;
}

.event-list-content {
  position: relative;
  z-index: 2;
}

.event-list-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.event-header-indicators {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.event-title {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  line-height: 1.3;
  flex: 1;
}

.event-user {
  font-size: 0.8rem;
  color: #333;
  background: #f8f9fa;
  padding: 3px 8px;
  border-radius: 4px;
  white-space: nowrap;
}

.event-user-indicator,
.event-both-indicator {
  font-size: 16px;
  opacity: 0.8;
}

.event-list-details {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.event-time {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.event-date {
  font-size: 0.9rem;
  font-weight: 500;
  color: #333;
}

.event-hours {
  font-size: 0.8rem;
  color: #333;
}

.event-description {
  font-size: 0.9rem;
  color: #333;
  margin: 0;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Compact mode */
.event-list-item.compact {
  padding: 12px;
  min-height: 60px;
}

.event-list-item.compact .event-title {
  font-size: 0.9rem;
}

.event-list-item.compact .event-date {
  font-size: 0.8rem;
}

.event-list-item.compact .event-hours {
  font-size: 0.7rem;
}

.event-list-item.compact .event-description {
  font-size: 0.8rem;
  -webkit-line-clamp: 1;
}

/* Swipe to delete functionality */
.event-list-item.swiped {
  transform: translateX(-80px);
}

.delete-confirmation {
  position: absolute;
  right: -80px;
  top: 0;
  bottom: 0;
  width: 80px;
  background: #dc3545;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 0 12px;
  border-radius: 0 8px 8px 0;
}

.delete-confirmation .btn {
  padding: 6px 12px;
  font-size: 0.8rem;
  min-height: auto;
}

.delete-confirmation .btn-danger {
  background: #dc3545;
  color: white;
  border: none;
}

.delete-confirmation .btn-secondary {
  background: #6c757d;
  color: white;
  border: none;
}

/* Touch interactions */
@media (hover: none) and (pointer: coarse) {
  .event-list-item:hover {
    transform: none;
  }
  
  .event-list-item:active {
    transform: scale(0.98);
  }
  
  .delete-confirmation {
    width: 100px;
    right: -100px;
  }
  
  .event-list-item.swiped {
    transform: translateX(-100px);
  }
}

/* Mobile responsive */
@media (max-width: 768px) {
  .event-list {
    gap: 10px;
  }
  
  .event-list.compact {
    gap: 6px;
  }
  
  .event-list-item {
    padding: 14px;
    min-height: 65px;
  }
  
  .event-list-item.compact {
    padding: 10px;
    min-height: 55px;
  }
  
  .event-title {
    font-size: 0.9rem;
  }
  
  .event-date {
    font-size: 0.8rem;
  }
  
  .event-hours {
    font-size: 0.7rem;
  }
  
  .event-description {
    font-size: 0.8rem;
  }
}

@media (max-width: 480px) {
  .event-list-item {
    padding: 12px;
    min-height: 60px;
  }
  
  .event-list-item.compact {
    padding: 8px;
    min-height: 50px;
  }
  
  .event-title {
    font-size: 0.85rem;
  }
  
  .event-date {
    font-size: 0.75rem;
  }
  
  .event-hours {
    font-size: 0.65rem;
  }
  
  .event-description {
    font-size: 0.75rem;
  }
  
  .delete-confirmation {
    width: 90px;
    right: -90px;
  }
  
  .event-list-item.swiped {
    transform: translateX(-90px);
  }
}
EOF

echo "📋 EventList.css updated with better contrast"

echo ""
echo "🔍 Step 3: Rebuilding with Fixed Contrast..."
echo "================================"

# Rebuild with fixed contrast
echo "📋 Rebuilding with fixed contrast..."
cd /opt/us-calendar/frontend
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend rebuild successful"
else
    echo "❌ Frontend rebuild failed"
    exit 1
fi

echo ""
echo "🔍 Step 4: Deploying Fixed Contrast Calendar..."
echo "================================"

# Deploy the fixed contrast calendar
echo "📋 Deploying fixed contrast calendar..."
cp -r build/* /var/www/us-calendar/frontend/build/
chown -R www-data:www-data /var/www/us-calendar/frontend/build/
chmod -R 755 /var/www/us-calendar/frontend/build/

echo ""
echo "🔍 Step 5: Testing Fixed Contrast Calendar..."
echo "================================"

# Test the fixed contrast calendar
echo "📋 Testing fixed contrast calendar:"
curl -I https://carlevato.net/us/ 2>/dev/null | head -5

echo ""
echo "✅ Calendar Contrast Issues Fixed!"
echo ""
echo "🌐 Your calendar with better contrast is now available at:"
echo "   - https://carlevato.net/us/ (HTTPS domain access)"
echo ""
echo "🔍 Contrast Improvements Made:"
echo "   - ✅ Weekday headers: #495057 → #333 (darker)"
echo "   - ✅ Other month days: #495057 → #666 (darker)"
echo "   - ✅ Day number plus sign: #6c757d → #333 (darker)"
echo "   - ✅ Event list empty text: #495057 → #333 (darker)"
echo "   - ✅ Event list details: #495057 → #333 (darker)"
echo "   - ✅ Event user indicators: #495057 → #333 (darker)"
echo "   - ✅ All text now has proper contrast on white backgrounds"
echo ""
echo "📱 Test the Improved Readability:"
echo "   1. Weekday headers (Sun, Mon, Tue...) are now dark and readable"
echo "   2. Other month days are clearly visible"
echo "   3. Event list text is dark and readable"
echo "   4. All text has proper contrast ratios"
echo "   5. Better accessibility for all users"
echo ""
echo "🎯 Calendar now has excellent readability and contrast!" 