#!/bin/bash

echo "🔧 Quick fix for port conflict..."

# Stop the service first
sudo systemctl stop us-calendar

# Kill any remaining processes on port 5001
sudo pkill -f "python.*app.py" || true
sudo pkill -f "flask" || true

# Wait
sleep 2

# Pull latest changes
cd /opt/us-calendar
git pull origin main

# Start the service
sudo systemctl start us-calendar

# Check status
sudo systemctl status us-calendar --no-pager

echo "✅ Done! Now test creating an event as Angel." 