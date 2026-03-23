# 1. 创建GRE隧道
ip tunnel add gre1 mode gre remote 198.51.100.1 local 203.0.113.1

# 2. 配置IP
ip addr add 10.0.0.1/30 dev gre1

# 3. 启用
ip link set gre1 up

# 4. 添加路由
ip route add 10.0.2.0/24 dev gre1

# 5. 查看
ip tunnel show
ip link show gre1

# 6. 删除
ip link set gre1 down
ip tunnel del gre1