#!/bin/bash

# NGINX QUIC Log Analysis Tool
echo "NGINX QUIC Log Analysis Dashboard"
echo "=================================="
echo "$(date)"
echo ""

# Function to show separator
show_section() {
    echo ""
    echo "* $1"
    echo "$(printf '%.0s-' {1..50})"
}

show_section "QUIC Connection Summary"
echo "HTTP/3 requests today: $(grep "HTTP/3.0" /var/log/nginx/access.log | grep "$(date '+%d/%b/%Y')" | wc -l)"
echo "QUIC events in error log: $(grep -i quic /var/log/nginx/error.log | wc -l)"
echo "Unique QUIC clients: $(grep "HTTP/3.0" /var/log/nginx/access.log | awk '{print $1}' | sort -u | wc -l)"

show_section "Recent HTTP/3 Requests (Last 10)"
grep "HTTP/3.0" /var/log/nginx/access.log | tail -10 | while read line; do
    # Extract key fields from access log
    IP=$(echo "$line" | awk '{print $1}')
    TIME=$(echo "$line" | awk -F'[' '{print $2}' | awk -F']' '{print $1}')
    METHOD=$(echo "$line" | awk -F'"' '{print $2}' | awk '{print $1}')
    URL=$(echo "$line" | awk -F'"' '{print $2}' | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{print $9}')
    BYTES=$(echo "$line" | awk '{print $10}')
    RESPONSE_TIME=$(echo "$line" | awk '{print $16}')
    
    echo "  * $IP -> $METHOD $URL | $STATUS | ${BYTES} bytes | ${RESPONSE_TIME}s"
done

show_section "QUIC Connection Details (Last 10)"
grep -i quic /var/log/nginx/error.log | tail -10 | while read line; do
    # Extract timestamp and event
    TIMESTAMP=$(echo "$line" | awk '{print $1, $2}')
    EVENT=$(echo "$line" | sed 's/.*quic /quic /' | cut -d',' -f1)
    CLIENT=$(echo "$line" | grep -o 'client: [^,]*' | sed 's/client: //')
    
    echo "  * $TIMESTAMP | $EVENT | $CLIENT"
done

show_section "QUIC Protocol Analysis"

# Path migration events
MIGRATIONS=$(grep "quic migrated to path" /var/log/nginx/error.log | wc -l)
echo "Path migrations detected: $MIGRATIONS"

# Connection validation events  
VALIDATIONS=$(grep "successfully validated" /var/log/nginx/error.log | wc -l)
echo "Path validations: $VALIDATIONS"

# Connection timeouts
TIMEOUTS=$(grep "quic client timed out" /var/log/nginx/error.log | wc -l)
echo "Connection timeouts: $TIMEOUTS"

# Fixed bit errors (potential QUIC version issues)
FIXED_BIT_ERRORS=$(grep "quic fixed bit is not set" /var/log/nginx/error.log | wc -l)
echo "Fixed bit warnings: $FIXED_BIT_ERRORS"

show_section "Performance Metrics"

# Calculate average response times for HTTP/3
echo "HTTP/3 Performance:"
grep "HTTP/3.0" /var/log/nginx/access.log | awk '{print $16}' | grep -E '^[0-9.]+$' | awk '
{
    sum += $1
    count++
    if ($1 > max) max = $1
    if (min == "" || $1 < min) min = $1
}
END {
    if (count > 0) {
        avg = sum / count
        printf "  Average response time: %.3fs\n", avg
        printf "  Min response time: %.3fs\n", min
        printf "  Max response time: %.3fs\n", max
        printf "  Total requests: %d\n", count
    } else {
        print "  No valid response time data found"
    }
}'

# Bytes transferred analysis
echo ""
echo "Data Transfer:"
grep "HTTP/3.0" /var/log/nginx/access.log | awk '{print $10}' | grep -E '^[0-9]+$' | awk '
{
    sum += $1
    count++
}
END {
    if (count > 0) {
        total_mb = sum / (1024 * 1024)
        avg_kb = (sum / count) / 1024
        printf "  Total bytes transferred: %.2f MB\n", total_mb
        printf "  Average response size: %.2f KB\n", avg_kb
    }
}'

show_section "Real-time Monitoring Commands"
echo "Monitor access log: tail -f /var/log/nginx/access.log | grep 'HTTP/3.0'"
echo "Monitor QUIC events: tail -f /var/log/nginx/error.log | grep -i quic"
echo "Watch connections: watch -n1 \"netstat -tuln | grep :443\""
echo ""
echo "Run this script again: ./quic_logs.sh"