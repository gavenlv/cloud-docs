# 基于源地址的策略路由
ip rule add from 192.168.1.0/24 table 100 priority 100

# 创建自定义路由表
echo "100 custom" >> /etc/iproute2/rt_tables

# 添加路由到自定义表
ip route add default via 10.0.0.1 dev eth1 table custom

# 查看路由表
ip route show table custom

# 基于源地址的完整配置:
# 1. 创建路由表
echo "200 wan1" >> /etc/iproute2/rt_tables
echo "201 wan2" >> /etc/iproute2/rt_tables

# 2. 添加默认路由
ip route add default via 203.0.113.1 dev eth0 table wan1
ip route add default via 198.51.100.1 dev eth1 table wan2

# 3. 添加策略路由
ip rule add from 192.168.1.0/24 table wan1 priority 100
ip rule add from 192.168.2.0/24 table wan2 priority 101

# 4. 查看
ip rule show
ip route show table wan1
ip route show table wan2