# 诊断步骤
# 1. 确认本地网络配置
ip addr show
ip route show

# 2. 测试本地网关
ping -c 3 192.168.1.1

# 3. 测试DNS
ping -c 3 8.8.8.8
ping -c 3 google.com

# 常见原因和解决方案
# 1. 网卡未启用
ip link set eth0 up

# 2. IP配置错误
ip addr add 192.168.1.100/24 dev eth0

# 3. 网关不通
# 检查路由
ip route show
# 添加默认路由
ip route add default via 192.168.1.1

# 4. 防火墙阻止ICMP
iptables -L -n | grep ICMP