# ping - ICMP测试
ping 8.8.8.8
ping -c 4 8.8.8.8            # 发4个包
ping -i 0.5 8.8.8.8           # 每0.5秒
ping -s 1472 8.8.8.8          # 指定数据包大小
ping -f 8.8.8.8                # 洪水ping (需root)

# ping输出分析
# 64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=10.2 ms
# - bytes: 数据包大小
# - icmp_seq: 序列号
# - ttl: 生存时间 (每经过一个路由减1)
# - time: 往返时间

# traceroute - 路由跟踪
traceroute 8.8.8.8
traceroute -n 8.8.8.8          # 不解析域名
traceroute -m 30 8.8.8.8       # 最大跳数
traceroute -T 8.8.8.8          # TCP方式
traceroute -I 8.8.8.8          # ICMP方式

# mtr - traceroute + ping
mtr 8.8.8.8
mtr -r 8.8.8.8                 # 报告模式