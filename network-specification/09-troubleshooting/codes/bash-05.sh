# 诊断步骤
# 1. 查看路由表
ip route show
route -n

# 2. 测试路由
traceroute 10.0.0.1
ip route get 10.0.0.1

# 3. 检查网关
ip neigh show

# 常见原因
# 1. 缺少路由
ip route add 10.0.0.0/24 via 192.168.1.1

# 2. 默认路由缺失
ip route add default via 192.168.1.1

# 3. 路由冲突
ip route show
# 删除冲突路由
ip route del 10.0.0.0/24