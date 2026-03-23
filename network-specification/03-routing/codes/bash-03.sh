# 添加静态路由
ip route add 10.0.0.0/8 via 192.168.1.1 dev eth0

# 添加默认路由
ip route add default via 192.168.1.1 dev eth0
# 或
ip route add 0.0.0.0/0 via 192.168.1.1 dev eth0

# 删除路由
ip route del 10.0.0.0/8 via 192.168.1.1 dev eth0

# 添加主机路由
ip route add 192.168.1.100/32 via 192.168.1.1 dev eth0

# 添加黑洞路由 (丢弃流量)
ip route add blackhole 10.0.0.0/8

# 添加不可达路由 (发送ICMP不可达)
ip route add prohibit 172.16.0.0/12

# 查看特定路由
ip route get 8.8.8.8
# 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.100

# 持久化静态路由 (重启后保留)
# Debian/Ubuntu:
echo "10.0.0.0/8 via 192.168.1.1" >> /etc/network/interfaces

# RHEL/CentOS:
echo "10.0.0.0/8 via 192.168.1.1 dev eth0" >> /etc/sysconfig/network-scripts/route-eth0