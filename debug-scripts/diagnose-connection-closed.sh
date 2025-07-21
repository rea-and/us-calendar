#!/bin/bash

# Diagnose ERR_CONNECTION_CLOSED errors

echo "🔍 Diagnosing ERR_CONNECTION_CLOSED Errors..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🔧 Step 1: Checking Service Status..."
echo "================================"

# Check if services are running
echo "📊 Backend service status:"
systemctl status us-calendar --no-pager -l

echo ""
echo "📊 Nginx service status:"
systemctl status nginx --no-pager -l

echo ""
echo "🔍 Step 2: Checking Port Accessibility..."
echo "================================"

# Check if ports are listening
echo "📋 Listening ports:"
netstat -tlnp | grep -E ':(80|443|5001)'

echo ""
echo "📋 Testing port connectivity:"
nc -z localhost 80 && echo "✅ Port 80 accessible from localhost" || echo "❌ Port 80 not accessible from localhost"
nc -z localhost 5001 && echo "✅ Port 5001 accessible from localhost" || echo "❌ Port 5001 not accessible from localhost"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📋 Testing external IP connectivity ($SERVER_IP):"
nc -z $SERVER_IP 80 && echo "✅ Port 80 accessible from external IP" || echo "❌ Port 80 not accessible from external IP"

echo ""
echo "🔍 Step 3: Testing HTTP Responses..."
echo "================================"

# Test HTTP responses
echo "📋 Testing localhost HTTP response:"
curl -s -o /dev/null -w "Localhost: %{http_code}, Time: %{time_total}s\n" http://localhost/us/

echo "📋 Testing external IP HTTP response:"
curl -s -o /dev/null -w "External IP: %{http_code}, Time: %{time_total}s\n" http://$SERVER_IP/us/

echo "📋 Testing domain HTTP response:"
curl -s -o /dev/null -w "Domain: %{http_code}, Time: %{time_total}s\n" http://carlevato.net/us/

echo ""
echo "🔍 Step 4: Checking Firewall Status..."
echo "================================"

# Check firewall
if command -v ufw &> /dev/null; then
    echo "📊 UFW Firewall Status:"
    ufw status
else
    echo "⚠️  UFW not installed"
fi

echo ""
echo "📊 iptables Status:"
iptables -L -n | head -20

echo ""
echo "🔍 Step 5: Checking Nginx Configuration..."
echo "================================"

# Test nginx config
echo "📋 Nginx configuration test:"
nginx -t

echo ""
echo "📋 Nginx error logs (last 10 lines):"
tail -10 /var/log/nginx/error.log

echo ""
echo "📋 Nginx access logs (last 10 lines):"
tail -10 /var/log/nginx/access.log

echo ""
echo "🔍 Step 6: Checking Backend Logs..."
echo "================================"

# Check backend logs
echo "📋 Backend service logs (last 10 lines):"
journalctl -u us-calendar --no-pager -n 10

echo ""
echo "🔍 Step 7: Testing API Endpoints..."
echo "================================"

# Test API endpoints
echo "📋 Testing API health endpoint:"
curl -s http://localhost/api/health

echo ""
echo "📋 Testing API users endpoint:"
curl -s http://localhost/api/users | head -3

echo ""
echo "🔍 Step 8: Checking Network Interfaces..."
echo "================================"

# Check network interfaces
echo "📋 Network interfaces:"
ip addr show | grep -E "inet.*scope global"

echo ""
echo "🔍 Step 9: Testing DNS Resolution..."
echo "================================"

# Test DNS
echo "📋 DNS resolution for carlevato.net:"
nslookup carlevato.net

echo ""
echo "📋 Testing ping to carlevato.net:"
ping -c 3 carlevato.net

echo ""
echo "🔍 Step 10: Checking System Resources..."
echo "================================"

# Check system resources
echo "📋 Memory usage:"
free -h

echo ""
echo "📋 Disk usage:"
df -h /

echo ""
echo "📋 CPU and load:"
uptime

echo ""
echo "🔍 Step 11: Testing from Different Perspectives..."
echo "================================"

# Test with different user agents
echo "📋 Testing with Chrome user agent:"
curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
     -o /dev/null -w "Chrome UA: %{http_code}\n" http://localhost/us/

echo "📋 Testing with Safari user agent:"
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15" \
     -o /dev/null -w "Safari UA: %{http_code}\n" http://localhost/us/

echo ""
echo "🔍 Step 12: Checking for Common Issues..."
echo "================================"

# Check for common issues
echo "📋 Checking if nginx is binding to all interfaces:"
ss -tlnp | grep nginx

echo ""
echo "📋 Checking if there are any conflicting services:"
lsof -i :80 2>/dev/null || echo "No processes found on port 80"

echo ""
echo "📋 Checking if the React app files exist:"
ls -la /var/www/us-calendar/frontend/build/

echo ""
echo "🔧 Potential Fixes for ERR_CONNECTION_CLOSED..."
echo "================================"

echo "💡 Common causes and fixes:"
echo ""
echo "1. 🔥 Firewall blocking connections:"
echo "   sudo ufw allow 80"
echo "   sudo ufw allow 443"
echo ""
echo "2. 🌐 Nginx not listening on all interfaces:"
echo "   sudo systemctl restart nginx"
echo "   sudo netstat -tlnp | grep :80"
echo ""
echo "3. 🔧 Service not running:"
echo "   sudo systemctl start us-calendar"
echo "   sudo systemctl start nginx"
echo ""
echo "4. 📊 System resources exhausted:"
echo "   Check memory and disk space above"
echo ""
echo "5. 🔍 DNS issues:"
echo "   Try accessing via IP: http://$SERVER_IP/us"
echo ""
echo "6. 🌐 Network interface issues:"
echo "   Check if eth0 is up and has correct IP"
echo ""
echo "7. 📱 Browser-specific issues:"
echo "   Try different browser or incognito mode"
echo "   Clear browser cache and cookies"
echo ""
echo "8. 🔧 Cloud provider firewall:"
echo "   Check DigitalOcean/AWS firewall rules"
echo "   Ensure port 80 is open in cloud dashboard"

echo ""
echo "✅ Diagnosis completed!"
echo ""
echo "📋 Summary:"
echo "================================"
echo "🌐 Test URLs:"
echo "   - http://localhost/us"
echo "   - http://$SERVER_IP/us"
echo "   - http://carlevato.net/us"
echo ""
echo "🔍 Next steps:"
echo "   1. Check the service status above"
echo "   2. Look for error messages in logs"
echo "   3. Try the suggested fixes"
echo "   4. Test from different networks/devices" 