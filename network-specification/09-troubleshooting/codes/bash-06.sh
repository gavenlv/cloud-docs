# 诊断步骤
# 1. 检查网关
ip route show | grep default

# 2. 测试网关
ping -c 3 192.168.1.1

# 3. 检查ARP表
ip neigh show

# 常见原因
# 1. 网关配置错误
ip route change default via 192.168.1.254

# 2. 网关不可达
# 检查物理连接
ip link show
ethtool eth0