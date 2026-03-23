# IP-in-IP隧道 (简单封装)

# 创建
ip tunnel add ipip1 mode ipip remote 198.51.100.1 local 203.0.113.1

# 配置
ip addr add 10.0.0.1/30 dev ipip1
ip link set ipip1 up

# 路由
ip route add 10.0.2.0/24 dev ipip1