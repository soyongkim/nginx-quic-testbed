#!/bin/bash

# Generate simple HTML files of specified sizes
# Usage: ./generate_simple.sh [size] (default: 1k)
# Examples: ./generate_simple.sh 1k, ./generate_simple.sh 10k, ./generate_simple.sh 1M

SIZE=${1:-1k}
TARGET_FILE="html/index.html"

# Ensure html directory exists
mkdir -p html

# Convert size to bytes
case $SIZE in
    *k|*K) BYTES=$((${SIZE%[kK]} * 1024)) ;;
    *m|*M) BYTES=$((${SIZE%[mM]} * 1024 * 1024)) ;;
    *) BYTES=$SIZE ;;
esac

# Basic HTML structure
HEADER='<!DOCTYPE html>
<html>
<head>
    <title>NGINX QUIC Test</title>
</head>
<body>
'

FOOTER='
</body>
</html>'

# Calculate header and footer sizes
HEADER_SIZE=${#HEADER}
FOOTER_SIZE=${#FOOTER}
OVERHEAD_SIZE=$((HEADER_SIZE + FOOTER_SIZE))

# Calculate needed data size
DATA_SIZE=$((BYTES - OVERHEAD_SIZE))

# For large files, use efficient method
if [ $DATA_SIZE -gt 100000 ]; then
    # Create data in chunks to avoid memory issues
    printf "%s" "$HEADER" > "$TARGET_FILE"
    
    # Generate data efficiently
    DATA_UNIT="NGINX QUIC test data "
    UNIT_SIZE=${#DATA_UNIT}
    REPETITIONS=$((DATA_SIZE / UNIT_SIZE))
    
    # Write data in chunks of 10000 repetitions to avoid command line limits
    CHUNK_SIZE=10000
    WRITTEN=0
    
    while [ $WRITTEN -lt $REPETITIONS ]; do
        REMAINING=$((REPETITIONS - WRITTEN))
        CURRENT_CHUNK=$((REMAINING < CHUNK_SIZE ? REMAINING : CHUNK_SIZE))
        
        # Generate chunk
        for i in $(seq 1 $CURRENT_CHUNK); do
            printf "%s" "$DATA_UNIT"
        done >> "$TARGET_FILE"
        
        WRITTEN=$((WRITTEN + CURRENT_CHUNK))
    done
    
    printf "%s" "$FOOTER" >> "$TARGET_FILE"
else
    # For smaller files, use simple method
    DATA_UNIT="NGINX QUIC test data "
    UNIT_SIZE=${#DATA_UNIT}
    REPETITIONS=$((DATA_SIZE / UNIT_SIZE))
    
    # Generate the data content
    DATA=""
    for i in $(seq 1 $REPETITIONS); do
        DATA="${DATA}${DATA_UNIT}"
    done
    
    # Write complete file
    printf "%s%s%s" "$HEADER" "$DATA" "$FOOTER" > "$TARGET_FILE"
fi

# Get actual file size
ACTUAL_SIZE=$(wc -c < "$TARGET_FILE")
SIZE_DIFF=$((ACTUAL_SIZE - BYTES))

echo "Generated $TARGET_FILE"
echo "Target size: $BYTES bytes ($SIZE)"
echo "Actual size: $ACTUAL_SIZE bytes"
echo "Difference: ${SIZE_DIFF} bytes"