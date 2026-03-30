#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/fill_200p.sql"


START_TIME=$(date +%s)

for p in $(seq 1 100); do
    echo "Processing p = $p..."
    
    ydb -p default sql -f "$SQL_FILE" 
    # -p "\$p=$p" 
done

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "Completed all 100 REPLACE INTO queries in ${DURATION} seconds"
