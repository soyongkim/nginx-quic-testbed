#!/bin/bash
echo "Live QUIC Connection Monitor"
echo "============================"
echo "Press Ctrl+C to stop"
echo ""

# Monitor both access and error logs
tail -f /var/log/nginx/access.log /var/log/nginx/error.log | grep --line-buffered -E "(HTTP/3.0|quic)" | while read line; do
    timestamp=$(date '+%H:%M:%S')
    if [[ "$line" =~ "HTTP/3.0" ]]; then
        # Parse access log entry
        ip=$(echo "$line" | awk '{print $1}')
        method=$(echo "$line" | awk -F'"' '{print $2}' | awk '{print $1}')
        path=$(echo "$line" | awk -F'"' '{print $2}' | awk '{print $2}')
        status=$(echo "$line" | awk '{print $9}')
        bytes=$(echo "$line" | awk '{print $10}')
        echo "[$timestamp] HTTP/3: $ip -> $method $path ($status, ${bytes}B)"
    else
        # Parse error log entry
        event=$(echo "$line" | sed 's/.*quic //' | cut -d',' -f1)
        client=$(echo "$line" | grep -o 'client: [^,]*' | sed 's/client: //')
        echo "[$timestamp] QUIC: $event (client: $client)"
    fi
done
