# 查看当前cwnd
ss -i

# 查看网络统计
netstat -s | grep -i congestion

# 查看TCP参数
sysctl net.ipv4.tcp_congestion_control   # 当前算法
sysctl net.ipv4.tcp_slow_start_after_idle  # 空闲后是否重置

# 可用算法
sysctl net.ipv4.tcp_available_congestion_control

# 常见算法:
# cubic (Linux默认)
# reno (经典)
# bbr (Google开发)
#vegas, westwood, etc.

# 切换算法
sysctl -w net.ipv4.tcp_congestion_control=bbr

# 永久配置
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf