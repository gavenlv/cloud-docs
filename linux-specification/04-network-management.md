# 网络管理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux网络协议栈的**底层原理**（从网卡到应用的数据流）
- 掌握网络接口配置和路由管理
- 熟练使用网络诊断工具
- 理解iptables/netfilter防火墙机制
- 从**内核角度**理解数据包是如何被处理和转发的

**学习方法：**

```
网络协议栈 → 接口配置 → 路由管理 → 防火墙 → 诊断工具 → 实战操作
```

---

# 1. Linux网络协议栈

## 1.1 协议栈架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux网络协议栈                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      应用层 (Application)                        │
│               (HTTP, FTP, SSH, DNS, SMTP)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ socket API (connect, send, recv)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      套接字层 (Socket)                           │
│                (sock, inet_protos, BSD socket)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      传输层 (Transport)                          │
│                      (TCP, UDP, SCTP)                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ TCP          │  │ UDP          │  │ SCTP         │          │
│  │ 状态机       │  │ 无连接       │  │ 多宿主       │          │
│  │ 流量控制     │  │ 面向报文     │  │ 关联管理     │          │
│  │ 拥塞控制     │  │ 不可靠       │  │ 可靠性       │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      网络层 (Network)                             │
│                       (IP, ICMP, IGMP)                          │
│  ┌─────────────┐  ┌─────────────┐                            │
│  │ IP           │  │ ICMP         │                            │
│  │ 路由选择     │  │ ping/traceroute│                          │
│  │ 分片/重组   │  │ 错误报告     │                            │
│  │ TTL          │  │              │                            │
│  └─────────────┘  └─────────────┘                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      数据链路层 (Link)                           │
│                   (Ethernet, ARP, VLAN)                         │
│  ┌─────────────┐  ┌─────────────┐                            │
│  │ Ethernet     │  │  ARP         │                            │
│  │ MAC地址      │  │  IP→MAC映射  │                            │
│  │ MTU=1500    │  │              │                            │
│  └─────────────┘  └─────────────┘                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      物理层 (Physical)                           │
│                    (网卡驱动, PHY芯片)                           │
└─────────────────────────────────────────────────────────────────┘
```

## 1.2 数据包接收流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    数据包接收流程                                  │
└─────────────────────────────────────────────────────────────────┘

1. 网卡接收数据包 (DMA到环形缓冲区)
       │
       ▼
2. 硬中断通知CPU
       │
       ▼
3. NAPI/软中断处理
       │
       ▼
4. 协议栈处理 (IP → TCP/UDP)
       │
       ▼
5. 插入 socket接收队列
       │
       ▼
6. 应用通过 recv() 读取
```

```bash
# 查看网络配置
cat /proc/sys/net/ipv4/tcp_rmem  # TCP接收缓冲区
cat /proc/sys/net/ipv4/tcp_wmem  # TCP发送缓冲区
cat /proc/sys/net/core/rmem_max  # 最大接收缓冲区
cat /proc/sys/net/core/wmem_max  # 最大发送缓冲区
```

---

# 2. 网络接口配置

## 2.1 ip命令详解

```bash
# ip - 现代网络配置命令

# 查看接口
ip link show
ip addr show
ip -s link show

# 示例输出:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP
#     link/ether 00:11:22:33:44:55 brd ff:ff:ff:ff:ff:ff

# 接口操作
ip link set eth0 up           # 启用接口
ip link set eth0 down         # 禁用接口
ip link set eth0 promisc on   # 混杂模式
ip link set eth0 mtu 9000     # 设置MTU

# IP地址操作
ip addr add 192.168.1.100/24 dev eth0    # 添加IP
ip addr del 192.168.1.100/24 dev eth0    # 删除IP
ip addr show eth0                              # 查看接口IP
ip addr flush dev eth0                          # 清除所有IP

# 查看MAC地址
ip link show eth0 | grep ether
ip -o link show eth0 | awk '{print $17}'

# 查看接口统计
ip -s link show eth0
ip -s -s link show eth0   # 详细统计
```

## 2.2 路由管理

```bash
# 路由表

# 查看路由表
ip route show
ip route show table all

# 示例输出:
# default via 192.168.1.1 dev eth0 proto static
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100

# 添加路由
ip route add 10.0.0.0/24 via 192.168.1.1 dev eth0    # 添加子网路由
ip route add default via 192.168.1.1 dev eth0         # 添加默认路由
ip route add 172.16.0.0/16 dev eth1                   # 添加直连路由

# 删除路由
ip route del 10.0.0.0/24
ip route del default

# 查看特定路由
ip route get 8.8.8.8
# 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.100

# 多路由表
ip route show table 100
ip route add default via 10.0.0.1 dev eth1 table 100

# 路由规则
ip rule show
# 0:      from all lookup local
# 32766:  from all lookup main
# 32767:  from all lookup default

ip rule add from 192.168.1.0/24 table 100
ip rule del from 192.168.1.0/24 table 100
```

## 2.3 网络配置实战

```bash
# 场景: 配置静态IP

# 方法1: 使用ip命令 (临时)
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add default via 192.168.1.1

# 方法2: 配置网络接口 (Debian/Ubuntu)
cat > /etc/network/interfaces << 'EOF'
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
EOF

sudo systemctl restart networking

# 方法3: Netplan (Ubuntu 18.04+)
cat > /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF

sudo netplan apply

# 方法4: RHEL/CentOS
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << 'EOF'
TYPE=Ethernet
BOOTPROTO=static
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=192.168.1.100
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
EOF

sudo systemctl restart network
```

---

# 3. 网络诊断工具

## 3.1 连通性测试

```bash
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
```

## 3.2 端口和连接

```bash
# netstat - 网络统计 (已过时,推荐使用ss)
netstat -tuln                  # TCP/UDP监听端口
netstat -an                    # 所有连接
netstat -r                     # 路由表
netstat -i                      # 接口统计
netstat -s                      # 协议统计

# ss - 现代socket统计 (替代netstat)
ss -tuln                       # TCP/UDP监听端口
ss -tan                        # 所有TCP连接
ss -ua                         # 所有UDP连接
ss -s                          # 统计汇总
ss -p                          # 显示进程
ss -o state established '(dport = :80 or sport = :80)'  # 过滤

# 输出字段说明:
# State:  TCP状态 (ESTABLISHED, LISTEN, TIME_WAIT, etc)
# Recv-Q: 接收队列 (字节)
# Send-Q: 发送队列 (字节)
# Local Address: 本地地址
# Peer Address: 远端地址

# 示例:
ss -tuln
# Netid  State   Recv-Q   Send-Q     Local Address:Port     Peer Address:Port
# tcp    LISTEN  0        128              0.0.0.0:22          0.0.0.0:*
# tcp    LISTEN  0        128                    *:80                *:*
```

## 3.3 抓包分析

```bash
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
```

```bash
# wireshark/tshark - 图形/命令行抓包分析

# tshark - 命令行wireshark
tshark -i eth0
tshark -r capture.pcap
tshark -r capture.pcap -Y "http.request"  # 过滤HTTP请求
tshark -r capture.pcap -T fields -e ip.src -e http.host  # 导出字段

# 常用过滤表达式
# ip.addr == 192.168.1.1
# tcp.port == 80
# http.request.method == "GET"
# tcp.flags.syn == 1  # SYN包
# tcp.flags.fin == 1  # FIN包
```

## 3.4 其他诊断工具

```bash
# arp - ARP缓存
arp -n                         # 查看ARP表
arp -s 192.168.1.1 00:11:22:33:44:55  # 静态ARP
arp -d 192.168.1.1              # 删除ARP条目

# arpwatch - ARP监控
sudo apt install arpwatch
sudo systemctl start arpwatch

# dig - DNS查询
dig @8.8.8.8 example.com
dig +short example.com          # 简短输出
dig -x 192.168.1.1             # 反向查询
dig example.com +trace          # 追踪DNS解析

# nslookup - DNS查询 (已过时)
nslookup example.com

# host - DNS查询
host example.com
host -t mx example.com          # MX记录

# nc/netcat - 网络瑞士军刀
nc -l 8080                     # 监听端口
nc 192.168.1.1 8080             # 连接端口
nc -zv 192.168.1.1 80          # 扫描端口
echo "GET /" | nc example.com 80  # 发送原始请求

# nmap - 端口扫描
nmap -sT localhost              # TCP连接扫描
nmap -sU localhost              # UDP扫描
nmap -sP 192.168.1.0/24        # 主机发现
nmap -O 192.168.1.1            # 操作系统检测
```

---

# 4. iptables/netfilter防火墙

## 4.1 防火墙原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    netfilter Hooks                              │
└─────────────────────────────────────────────────────────────────┘

      数据包流向:
      ┌─────────┐
      │  发送   │◄──────── NF_INET_POST_ROUTING
      └────┬────┘
           │
    ┌──────▼──────┐
    │    OUTPUT   │──────── NF_INET_LOCAL_OUT
    └──────┬──────┘
           │
      ┌────▼────┐
      │ routing │
      └────┬────┘
           │
    ┌──────▼──────┐
    │   INPUT     │──────── NF_INET_PRE_ROUTING
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │  FORWARD    │
    └──────┬──────┘
           │
      ┌────▼────┐
      │  接收   │
      └─────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    iptables 表                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┬───────────────────────────────────────────────────┐
│  表         │  功能                                              │
├─────────────┼───────────────────────────────────────────────────┤
│  filter     │  包过滤 (INPUT, FORWARD, OUTPUT)                  │
│  nat        │  网络地址转换 (PREROUTING, INPUT, OUTPUT, POSTROUTING)│
│  mangle     │  包修改 (所有链)                                  │
│  raw        │  跟踪配置 (PREROUTING, OUTPUT)                    │
│  security   │  SELinux (INPUT, FORWARD, OUTPUT)                  │
└─────────────┴───────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    iptables 链                                   │
└─────────────────────────────────────────────────────────────────┘

# PREROUTING   - 数据包进入后,路由决策前
# INPUT        - 发往本机的数据包
# FORWARD      - 路由转发数据包
# OUTPUT       - 本机发出的数据包
# POSTROUTING  - 数据包离开前
```

## 4.2 iptables命令

```bash
# 基础语法
iptables -t filter -A INPUT -s 192.168.1.0/24 -j DROP
#   │        │    │    │              │
#   │        │    │    │              └─ 动作
#   │        │    │    └─ 源地址
#   │        │    └─ 链
#   │        └─ 表
#   └─ 操作 (-A添加, -D删除, -I插入, -L列表, -F清空)

# 动作 (Target)
# ACCEPT - 接受
# DROP   - 丢弃 (不响应)
# REJECT - 拒绝 (响应ICMP错误)
# LOG    - 记录日志
# SNAT   - 源NAT
# DNAT   - 目标NAT
# MASQUERADE - 动态SNAT

# 常用操作
iptables -L                           # 列出所有规则
iptables -L -n                        # 不解析IP
iptables -L -v                        # 详细
iptables -L -t nat                    # 查看NAT表
iptables -L INPUT --line-numbers      # 带行号

# 追加规则
iptables -A INPUT -p tcp --dport 22 -j ACCEPT     # 允许SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT     # 允许HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT    # 允许HTTPS
iptables -A INPUT -j DROP                        # 默认拒绝

# 插入规则
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT   # 插入到第1行

# 删除规则
iptables -D INPUT 3                              # 删除第3行
iptables -D INPUT -p tcp --dport 22 -j ACCEPT   # 删除匹配规则

# 清空规则
iptables -F                           # 清空filter表
iptables -t nat -F                    # 清空NAT表
iptables -X                           # 删除用户自定义链

# 设置默认策略
iptables -P INPUT DROP                 # 默认拒绝输入
iptables -P FORWARD DROP               # 默认拒绝转发
iptables -P OUTPUT ACCEPT              # 默认允许输出
```

## 4.3 连接跟踪

```bash
# conntrack - 连接跟踪

# 查看跟踪的连接
conntrack -L                         # 列出所有连接
conntrack -L -p tcp                   # 只看TCP
conntrack -L --state ESTABLISHED     # 已建立连接

# 示例输出:
# tcp      6 431999 ESTABLISHED src=192.168.1.100 dst=8.8.8.8 sport=54321 dport=443
# tcp      6 431999 ESTABLISHED src=8.8.8.8 dst=192.168.1.100 sport=443 dport=54321

# conntrack参数说明:
# -p: 协议
# --state: 连接状态 (ESTABLISHED, NEW, RELATED, INVALID)

# NAT相关
conntrack -L -n                      # 不解析IP

# conntrack-tools
# conntrackd - 连接跟踪守护进程 (用于高可用)
```

---

# 5. 网络高级配置

## 5.1 网桥 (Bridge)

```bash
# 网桥 - 用于虚拟机/容器网络

# 查看网桥
ip link show type bridge
brctl show

# 创建网桥
ip link add br0 type bridge
ip link set br0 up

# 添加接口到网桥
ip link set eth0 master br0
ip link set vnet0 master br0

# 从网桥移除
ip link set eth0 nomaster

# 删除网桥
ip link del br0

# brctl命令 (需要bridge-utils)
apt install bridge-utils
brctl addbr br0
brctl addif br0 eth0
brctl delif br0 eth0
brctl delbr br0

# 查看MAC地址表
brctl showmacs br0
```

## 5.2 VLAN

```bash
# VLAN - 虚拟局域网

# 加载VLAN模块
modprobe 8021q

# 创建VLAN接口
ip link add link eth0 name eth0.100 type vlan id 100
ip addr add 192.168.100.1/24 dev eth0.100
ip link set eth0.100 up

# 删除VLAN接口
ip link del eth0.100

# 查看VLAN配置
cat /proc/net/vlan/config
cat /proc/net/vlan/eth0.100

# vconfig命令 (旧)
apt install vlan
vconfig add eth0 100
vconfig set_flag eth0.100 1 1
```

## 5.3 Bonding/Teaming

```bash
# 网络绑定 - 聚合多个网卡

# 加载bonding模块
modprobe bonding mode=0

# 创建bond接口
ip link add bond0 type bond mode 802.3ad
ip link set eth0 down
ip link set eth1 down
ip link set eth0 master bond0
ip link set eth1 master bond0
ip link set bond0 up
ip addr add 192.168.1.100/24 dev bond0

# Bonding模式:
# mode 0: balance-rr (轮转)
# mode 1: active-backup (主备)
# mode 2: balance-xor (XOR)
# mode 3: broadcast (广播)
# mode 4: 802.3ad (LACP)
# mode 5: balance-tlb (自适应负载)
# mode 6: balance-alb (自适应负载)

# 查看bond状态
cat /proc/net/bonding/bond0
```

## 5.4 Tunnel (隧道)

```bash
# IP隧道

# 创建GRE隧道
ip tunnel add gre1 mode gre remote 10.0.0.2 local 10.0.0.1
ip addr add 192.168.10.1/24 dev gre1
ip link set gre1 up

# 创建IPIP隧道
ip tunnel add ipip1 mode ipip remote 10.0.0.2 local 10.0.0.1
ip addr add 192.168.20.1/24 dev ipip1
ip link set ipip1 up

# 删除隧道
ip tunnel del gre1

# 查看隧道
ip tunnel show

# WireGuard (现代VPN)
apt install wireguard
wg genkey | tee privatekey | wg pubkey > publickey
```

---

# 6. DNS客户端配置

## 6.1 resolv.conf

```bash
# /etc/resolv.conf - DNS配置

cat /etc/resolv.conf
# nameserver 8.8.8.8
# nameserver 8.8.4.4
# search localdomain

# 字段说明:
# nameserver - DNS服务器地址 (最多3个)
# search     - 搜索域 (可多个)
# domain     - 本地域名

# 注意事项:
# - 此文件通常由systemd-resolved或NetworkManager管理
# - 手动修改可能被覆盖
# - 使用 systemd-resolve --status 查看状态
```

## 6.2 本地DNS解析

```bash
# /etc/hosts - 本地静态解析

cat /etc/hosts
# 127.0.0.1   localhost
# ::1         localhost ip6-localhost ip6-loopback

# 添加自定义解析
echo "192.168.1.100 myserver.local" >> /etc/hosts
ping myserver.local

# /etc/nsswitch.conf - 名称解析顺序
grep "^hosts:" /etc/nsswitch.conf
# hosts:          files dns  <-- 先查/etc/hosts,再查DNS
```

---

## 本章小结

- **Linux网络协议栈**从应用层到物理层分层处理数据包
- **ip命令**是现代网络配置的核心工具,替代了ifconfig/route等
- **路由管理**通过路由表决定数据包的去向
- **iptables/netfilter**提供强大的包过滤和NAT功能
- **连接跟踪**是状态防火墙和NAT的基础
- **网络诊断工具**(ping/traceroute/tcpdump/ss)是排错必备
- **高级特性**(网桥/VLAN/bonding/tunnel)支持复杂网络拓扑

**关键命令回顾:**

```bash
# 接口和地址
ip link, ip addr, ip addr add/del

# 路由
ip route, ip rule

# 防火墙
iptables -L, iptables -A/I/D, iptables -t nat

# 诊断
ping, traceroute, mtr, tcpdump, ss, netstat

# 连接跟踪
conntrack -L
```