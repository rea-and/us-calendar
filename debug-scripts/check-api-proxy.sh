#!/bin/bash

echo "🔍 Checking API proxy configuration..."

# Check nginx configuration
echo "📋 Nginx configuration:"
sudo cat /etc/nginx/sites-available/carlevato.net | grep -A 10 -B 5 "location /api"

# Test API proxy
echo ""
echo "🧪 Testing API proxy..."
echo "Testing https://carlevato.net/api/health:"
curl -s https://carlevato.net/api/health

echo ""
echo "Testing http://localhost:5001/api/health:"
curl -s http://localhost:5001/api/health

echo ""
echo "Testing direct backend:"
curl -s http://localhost:5001/api/users

echo ""
echo "🔍 Checking backend logs for API requests:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo ""
echo "📊 Backend service status:"
sudo systemctl status us-calendar --no-pager 