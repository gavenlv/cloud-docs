# 路由表

# 查看路由表
ip route show
ip route show table all

# 示例输出:
# default via 192.168.1.1 dev eth0 proto static
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100

# 添加路由
ip route add 10.0.0.0/24 via 192.168.1.1 dev eth0    # 添加子网路由
ip route add default via 192.168.1.1 dev eth0         # 添加默认路由
ip route add 172.16.0.0/16 dev eth1                   # 添加直连路由

# 删除路由
ip route del 10.0.0.0/24
ip route del default

# 查看特定路由
ip route get 8.8.8.8
# 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.100

# 多路由表
ip route show table 100
ip route add default via 10.0.0.1 dev eth1 table 100

# 路由规则
ip rule show
# 0:      from all lookup local
# 32766:  from all lookup main
# 32767:  from all lookup default

ip rule add from 192.168.1.0/24 table 100
ip rule del from 192.168.1.0/24 table 100