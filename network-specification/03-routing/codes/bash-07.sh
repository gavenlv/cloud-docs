# 查看路由
ip route show, route -n, ip rule show

# 静态路由
ip route add/del, ip route get

# 动态路由
# OSPF
router ospf 1, show ip ospf neighbor, show ip ospf route

# BGP
router bgp, show ip bgp, show ip bgp neighbor

# NAT
iptables -t nat -L, conntrack -L

# 诊断
traceroute, mtr, ip route get