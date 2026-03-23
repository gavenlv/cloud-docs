# 查看Linux路由表
ip route show
# 或
route -n

# 示例输出:
# default via 192.168.1.1 dev eth0 proto static
# 10.0.0.0/8 via 10.0.0.1 dev eth1 proto static
# 172.16.0.0/16 via 192.168.1.254 dev eth0 proto static
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100

# 字段说明:
# default: 默认路由 (0.0.0.0/0)
# via 192.168.1.1: 下一跳地址
# dev eth0: 出接口
# proto static: 路由协议 (static=静态, kernel=内核发现)
# scope link: 作用域 (link=本地链路, global=全局)
# src 192.168.1.100: 源IP地址

# 详细查看路由表
ip route show table all
ip route show table local
ip route show table main