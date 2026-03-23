#!/bin/bash
# 监控连接状态

while true; do
    clear
    echo "=== 连接监控 ==="
    date
    echo ""
    echo "ESTABLISHED: $(ss -tan state established | wc -l)"
    echo "TIME-WAIT:   $(ss -tan state time-wait | wc -l)"
    echo "CLOSE-WAIT:  $(ss -tan state close-wait | wc -l)"
    echo ""
    echo "TOP 5 来源IP:"
    ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5
    sleep 5
done