#!/bin/bash

echo "=== System Monitor ==="
echo "Date: $(date)"
echo ""

echo "=== Uptime ==="
uptime
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h | grep -E "^/dev|Filesystem"
echo ""

echo "=== Top 5 CPU Processes ==="
ps aux --sort=-%cpu | head -6
echo ""

echo "=== Top 5 Memory Processes ==="
ps aux --sort=-%mem | head -6
echo ""

echo "=== Network Connections ==="
ss -tuln | head -20