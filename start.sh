#!/bin/bash

# NGINX QUIC Testbed - Startup Script
# This script starts NGINX with the QUIC configuration

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF="$SCRIPT_DIR/config/nginx.conf"

echo "Starting NGINX QUIC Testbed..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (for binding to port 443)"
   echo "Please run: sudo $0"
   exit 1
fi

# Check if config exists
if [ ! -f "$NGINX_CONF" ]; then
    echo "NGINX configuration not found: $NGINX_CONF"
    echo "Make sure you've run the installer first: sudo ./install.sh"
    exit 1
fi

# Test nginx configuration
echo "Testing NGINX configuration..."
nginx -t -c "$NGINX_CONF"

if [ $? -eq 0 ]; then
    echo "NGINX configuration is valid"
else
    echo "NGINX configuration has errors"
    exit 1
fi

# Stop any existing nginx processes
echo "Stopping any existing NGINX processes..."
pkill nginx 2>/dev/null || true
sleep 2

# Start nginx with our configuration
echo "Starting NGINX with QUIC support..."
nginx -c "$NGINX_CONF"

if [ $? -eq 0 ]; then
    echo ""
    echo " NGINX QUIC Testbed is running!"
    echo ""
    echo " Access points:"
    echo "   - HTTP (redirects to HTTPS): http://localhost"
    echo "   - HTTPS/HTTP2/HTTP3: https://localhost"
    echo "   - Server info API: https://localhost/info"
    echo "   - NGINX status: https://localhost/status"
    echo ""
    echo " Testing:"
    echo "   - Open DevTools  Network tab to see HTTP/3 protocol"
    echo "   - Look for 'h3' in the Protocol column"
    echo "   - Check Alt-Svc header: h3=\":443\""
    echo ""
    echo "  Note: You'll see certificate warnings (normal for self-signed certs)"
    echo ""
    echo "To stop: sudo $SCRIPT_DIR/stop.sh"
else
    echo " Failed to start NGINX"
    exit 1
fi