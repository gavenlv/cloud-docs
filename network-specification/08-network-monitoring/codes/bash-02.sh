# traceroute追踪数据包经过的路由

# Linux (使用UDP/ICMP)
traceroute 8.8.8.8
traceroute -I 8.8.8.8          # 使用ICMP
traceroute -T 8.8.8.8         # 使用TCP
traceroute -n 8.8.8.8         # 不解析域名

# Windows
tracert 8.8.8.8

# 结果分析
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.1.1 (192.168.1.1)  1.234 ms  1.123 ms  1.089 ms
 2  10.0.0.1 (10.0.0.1)       5.678 ms  5.432 ms  5.321 ms
 3  * * *                       # * 表示超时(可能被防火墙阻断)
 4  8.8.8.8 (8.8.8.8)        14.567 ms 14.321 ms 14.234 ms

# mtr (实时追踪)
mtr 8.8.8.8
mtr -r 8.8.8.8                 # 生成报告