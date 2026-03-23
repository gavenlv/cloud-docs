# 查看TCP窗口
ss -tm

# 查看实际窗口大小
cat /proc/sys/net/ipv4/tcp_rmem   # 接收窗口
cat /proc/sys/net/ipv4/tcp_wmem   # 发送窗口

# 查看窗口探测
cat /proc/sys/net/ipv4/tcp_probe_threshold

# 调整窗口大小
# 临时调整
sysctl -w net.ipv4.tcp_rmem="4096 87380 6291456"

# 永久调整
echo "net.ipv4.tcp_rmem = 4096 87380 6291456" >> /etc/sysctl.conf