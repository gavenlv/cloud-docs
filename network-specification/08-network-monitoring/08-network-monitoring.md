# 网络监控和诊断

## 本章导学

**学完本章后，你将能够：**

- 掌握常用网络诊断工具的使用方法
- 理解TCP/UDP连接状态
- 掌握带宽测试和性能分析
- 理解网络监控的指标体系

**学习方法：**

```
ping → traceroute → tcpdump → ss/netstat → 性能测试 → 监控体系
```

---

# 1. 基础诊断工具

## 1.1 ping

```bash
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
```

## 1.2 traceroute

```bash
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
```

---

# 2. 连接状态分析

## 2.1 ss命令

```bash
# ss是netstat的现代替代品, 更快

# 基本用法
ss -tan                      # TCP所有连接
ss -tln                      # TCP监听端口
ss -uln                      # UDP监听端口
ss -s                        # 连接统计

# 过滤
ss -tan state established   # 已建立连接
ss -tan state time-wait     # TIME_WAIT状态
ss -tp                      # 显示进程信息
ss -tn sport = :80          # 源端口80

# 常用选项
# -n: 不解析域名
# -a: 所有连接
# -l: 监听端口
# -t: TCP
# -u: UDP
# -p: 显示进程
# -s: 统计
# -o: 显示定时器信息
# -e: 扩展信息
# -m: 内存信息

# 查看详细连接信息
ss -tano
# State      Recv-Q   Send-Q   Local Address:Port    Peer Address:Port
# ESTAB      0        0        192.168.1.100:22      192.168.1.50:54321
# users:(("sshd",pid=1234,fd=3))
```

## 2.2 netstat

```bash
# netstat是经典的网络统计工具

# 基本用法
netstat -tuln                # 监听端口
netstat -an                  # 所有连接
netstat -r                   # 路由表
netstat -i                   # 接口统计
netstat -s                   # 各协议统计

# 过滤
netstat -an | grep ESTABLISHED
netstat -an | grep :80

# 配合grep分析
netstat -an | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
```

---

# 3. 抓包分析

## 3.1 tcpdump

```bash
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
```

## 3.2 wireshark

```bash
# Wireshark是图形化抓包分析工具

# 常用过滤
ip.addr == 192.168.1.1           # 特定IP
ip.src == 192.168.1.0/24        # 源IP网段
tcp.port == 80                   # TCP端口
tcp.flags.syn == 1               # SYN包
http.request.method == "GET"     # HTTP GET

# 统计功能
# Statistics → Summary: 连接统计
# Statistics → Conversations: 对话统计
# Statistics → Protocol Hierarchy: 协议层级

# 导出
# File → Export Objects → HTTP: 导出HTTP对象
```

---

# 4. 性能测试

## 4.1 带宽测试

```bash
# iperf3: 带宽测试工具

# 服务器端
iperf3 -s
iperf3 -s -D                    # 后台运行
iperf3 -s -i 1                  # 每秒输出

# 客户端
iperf3 -c server_ip
iperf3 -c server_ip -t 30      # 测试30秒
iperf3 -c server_ip -P 4        # 4个并行连接
iperf3 -c server_ip -R          # 下载测试(服务端发送)

# 结果
# [  4]   0.00-30.00  sec  3.45 GBytes    987 Mbits/sec

# speedtest-cli: 测试到互联网的带宽
speedtest-cli
speedtest-cli --simple           # 简单输出
speedtest-cli --list            # 服务器列表
```

## 4.2 网络质量

```bash
# 延迟测试
ping -c 100 8.8.8.8 | tail -1

# 抖动测试
ping -c 100 8.8.8.8
# 分析time列的标准差

# 丢包测试
ping -c 1000 -s 1400 8.8.8.8
# 查看packet loss

# 网络质量综合测试
# 使用iperf3测试TCP带宽
# 使用ping测试延迟和抖动
# 使用traceroute测试路由跳数
```

---

# 5. 监控体系

## 5.1 关键指标

```
┌─────────────────────────────────────────────────────────────────┐
│                    网络监控关键指标                               │
└─────────────────────────────────────────────────────────────────┘

性能指标:
┌─────────────────────────────────────────────────────────────────┐
│ 带宽/吞吐量 (Throughput)                                       │
│ - 实际数据传输速率                                              │
│ - 单位: bps, Kbps, Mbps, Gbps                                 │
│ - 测量: iperf3                                                │
├─────────────────────────────────────────────────────────────────┤
│ 延迟 (Latency)                                                 │
│ - 数据包往返时间 (RTT)                                          │
│ - 单位: ms                                                     │
│ - 测量: ping, traceroute                                       │
├─────────────────────────────────────────────────────────────────┤
│ 抖动 (Jitter)                                                  │
│ - 延迟的变化程度                                                │
│ - 单位: ms                                                     │
│ - 测量: ping统计                                               │
├─────────────────────────────────────────────────────────────────┤
│ 丢包率 (Packet Loss)                                           │
│ - 丢失数据包的比例                                              │
│ - 单位: %                                                      │
│ - 测量: ping                                                   │
└─────────────────────────────────────────────────────────────────┘

连接指标:
┌─────────────────────────────────────────────────────────────────┐
│ 连接数                                                        │
│ - TCP/UDP连接数                                                │
│ - 状态分布 (ESTABLISHED, TIME_WAIT等)                          │
├─────────────────────────────────────────────────────────────────┤
│ 连接错误                                                       │
│ - 重传率                                                       │
│ - 丢包率                                                       │
├─────────────────────────────────────────────────────────────────┤
│ 带宽利用率                                                     │
│ - 实际使用/可用带宽                                            │
└─────────────────────────────────────────────────────────────────┘
```

## 5.2 监控工具

```bash
# iftop: 实时流量监控
sudo iftop -i eth0

# nethogs: 按进程显示流量
sudo nethogs

# iptraf-ng: 交互式流量监控
sudo iptraf-ng

# bmon: 带宽监控
bmon

# vnStat: 流量统计
vnstat
vnstat -l                    # 实时监控
vnstat -d                    # 每日统计
vnstat -h                    # 每小时统计
```

## 5.3 自动化监控

```bash
# Prometheus + node_exporter
# 指标端点: /metrics

# 常用网络指标:
# node_network_receive_bytes_total
# node_network_transmit_bytes_total
# node_network_receive_packets_total
# node_network_transmit_packets_total
# node_netstat_Tcp_CurrEstab

# Grafana看板
# 导入node_exporter看板
```

---

## 本章小结

- **ping**测试连通性和延迟, 基于ICMP协议
- **traceroute/mtr**追踪数据包路由路径
- **ss/netstat**查看网络连接状态和统计
- **tcpdump**是最强大的命令行抓包工具
- **iperf3**用于测试网络带宽
- **iftop/nethogs**用于实时流量监控
- 监控关键指标: 带宽、延迟、抖动、丢包率、连接数

**关键命令回顾:**

```bash
ping -c 4, traceroute, mtr
ss -tan, netstat -an, ss -s
tcpdump -i eth0 port 80, tcpdump -w file.pcap
iperf3 -s, iperf3 -c
iftop, nethogs, bmon
```