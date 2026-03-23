cat > /root/monitor.sh << 'EOF'
#!/bin/bash
# 系统监控脚本

while true; do
    clear
    echo "===== $(date) ====="
    echo ""
    echo "=== 系统负载 ==="
    uptime
    echo ""
    echo "=== 内存使用 ==="
    free -h
    echo ""
    echo "=== 磁盘使用 ==="
    df -h | grep -v tmpfs
    echo ""
    echo "=== Top 5 CPU进程 ==="
    ps aux --sort=-%cpu | head -6
    echo ""
    echo "=== Top 5 内存进程 ==="
    ps aux --sort=-%mem | head -6
    sleep 5
done
EOF
chmod +x /root/monitor.sh