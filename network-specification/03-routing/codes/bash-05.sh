# 静态负载均衡 (基于轮询)
ip route add default scope global \
    nexthop via 192.168.1.1 dev eth0 weight 1 \
    nexthop via 10.0.0.1 dev eth1 weight 1

# 基于策略的负载均衡
# 不同源地址走不同链路
ip rule add from 192.168.1.0/24 table wan1
ip rule add from 192.168.2.0/24 table wan2

# 查看ECMP (等价多路径)
ip route show
# default via 192.168.1.1 dev eth0
#         nexthop via 10.0.0.1 dev eth1 weight 1
#         nexthop via 192.168.1.1 dev eth0 weight 1

# 启用ECMP
sysctl -w net.ipv4.conf.all.rp_filter=1