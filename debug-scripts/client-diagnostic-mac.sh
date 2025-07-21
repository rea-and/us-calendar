#!/bin/bash

# Client-side diagnostic script for Mac

echo "🔍 Client-Side Diagnostic Script for Mac"
echo "========================================"
echo ""

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ curl is not installed. Please install it first."
    echo "   brew install curl"
    exit 1
fi

# Check if jq is available (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found. Install with: brew install jq"
    echo "   Continuing without JSON parsing..."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

echo "📋 Testing server: http://157.230.244.80/us/"
echo "📋 Testing domain: http://carlevato.net/us/"
echo ""

# Function to test a URL and show results
test_url() {
    local url=$1
    local description=$2
    local user_agent=$3
    
    echo "🔍 Testing: $description"
    echo "URL: $url"
    
    # Test with specific User-Agent
    if [ -n "$user_agent" ]; then
        echo "User-Agent: $user_agent"
        response=$(curl -s -H "User-Agent: $user_agent" "$url")
        headers=$(curl -s -I -H "User-Agent: $user_agent" "$url")
    else
        response=$(curl -s "$url")
        headers=$(curl -s -I "$url")
    fi
    
    # Get HTTP status
    status=$(echo "$headers" | head -1 | cut -d' ' -f2)
    echo "HTTP Status: $status"
    
    # Get Content-Type
    content_type=$(echo "$headers" | grep -i "content-type" | head -1)
    echo "Content-Type: $content_type"
    
    # Get first line of response
    first_line=$(echo "$response" | head -1)
    echo "First line: $first_line"
    
    # Analyze response
    if echo "$first_line" | grep -q "<!DOCTYPE\|<html"; then
        echo "❌ RESULT: HTML served (this is the problem!)"
    elif echo "$first_line" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
        echo "✅ RESULT: JavaScript served (correct)"
    elif echo "$first_line" | grep -q "404\|Not Found"; then
        echo "❌ RESULT: 404 Not Found"
    elif echo "$first_line" | grep -q "403\|Forbidden"; then
        echo "❌ RESULT: 403 Forbidden"
    else
        echo "⚠️  RESULT: Unknown response type"
    fi
    
    echo ""
}

# Function to test JavaScript file specifically
test_js_file() {
    local base_url=$1
    local description=$2
    local user_agent=$3
    
    echo "🔍 Testing JavaScript file: $description"
    echo "URL: $base_url/static/js/main.542ce4b5.js"
    
    # Test with specific User-Agent
    if [ -n "$user_agent" ]; then
        echo "User-Agent: $user_agent"
        response=$(curl -s -H "User-Agent: $user_agent" "$base_url/static/js/main.542ce4b5.js")
        headers=$(curl -s -I -H "User-Agent: $user_agent" "$base_url/static/js/main.542ce4b5.js")
    else
        response=$(curl -s "$base_url/static/js/main.542ce4b5.js")
        headers=$(curl -s -I "$base_url/static/js/main.542ce4b5.js")
    fi
    
    # Get HTTP status
    status=$(echo "$headers" | head -1 | cut -d' ' -f2)
    echo "HTTP Status: $status"
    
    # Get Content-Type
    content_type=$(echo "$headers" | grep -i "content-type" | head -1)
    echo "Content-Type: $content_type"
    
    # Get response size
    response_size=$(echo "$response" | wc -c)
    echo "Response size: $response_size bytes"
    
    # Get first line of response
    first_line=$(echo "$response" | head -1)
    echo "First line: $first_line"
    
    # Analyze response
    if echo "$first_line" | grep -q "<!DOCTYPE\|<html"; then
        echo "❌ RESULT: HTML served instead of JavaScript (this causes the error!)"
    elif echo "$first_line" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
        echo "✅ RESULT: JavaScript served correctly"
    elif [ "$status" = "404" ]; then
        echo "❌ RESULT: 404 Not Found"
    elif [ "$status" = "403" ]; then
        echo "❌ RESULT: 403 Forbidden"
    else
        echo "⚠️  RESULT: Unknown response type"
    fi
    
    echo ""
}

# Function to test network connectivity
test_network() {
    echo "🌐 Network Connectivity Tests"
    echo "============================"
    
    # Test DNS resolution
    echo "🔍 DNS Resolution:"
    if nslookup carlevato.net &> /dev/null; then
        echo "✅ carlevato.net resolves"
    else
        echo "❌ carlevato.net DNS resolution failed"
    fi
    
    # Test ping
    echo "🔍 Ping test:"
    if ping -c 1 157.230.244.80 &> /dev/null; then
        echo "✅ Server responds to ping"
    else
        echo "❌ Server does not respond to ping"
    fi
    
    # Test port 80
    echo "🔍 Port 80 test:"
    if nc -z 157.230.244.80 80 2>/dev/null; then
        echo "✅ Port 80 is open"
    else
        echo "❌ Port 80 is closed"
    fi
    
    echo ""
}

# Function to test browser simulation
test_browser_simulation() {
    echo "🌐 Browser Simulation Tests"
    echo "==========================="
    
    # Chrome User-Agent
    chrome_ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    # Safari User-Agent
    safari_ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    
    # Firefox User-Agent
    firefox_ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0"
    
    echo "🔍 Testing with different browser User-Agents:"
    echo ""
    
    test_js_file "http://157.230.244.80/us" "IP with Chrome UA" "$chrome_ua"
    test_js_file "http://157.230.244.80/us" "IP with Safari UA" "$safari_ua"
    test_js_file "http://157.230.244.80/us" "IP with Firefox UA" "$firefox_ua"
    
    test_js_file "http://carlevato.net/us" "Domain with Chrome UA" "$chrome_ua"
    test_js_file "http://carlevato.net/us" "Domain with Safari UA" "$safari_ua"
    test_js_file "http://carlevato.net/us" "Domain with Firefox UA" "$firefox_ua"
}

# Function to test with different headers
test_headers() {
    echo "📋 Header Tests"
    echo "=============="
    
    echo "🔍 Testing with Accept headers:"
    curl -s -H "Accept: application/javascript, text/javascript, */*" \
         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         "http://157.230.244.80/us/static/js/main.542ce4b5.js" | head -1
    echo ""
    
    echo "🔍 Testing with Referer header:"
    curl -s -H "Referer: http://157.230.244.80/us/" \
         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         "http://157.230.244.80/us/static/js/main.542ce4b5.js" | head -1
    echo ""
    
    echo "🔍 Testing with Cache-Control header:"
    curl -s -H "Cache-Control: no-cache" \
         -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         "http://157.230.244.80/us/static/js/main.542ce4b5.js" | head -1
    echo ""
}

# Function to test main page
test_main_page() {
    echo "🏠 Main Page Tests"
    echo "================="
    
    echo "🔍 Testing main page (IP):"
    main_response=$(curl -s "http://157.230.244.80/us/")
    if echo "$main_response" | grep -q "main.*\.js"; then
        js_ref=$(echo "$main_response" | grep -o 'main\.[^"]*\.js' | head -1)
        echo "✅ Main page contains JavaScript reference: $js_ref"
    else
        echo "❌ Main page missing JavaScript reference"
    fi
    echo ""
    
    echo "🔍 Testing main page (domain):"
    main_response=$(curl -s "http://carlevato.net/us/")
    if echo "$main_response" | grep -q "main.*\.js"; then
        js_ref=$(echo "$main_response" | grep -o 'main\.[^"]*\.js' | head -1)
        echo "✅ Main page contains JavaScript reference: $js_ref"
    else
        echo "❌ Main page missing JavaScript reference"
    fi
    echo ""
}

# Function to test API
test_api() {
    echo "🔌 API Tests"
    echo "============"
    
    echo "🔍 Testing API (IP):"
    api_response=$(curl -s "http://157.230.244.80/api/users")
    if [ "$JQ_AVAILABLE" = true ]; then
        if echo "$api_response" | jq . &> /dev/null; then
            echo "✅ API returns valid JSON"
        else
            echo "❌ API does not return valid JSON"
        fi
    else
        if echo "$api_response" | grep -q "\[.*\]"; then
            echo "✅ API returns array-like response"
        else
            echo "❌ API response format unknown"
        fi
    fi
    echo ""
    
    echo "🔍 Testing API (domain):"
    api_response=$(curl -s "http://carlevato.net/api/users")
    if [ "$JQ_AVAILABLE" = true ]; then
        if echo "$api_response" | jq . &> /dev/null; then
            echo "✅ API returns valid JSON"
        else
            echo "❌ API does not return valid JSON"
        fi
    else
        if echo "$api_response" | grep -q "\[.*\]"; then
            echo "✅ API returns array-like response"
        else
            echo "❌ API response format unknown"
        fi
    fi
    echo ""
}

# Function to generate summary
generate_summary() {
    echo "📊 DIAGNOSTIC SUMMARY"
    echo "===================="
    echo "Date: $(date)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "curl version: $(curl --version | head -1)"
    echo ""
    
    echo "🔍 Key Findings:"
    echo "================"
    
    # Test the main issue
    js_response=$(curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
         "http://157.230.244.80/us/static/js/main.542ce4b5.js" | head -1)
    
    if echo "$js_response" | grep -q "<!DOCTYPE\|<html"; then
        echo "❌ CRITICAL: Server is serving HTML instead of JavaScript"
        echo "   This explains the 'Unexpected token <' error in browsers"
        echo "   The nginx configuration needs to be fixed"
    elif echo "$js_response" | grep -q "function\|var\|const\|let\|import\|webpack\|/\*!"; then
        echo "✅ Server is serving JavaScript correctly"
        echo "   The issue is likely client-side caching or browser-specific"
        echo "   Try clearing browser cache completely"
    else
        echo "⚠️  Unknown response type - needs further investigation"
    fi
    
    echo ""
    echo "🔧 Recommendations:"
    echo "=================="
    if echo "$js_response" | grep -q "<!DOCTYPE\|<html"; then
        echo "1. Fix nginx configuration on server"
        echo "2. Ensure static file location blocks are correct"
        echo "3. Check nginx location priority"
    else
        echo "1. Clear browser cache completely"
        echo "2. Try incognito/private browsing mode"
        echo "3. Test with different browsers"
        echo "4. Check browser developer tools console"
    fi
    
    echo ""
    echo "🌐 Test URLs:"
    echo "============"
    echo "Main page: http://157.230.244.80/us/"
    echo "Domain: http://carlevato.net/us/"
    echo "JS file: http://157.230.244.80/us/static/js/main.542ce4b5.js"
    echo ""
}

# Run all tests
echo "Starting comprehensive client-side diagnostics..."
echo ""

test_network
test_main_page
test_api
test_browser_simulation
test_headers
generate_summary

echo "✅ Client-side diagnostic completed!"
echo ""
echo "📋 Copy the summary above and share it for analysis." 