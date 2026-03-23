# 网络绑定 - 聚合多个网卡

# 加载bonding模块
modprobe bonding mode=0

# 创建bond接口
ip link add bond0 type bond mode 802.3ad
ip link set eth0 down
ip link set eth1 down
ip link set eth0 master bond0
ip link set eth1 master bond0
ip link set bond0 up
ip addr add 192.168.1.100/24 dev bond0

# Bonding模式:
# mode 0: balance-rr (轮转)
# mode 1: active-backup (主备)
# mode 2: balance-xor (XOR)
# mode 3: broadcast (广播)
# mode 4: 802.3ad (LACP)
# mode 5: balance-tlb (自适应负载)
# mode 6: balance-alb (自适应负载)

# 查看bond状态
cat /proc/net/bonding/bond0