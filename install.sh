#!/bin/bash

# NGINX QUIC Testbed - Simple Installer
# Run this once to set up dependencies and SSL certificates

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing NGINX QUIC Testbed dependencies..."

# Install system dependencies
echo "Installing system packages..."
apt-get update -q
apt-get install -y nginx openssl curl

# Detect nginx user (varies by distribution)
if id -u nginx >/dev/null 2>&1; then
    NGINX_USER="nginx"
elif id -u www-data >/dev/null 2>&1; then
    NGINX_USER="www-data"
else
    echo "Warning: Neither 'nginx' nor 'www-data' user found"
    NGINX_USER="nobody"
fi

echo "Using NGINX user: $NGINX_USER"

# Update nginx.conf with correct user
sed -i "s/^user .*/user $NGINX_USER;/" "$SCRIPT_DIR/config/nginx.conf"

# Check if SSL certificates exist
if [ ! -f "$SCRIPT_DIR/ssl/server.crt" ]; then
    echo "Generating SSL certificates..."
    cd "$SCRIPT_DIR/ssl"
    
    # Generate private key
    openssl genrsa -out server.key 2048
    
    # Generate certificate
    openssl req -new -x509 -key server.key -out server.crt -days 365 \
        -subj "/C=US/ST=Test/L=Test/O=NGINX-QUIC/CN=localhost"
    
    echo "SSL certificates generated"
else
    echo "SSL certificates already exist"
fi

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

# Generate initial HTML content
echo "Creating test content..."
cd "$SCRIPT_DIR"
./generate_index.sh 1k

echo ""
echo "Installation complete!"
echo "Run: sudo ./start.sh"