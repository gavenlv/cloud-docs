# ip - 现代网络配置命令

# 查看接口
ip link show
ip addr show
ip -s link show

# 示例输出:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP
#     link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff

# 接口操作
ip link set eth0 up           # 启用接口
ip link set eth0 down         # 禁用接口
ip link set eth0 promisc on   # 混杂模式
ip link set eth0 mtu 9000     # 设置MTU

# IP地址操作
ip addr add 192.168.1.100/24 dev eth0    # 添加IP
ip addr del 192.168.1.100/24 dev eth0    # 删除IP
ip addr show eth0                              # 查看接口IP
ip addr flush dev eth0                          # 清除所有IP

# 查看MAC地址
ip link show eth0 | grep ether
ip -o link show eth0 | awk '{print $17}'

# 查看接口统计
ip -s link show eth0
ip -s -s link show eth0   # 详细统计