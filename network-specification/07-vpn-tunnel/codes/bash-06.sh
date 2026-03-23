# SIT隧道 (IPv6 over IPv4)

# 创建
ip tunnel add sit1 mode sit remote 198.51.100.1 local 203.0.113.1

# 配置IPv6
ip -6 addr add 2001:db8::1/64 dev sit1
ip link set sit1 up

# 添加默认路由
ip -6 route add ::/0 dev sit1