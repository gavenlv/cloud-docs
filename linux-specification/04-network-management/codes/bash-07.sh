# tcpdump - 命令行抓包

# 基础用法
tcpdump -i eth0                 # 监听接口
tcpdump -i any                   # 监听所有接口
tcpdump host 192.168.1.1        # 过滤主机
tcpdump port 80                  # 过滤端口
tcpdump tcp                      # 过滤TCP
tcpdump udp                      # 过滤UDP
tcpdump icmp                     # 过滤ICMP

# 组合过滤
tcpdump -i eth0 host 192.168.1.1 and port 80
tcpdump -i eth0 tcp and '(port 80 or port 443)'
tcpdump -i eth0 not arp and not icmp

# 保存到文件
tcpdump -i eth0 -w capture.pcap
tcpdump -r capture.pcap          # 读取文件

# 高级选项
tcpdump -n                       # 不解析域名
tcpdump -nn                      # 不解析域名和端口
tcpdump -v                       # 详细输出
tcpdump -vv                      # 更详细
tcpdump -X                       # 显示hex和ascii
tcpdump -c 10                    # 只抓10个包

# 表达式语法
# 类型: host, net, port, portrange
# 方向: src, dst
# 协议: tcp, udp, icmp, arp
# 操作符: and, or, not, >, <, >=, <=, =