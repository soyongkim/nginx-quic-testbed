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