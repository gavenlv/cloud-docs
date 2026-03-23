# ping是ICMP协议的基本测试工具
# 用于测试连通性和延迟

# 基本用法
ping 8.8.8.8
ping -c 4 8.8.8.8              # 发4个包
ping -i 0.5 8.8.8.8            # 每0.5秒一次
ping -s 1000 8.8.8.8          # 指定数据包大小

# 结果分析
ping -c 4 8.8.8.8
# PING 8.8.8.8 (8.8.8.8): 56 data bytes
# 64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=14.8 ms
# 64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=14.5 ms
# --- 8.8.8.8 ping statistics ---
# 4 packets transmitted, 4 received, 0% packet loss, time 3002ms
# rtt min/avg/max/mdev = 14.5/14.7/14.8/0.1 ms

# 参数说明:
# ttl: 生存时间 (经过的路由数)
# time: 往返时间
# rtt: Round-Trip Time

# 注意事项:
# - ICMP可能被防火墙阻断
# - ping通不代表端口可用