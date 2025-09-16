#!/bin/bash

# NGINX QUIC Testbed - Stop Script
# This script stops the NGINX server

set -e

echo "Stopping NGINX QUIC Testbed..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo " This script must be run as root"
   echo "   Please run: sudo $0"
   exit 1
fi

# Stop nginx processes
pkill nginx || echo "No NGINX processes found"

echo "NGINX QUIC Testbed stopped"