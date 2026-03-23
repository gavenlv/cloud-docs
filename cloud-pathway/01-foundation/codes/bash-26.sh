#!/bin/bash

LOG_FILE="/var/log/nginx/access.log"

echo "=== Top 10 IPs ==="
awk '{print $1}' $LOG_FILE | sort | uniq -c | sort -rn | head -10

echo "=== Top 10 URLs ==="
awk '{print $7}' $LOG_FILE | sort | uniq -c | sort -rn | head -10

echo "=== Status Codes ==="
awk '{print $9}' $LOG_FILE | sort | uniq -c | sort -rn

echo "=== Requests per Hour ==="
awk '{print substr($4, 14, 2)}' $LOG_FILE | sort | uniq -c