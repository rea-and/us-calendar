#!/bin/bash

# Diagnose connection refused errors

echo "🔍 Diagnosing Connection Refused Errors..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "🌐 Testing Local vs External Access..."
echo "================================"

# Test local access
echo "📋 Testing localhost access..."
curl -s -o /dev/null -w "Localhost: %{http_code}\n" http://localhost/us/

# Test external IP access
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📋 Testing external IP access ($SERVER_IP)..."
curl -s -o /dev/null -w "External IP: %{http_code}\n" "http://$SERVER_IP/us/"

# Test domain access
echo "📋 Testing domain access..."
curl -s -o /dev/null -w "Domain: %{http_code}\n" http://carlevato.net/us/

echo ""
echo "🔧 Checking Firewall Status..."
echo "================================"

# Check UFW status
if command -v ufw &> /dev/null; then
    echo "📊 UFW Firewall Status:"
    ufw status
    echo ""
    echo "📋 UFW Rules:"
    ufw status numbered
else
    echo "⚠️  UFW not installed"
fi

# Check iptables
echo ""
echo "📊 iptables Status:"
iptables -L -n | head -20

echo ""
echo "🔍 Checking Nginx Configuration..."
echo "================================"

# Check nginx config
echo "📋 Nginx configuration test:"
nginx -t

echo ""
echo "📋 Nginx server blocks:"
ls -la /etc/nginx/sites-available/
ls -la /etc/nginx/sites-enabled/

echo ""
echo "📋 Current nginx config for carlevato.net:"
cat /etc/nginx/sites-available/us-calendar

echo ""
echo "🌐 Checking Network Interfaces..."
echo "================================"

# Check network interfaces
echo "📋 Network interfaces:"
ip addr show

echo ""
echo "📋 Listening ports:"
netstat -tlnp | grep -E ':(80|443|5001)'

echo ""
echo "🔍 Testing Port Accessibility..."
echo "================================"

# Test if ports are accessible from localhost
echo "📋 Testing port 80 from localhost..."
nc -z localhost 80 && echo "✅ Port 80 accessible from localhost" || echo "❌ Port 80 not accessible from localhost"

echo "📋 Testing port 5001 from localhost..."
nc -z localhost 5001 && echo "✅ Port 5001 accessible from localhost" || echo "❌ Port 5001 not accessible from localhost"

# Test if ports are accessible from external IP
echo "📋 Testing port 80 from external IP..."
nc -z $SERVER_IP 80 && echo "✅ Port 80 accessible from external IP" || echo "❌ Port 80 not accessible from external IP"

echo "📋 Testing port 5001 from external IP..."
nc -z $SERVER_IP 5001 && echo "✅ Port 5001 accessible from external IP" || echo "❌ Port 5001 not accessible from external IP"

echo ""
echo "🔧 Checking Service Status..."
echo "================================"

# Check service status
echo "📊 Nginx service status:"
systemctl status nginx --no-pager -l

echo ""
echo "📊 Backend service status:"
systemctl status us-calendar --no-pager -l

echo ""
echo "📋 Checking Nginx Logs..."
echo "================================"

# Check recent nginx logs
echo "📋 Recent nginx error logs:"
tail -10 /var/log/nginx/error.log

echo ""
echo "📋 Recent nginx access logs:"
tail -10 /var/log/nginx/access.log

echo ""
echo "🔍 Testing Different User Agents..."
echo "================================"

# Test with different user agents
echo "📋 Testing with Safari user agent..."
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15" \
     -o /dev/null -w "Safari: %{http_code}\n" http://localhost/us/

echo "📋 Testing with mobile Safari user agent..."
curl -s -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1" \
     -o /dev/null -w "Mobile Safari: %{http_code}\n" http://localhost/us/

echo ""
echo "🔧 Checking DNS and Network..."
echo "================================"

# Check DNS resolution
echo "📋 DNS resolution for carlevato.net:"
nslookup carlevato.net

echo ""
echo "📋 Reverse DNS lookup:"
nslookup $SERVER_IP

echo ""
echo "🔍 Testing from Different Networks..."
echo "================================"

# Test connectivity from different perspectives
echo "📋 Testing ping to carlevato.net..."
ping -c 3 carlevato.net

echo "📋 Testing traceroute to carlevato.net..."
traceroute -m 15 carlevato.net 2>/dev/null || echo "traceroute not available"

echo ""
echo "🔧 Potential Fixes..."
echo "================================"

echo "💡 If connection refused, try these fixes:"
echo ""
echo "1. 🔥 Check firewall:"
echo "   sudo ufw status"
echo "   sudo ufw allow 80"
echo "   sudo ufw allow 443"
echo ""
echo "2. 🌐 Check nginx binding:"
echo "   sudo netstat -tlnp | grep :80"
echo "   sudo systemctl restart nginx"
echo ""
echo "3. 🔍 Check if nginx is listening on all interfaces:"
echo "   sudo grep -r 'listen' /etc/nginx/sites-available/"
echo ""
echo "4. 📱 Test with different devices/networks:"
echo "   - Try from mobile data (not WiFi)"
echo "   - Try from different WiFi network"
echo "   - Try from different browser"
echo ""
echo "5. 🔧 Check cloud provider firewall:"
echo "   - DigitalOcean: Check firewall rules in dashboard"
echo "   - AWS: Check security groups"
echo "   - Google Cloud: Check firewall rules"
echo ""
echo "6. 📊 Check server resources:"
echo "   free -h"
echo "   df -h"
echo "   top -n 1"

echo ""
echo "✅ Diagnosis completed!"
echo ""
echo "📋 Summary of findings will help identify the connection issue." 