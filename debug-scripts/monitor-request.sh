#!/bin/bash

# Comprehensive real-time request monitoring script

echo "🔍 Real-Time Request Monitoring Script"
echo "======================================"
echo ""
echo "📋 This script will monitor your server while you make a browser request."
echo "🌐 Please open http://157.230.244.80/us/ in your browser when prompted."
echo ""
echo "📊 Monitoring will capture:"
echo "   - Network connections and requests"
echo "   - Nginx access and error logs"
echo "   - Backend service logs"
echo "   - System resources"
echo "   - HTTP responses and headers"
echo "   - Browser user agents and requests"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

# Create monitoring directory
MONITOR_DIR="/tmp/request-monitor-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$MONITOR_DIR"

echo "📁 Monitoring data will be saved to: $MONITOR_DIR"
echo ""

# Function to capture current state
capture_state() {
    echo "=== $(date) ===" >> "$MONITOR_DIR/system-state.log"
    
    # System resources
    echo "--- System Resources ---" >> "$MONITOR_DIR/system-state.log"
    free -h >> "$MONITOR_DIR/system-state.log" 2>&1
    df -h / >> "$MONITOR_DIR/system-state.log" 2>&1
    uptime >> "$MONITOR_DIR/system-state.log" 2>&1
    
    # Service status
    echo "--- Service Status ---" >> "$MONITOR_DIR/system-state.log"
    systemctl status nginx --no-pager >> "$MONITOR_DIR/system-state.log" 2>&1
    systemctl status us-calendar --no-pager >> "$MONITOR_DIR/system-state.log" 2>&1
    
    # Network connections
    echo "--- Network Connections ---" >> "$MONITOR_DIR/system-state.log"
    netstat -tlnp | grep -E ':(80|443|5001)' >> "$MONITOR_DIR/system-state.log" 2>&1
    ss -tlnp | grep -E ':(80|443|5001)' >> "$MONITOR_DIR/system-state.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/system-state.log"
}

# Function to test HTTP responses
test_http_responses() {
    echo "=== HTTP Response Test $(date) ===" >> "$MONITOR_DIR/http-tests.log"
    
    # Test main page
    echo "--- Testing /us/ ---" >> "$MONITOR_DIR/http-tests.log"
    curl -v -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         http://localhost/us/ >> "$MONITOR_DIR/http-tests.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/http-tests.log"
    
    # Test API
    echo "--- Testing /api/users ---" >> "$MONITOR_DIR/http-tests.log"
    curl -v -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         http://localhost/api/users >> "$MONITOR_DIR/http-tests.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/http-tests.log"
    
    # Test static files
    echo "--- Testing static files ---" >> "$MONITOR_DIR/http-tests.log"
    JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
    if [ -n "$JS_FILE" ]; then
        JS_FILENAME=$(basename "$JS_FILE")
        curl -v -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
             "http://localhost/us/static/js/$JS_FILENAME" >> "$MONITOR_DIR/http-tests.log" 2>&1
    fi
    
    echo "" >> "$MONITOR_DIR/http-tests.log"
}

# Function to capture logs
capture_logs() {
    # Nginx access logs
    tail -n 50 /var/log/nginx/access.log > "$MONITOR_DIR/nginx-access.log"
    
    # Nginx error logs
    tail -n 50 /var/log/nginx/error.log > "$MONITOR_DIR/nginx-error.log"
    
    # Backend logs
    journalctl -u us-calendar --no-pager -n 50 > "$MONITOR_DIR/backend.log"
}

# Function to monitor network activity
monitor_network() {
    echo "=== Network Activity $(date) ===" >> "$MONITOR_DIR/network.log"
    
    # Active connections
    netstat -tuln | grep -E ':(80|443|5001)' >> "$MONITOR_DIR/network.log" 2>&1
    
    # Established connections
    ss -tuln | grep -E ':(80|443|5001)' >> "$MONITOR_DIR/network.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/network.log"
}

# Function to check React app files
check_react_files() {
    echo "=== React App Files $(date) ===" >> "$MONITOR_DIR/react-files.log"
    
    # Check build directory
    ls -la /var/www/us-calendar/frontend/build/ >> "$MONITOR_DIR/react-files.log" 2>&1
    
    # Check static files
    echo "--- Static JS Files ---" >> "$MONITOR_DIR/react-files.log"
    ls -la /var/www/us-calendar/frontend/build/static/js/ >> "$MONITOR_DIR/react-files.log" 2>&1
    
    echo "--- Static CSS Files ---" >> "$MONITOR_DIR/react-files.log"
    ls -la /var/www/us-calendar/frontend/build/static/css/ >> "$MONITOR_DIR/react-files.log" 2>&1
    
    # Check file permissions
    echo "--- File Permissions ---" >> "$MONITOR_DIR/react-files.log"
    find /var/www/us-calendar/frontend/build/ -type f -exec ls -la {} \; >> "$MONITOR_DIR/react-files.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/react-files.log"
}

# Function to test CORS
test_cors() {
    echo "=== CORS Test $(date) ===" >> "$MONITOR_DIR/cors-test.log"
    
    # Test with different origins
    curl -v -H "Origin: http://157.230.244.80" \
         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         http://localhost/api/users >> "$MONITOR_DIR/cors-test.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/cors-test.log"
    
    curl -v -H "Origin: http://carlevato.net" \
         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         http://localhost/api/users >> "$MONITOR_DIR/cors-test.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/cors-test.log"
}

# Function to check nginx configuration
check_nginx_config() {
    echo "=== Nginx Configuration $(date) ===" >> "$MONITOR_DIR/nginx-config.log"
    
    # Test nginx config
    nginx -t >> "$MONITOR_DIR/nginx-config.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/nginx-config.log"
    
    # Show current config
    cat /etc/nginx/sites-available/us-calendar >> "$MONITOR_DIR/nginx-config.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/nginx-config.log"
}

# Function to check backend configuration
check_backend_config() {
    echo "=== Backend Configuration $(date) ===" >> "$MONITOR_DIR/backend-config.log"
    
    # Show app.py content
    cat /var/www/us-calendar/backend/app.py >> "$MONITOR_DIR/backend-config.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/backend-config.log"
    
    # Check database
    echo "--- Database Check ---" >> "$MONITOR_DIR/backend-config.log"
    ls -la /var/www/us-calendar/backend/ >> "$MONITOR_DIR/backend-config.log" 2>&1
    
    echo "" >> "$MONITOR_DIR/backend-config.log"
}

# Initial state capture
echo "📊 Capturing initial system state..."
capture_state
capture_logs
check_react_files
check_nginx_config
check_backend_config

echo ""
echo "🔄 Starting real-time monitoring..."
echo "📱 Please open http://157.230.244.80/us/ in your browser NOW"
echo "⏱️  Monitoring for 30 seconds..."
echo ""

# Real-time monitoring loop
for i in {1..30}; do
    echo -n "."
    
    # Capture state every 5 seconds
    if [ $((i % 5)) -eq 0 ]; then
        capture_state
        monitor_network
        test_http_responses
        test_cors
    fi
    
    sleep 1
done

echo ""
echo ""

# Final capture
echo "📊 Capturing final state..."
capture_state
capture_logs

# Generate summary report
echo "📋 Generating summary report..."
cat > "$MONITOR_DIR/summary-report.txt" << EOF
REAL-TIME REQUEST MONITORING SUMMARY
====================================
Date: $(date)
Monitoring Duration: 30 seconds
Monitoring Directory: $MONITOR_DIR

FILES GENERATED:
- system-state.log: System resources and service status
- http-tests.log: HTTP response tests
- nginx-access.log: Nginx access logs
- nginx-error.log: Nginx error logs
- backend.log: Backend service logs
- network.log: Network activity
- react-files.log: React app file status
- cors-test.log: CORS configuration tests
- nginx-config.log: Nginx configuration
- backend-config.log: Backend configuration

QUICK CHECKS:
EOF

# Add quick status checks to summary
echo "--- Service Status ---" >> "$MONITOR_DIR/summary-report.txt"
systemctl is-active nginx >> "$MONITOR_DIR/summary-report.txt" 2>&1
systemctl is-active us-calendar >> "$MONITOR_DIR/summary-report.txt" 2>&1

echo "--- Port Status ---" >> "$MONITOR_DIR/summary-report.txt"
netstat -tlnp | grep -E ':(80|443|5001)' >> "$MONITOR_DIR/summary-report.txt" 2>&1

echo "--- Recent Nginx Errors ---" >> "$MONITOR_DIR/summary-report.txt"
tail -5 /var/log/nginx/error.log >> "$MONITOR_DIR/summary-report.txt" 2>&1

echo "--- Recent Backend Logs ---" >> "$MONITOR_DIR/summary-report.txt"
journalctl -u us-calendar --no-pager -n 5 >> "$MONITOR_DIR/summary-report.txt" 2>&1

echo ""
echo "✅ Monitoring completed!"
echo ""
echo "📁 All monitoring data saved to: $MONITOR_DIR"
echo ""
echo "📋 Summary report: $MONITOR_DIR/summary-report.txt"
echo ""
echo "🔍 Key files to check:"
echo "   - $MONITOR_DIR/nginx-error.log (for nginx errors)"
echo "   - $MONITOR_DIR/backend.log (for backend errors)"
echo "   - $MONITOR_DIR/http-tests.log (for HTTP response issues)"
echo "   - $MONITOR_DIR/cors-test.log (for CORS issues)"
echo ""
echo "💡 To view the summary:"
echo "   cat $MONITOR_DIR/summary-report.txt"
echo ""
echo "💡 To view nginx errors:"
echo "   cat $MONITOR_DIR/nginx-error.log"
echo ""
echo "💡 To view backend logs:"
echo "   cat $MONITOR_DIR/backend.log"

echo ""
echo "📊 CONSOLE SUMMARY FOR COPY/PASTE"
echo "================================="
echo "Date: $(date)"
echo "Monitoring Directory: $MONITOR_DIR"
echo ""

echo "🔧 SERVICE STATUS:"
echo "=================="
echo "Nginx: $(systemctl is-active nginx)"
echo "Backend: $(systemctl is-active us-calendar)"
echo ""

echo "🌐 PORT STATUS:"
echo "=============="
netstat -tlnp | grep -E ':(80|443|5001)' | head -5
echo ""

echo "📋 RECENT NGINX ERRORS (last 5):"
echo "================================"
tail -5 /var/log/nginx/error.log
echo ""

echo "🔧 RECENT BACKEND LOGS (last 5):"
echo "================================"
journalctl -u us-calendar --no-pager -n 5
echo ""

echo "📊 SYSTEM RESOURCES:"
echo "==================="
echo "Memory:"
free -h | grep -E '^Mem|^Swap'
echo ""
echo "Disk:"
df -h / | tail -1
echo ""
echo "Load:"
uptime
echo ""

echo "🌐 HTTP RESPONSE TESTS:"
echo "======================"
echo "Main page (/us/):"
MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/us/)
echo "Status: $MAIN_STATUS"
echo ""

echo "API (/api/users):"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/users)
echo "Status: $API_STATUS"
echo ""

echo "Static JS file:"
JS_FILE=$(ls /var/www/us-calendar/frontend/build/static/js/main.*.js 2>/dev/null | head -1)
if [ -n "$JS_FILE" ]; then
    JS_FILENAME=$(basename "$JS_FILE")
    JS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/us/static/js/$JS_FILENAME")
    echo "Status: $JS_STATUS ($JS_FILENAME)"
else
    echo "No JS file found"
fi
echo ""

echo "📁 REACT BUILD FILES:"
echo "===================="
echo "Build directory exists: $(test -d /var/www/us-calendar/frontend/build && echo 'YES' || echo 'NO')"
echo "Index.html exists: $(test -f /var/www/us-calendar/frontend/build/index.html && echo 'YES' || echo 'NO')"
echo "Static JS files: $(ls /var/www/us-calendar/frontend/build/static/js/ 2>/dev/null | wc -l) files"
echo "Static CSS files: $(ls /var/www/us-calendar/frontend/build/static/css/ 2>/dev/null | wc -l) files"
echo ""

echo "🔧 NGINX CONFIGURATION:"
echo "======================"
echo "Config valid: $(nginx -t >/dev/null 2>&1 && echo 'YES' || echo 'NO')"
echo ""

echo "📊 MONITORING FILES CREATED:"
echo "==========================="
ls -la "$MONITOR_DIR" | grep -E '\.(log|txt)$'
echo ""

echo "📋 END OF CONSOLE SUMMARY"
echo "=========================" 