# 查看网络配置
cat /proc/sys/net/ipv4/tcp_rmem  # TCP接收缓冲区
cat /proc/sys/net/ipv4/tcp_wmem  # TCP发送缓冲区
cat /proc/sys/net/core/rmem_max  # 最大接收缓冲区
cat /proc/sys/net/core/wmem_max  # 最大发送缓冲区