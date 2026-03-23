# tcpdump是强大的命令行抓包工具

# 基本用法
sudo tcpdump -i eth0                    # 抓取接口所有包
sudo tcpdump -i eth0 -c 10             # 抓10个包
sudo tcpdump -i eth0 -w capture.pcap    # 保存到文件
sudo tcpdump -r capture.pcap            # 读取文件

# 过滤表达式
sudo tcpdump -i eth0 host 192.168.1.1   # 特定主机
sudo tcpdump -i eth0 port 80            # 特定端口
sudo tcpdump -i eth0 tcp                # TCP协议
sudo tcpdump -i eth0 icmp               # ICMP协议
sudo tcpdump -i eth0 'port 80 or 443'  # 多端口

# 常用选项
# -i: 接口
# -c: 抓包数量
# -w: 保存到文件
# -r: 读取文件
# -n: 不解析IP
# -nn: 不解析IP和端口
# -v: 详细输出
# -vv: 更详细
# -X: 显示十六进制内容
# -A: 显示ASCII内容

# 抓包分析示例
# 抓取HTTP请求
sudo tcpdump -i eth0 -A 'port 80 and tcp[((tcp[12:1] & 0xf0) >> 2):2] = 0x4745'

# 抓取DNS查询
sudo tcpdump -i eth0 -n 'port 53'

# 抓取SSH连接
sudo tcpdump -i eth0 'port 22'

# 抓取TCP握手
sudo tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn|tcp-ack) != 0'