# 查看所有网络接口
ip link show
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
#    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast
#    link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff

# 查看IP地址
ip addr show
# inet 192.168.1.100/24 scope global eth0

# 查看路由表
ip route show

# 查看ARP表
ip neigh show
# 192.168.1.1 dev eth0 lladdr 00:11:22:33:44:55 REACHABLE

# 查看网络连接统计
ss -s
# Total: 186 (kernel: 194)
# TCP:   12 (estab: 5, closed: 0, orphaned: 0, synrecv: 0)