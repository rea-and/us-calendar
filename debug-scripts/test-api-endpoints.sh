#!/bin/bash

echo "🧪 Testing API endpoints..."

# Test different API URLs
echo "🔍 Testing different API URLs:"

echo ""
echo "1. Testing http://localhost:5001/api/health:"
curl -s http://localhost:5001/api/health

echo ""
echo "2. Testing http://localhost:5001/health:"
curl -s http://localhost:5001/health

echo ""
echo "3. Testing http://localhost:5001/api/users:"
curl -s http://localhost:5001/api/users

echo ""
echo "4. Testing http://localhost:5001/users:"
curl -s http://localhost:5001/users

echo ""
echo "5. Testing http://localhost:5001/api/events:"
curl -s http://localhost:5001/api/events

echo ""
echo "6. Testing http://localhost:5001/events:"
curl -s http://localhost:5001/events

echo ""
echo "7. Testing http://localhost:5001/ (root):"
curl -s http://localhost:5001/

echo ""
echo "🔍 Checking what's running on port 5001:"
lsof -i:5001

echo ""
echo "📋 Recent service logs:"
sudo journalctl -u us-calendar -n 10 --no-pager

echo ""
echo "✅ API endpoint testing completed!" 