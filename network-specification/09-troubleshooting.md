# 网络常见错误处理

## 本章导学

**学完本章后，你将能够：**

- 掌握网络连接问题的诊断思路
- 快速定位网络故障原因
- 解决常见的网络问题

**学习方法：**

```
问题现象 → 诊断步骤 → 排查命令 → 解决方案
```

---

# 1. 连通性问题

## 1.1 无法ping通

```bash
# 诊断步骤
# 1. 确认本地网络配置
ip addr show
ip route show

# 2. 测试本地网关
ping -c 3 192.168.1.1

# 3. 测试DNS
ping -c 3 8.8.8.8
ping -c 3 google.com

# 常见原因和解决方案
# 1. 网卡未启用
ip link set eth0 up

# 2. IP配置错误
ip addr add 192.168.1.100/24 dev eth0

# 3. 网关不通
# 检查路由
ip route show
# 添加默认路由
ip route add default via 192.168.1.1

# 4. 防火墙阻止ICMP
iptables -L -n | grep ICMP
```

## 1.2 DNS解析失败

```bash
# 诊断步骤
# 1. 检查DNS服务器
cat /etc/resolv.conf

# 2. 测试DNS服务器
dig @8.8.8.8 example.com
nslookup example.com 8.8.8.8

# 3. 检查本机缓存
systemd-resolve --flush-caches

# 常见原因
# 1. DNS服务器配置错误
# 修复
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# 2. DNS服务器不可达
# 更换DNS服务器
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# 3. hosts文件污染
cat /etc/hosts
```

---

# 2. 端口和服务问题

## 2.1 端口无法连接

```bash
# 诊断步骤
# 1. 检查服务是否监听
ss -tuln | grep :80
netstat -tuln | grep :80

# 2. 检查服务状态
systemctl status nginx

# 3. 测试本地连接
curl -v localhost:80
telnet localhost 80

# 4. 检查防火墙
iptables -L -n | grep :80
firewall-cmd --list-all

# 常见原因
# 1. 服务未启动
systemctl start nginx
systemctl enable nginx

# 2. 端口未监听
# 检查配置文件
ss -tuln | grep nginx

# 3. 防火墙阻止
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
firewall-cmd --add-port=80/tcp --permanent
```

## 2.2 连接被拒绝

```bash
# 诊断步骤
# 1. 查看连接状态
ss -tan | grep :80

# 2. 查看服务日志
journalctl -u nginx -n 50

# 3. 检查资源限制
ulimit -n
cat /proc/sys/fs/file-max

# 常见原因
# 1. 连接数满
# 查看最大连接数
ss -s
# 调整限制
ulimit -n 65535

# 2. 服务崩溃
systemctl restart nginx
```

---

# 3. 路由问题

## 3.1 路由不可达

```bash
# 诊断步骤
# 1. 查看路由表
ip route show
route -n

# 2. 测试路由
traceroute 10.0.0.1
ip route get 10.0.0.1

# 3. 检查网关
ip neigh show

# 常见原因
# 1. 缺少路由
ip route add 10.0.0.0/24 via 192.168.1.1

# 2. 默认路由缺失
ip route add default via 192.168.1.1

# 3. 路由冲突
ip route show
# 删除冲突路由
ip route del 10.0.0.0/24
```

## 3.2 网关不可达

```bash
# 诊断步骤
# 1. 检查网关
ip route show | grep default

# 2. 测试网关
ping -c 3 192.168.1.1

# 3. 检查ARP表
ip neigh show

# 常见原因
# 1. 网关配置错误
ip route change default via 192.168.1.254

# 2. 网关不可达
# 检查物理连接
ip link show
ethtool eth0
```

---

# 4. 性能问题

## 4.1 网络延迟高

```bash
# 诊断步骤
# 1. 测试各段延迟
traceroute target_ip
mtr target_ip

# 2. 分析瓶颈
# 哪一跳延迟最高?

# 3. 检查网络负载
iftop -i eth0
nethogs

# 常见原因
# 1. 带宽不足
# 使用iperf3测试
iperf3 -c server_ip

# 2. 网络拥塞
# 限速或QoS
tc qdisc show

# 3. DNS慢
# 使用快速DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

## 4.2 连接频繁断开

```bash
# 诊断步骤
# 1. 检查TCP连接状态
ss -tan | awk '{print $1}' | sort | uniq -c

# 2. 检查TIME_WAIT
ss -tan state time-wait | wc -l

# 3. 检查错误
netstat -s | grep -i error
cat /proc/net/netstat

# 常见原因
# 1. NAT连接数满
# 查看NAT表大小
cat /proc/sys/net/netfilter/nf_conntrack_max
# 调整大小
echo 262144 > /proc/sys/net/netfilter/nf_conntrack_max

# 2. TCP参数优化
sysctl -w net.ipv4.tcp_fin_timeout=30
```

---

# 5. 安全相关问题

## 5.1 ARP欺骗

```bash
# 诊断
arp -a
ip neigh show

# 发现问题
# 查看是否有重复MAC
arp -a | awk '{print $4}' | sort | uniq -c

# 防御
# 静态ARP绑定
ip neigh add 192.168.1.1 lladdr AA:BB:CC:DD:EE:FF dev eth0
# 写入/etc/ethers
echo "192.168.1.1 AA:BB:CC:DD:EE:FF" >> /etc/ethers

# 启用ARP防护
echo 1 > /proc/sys/net/ipv4/conf/all/arp_filter
```

## 5.2 DDoS攻击

```bash
# 诊断
# 查看连接数异常
ss -s

# 查看TOP IP
ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# 查看流量异常
iftop -i eth0

# 防御
# 限流
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 封禁IP
iptables -A INPUT -s 1.2.3.4 -j DROP
```

---

# 6. 工具和脚本

## 6.1 网络诊断脚本

```bash
#!/bin/bash
# 网络诊断脚本

echo "=== 网络诊断报告 ==="
echo "时间: $(date)"
echo ""

echo "--- IP配置 ---"
ip addr show
echo ""

echo "--- 路由表 ---"
ip route show
echo ""

echo "--- DNS配置 ---"
cat /etc/resolv.conf
echo ""

echo "--- 网络连接 ---"
ss -tuln | head -20
echo ""

echo "--- 网关连通性 ---"
ping -c 3 8.8.8.8 2>&1 | tail -2
echo ""

echo "--- DNS解析 ---"
nslookup google.com 2>&1 | tail -5
```

## 6.2 连接监控脚本

```bash
#!/bin/bash
# 监控连接状态

while true; do
    clear
    echo "=== 连接监控 ==="
    date
    echo ""
    echo "ESTABLISHED: $(ss -tan state established | wc -l)"
    echo "TIME-WAIT:   $(ss -tan state time-wait | wc -l)"
    echo "CLOSE-WAIT:  $(ss -tan state close-wait | wc -l)"
    echo ""
    echo "TOP 5 来源IP:"
    ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5
    sleep 5
done
```

---

## 本章小结

- **连通性问题**: 从本地到网关到外网逐步排查
- **DNS问题**: 检查/etc/resolv.conf和DNS服务器可达性
- **端口问题**: 检查服务状态、防火墙、连接数限制
- **路由问题**: 检查路由表、网关、ARP表
- **性能问题**: 使用iftop、ss分析网络流量和连接状态
- **安全问题**: 防范ARP欺骗和DDoS攻击

**关键诊断命令:**

```bash
# 基础诊断
ping, traceroute, mtr, dig, nslookup

# 连接状态
ss -tan, netstat -an, ss -s

# 流量监控
iftop, nethogs, tcpdump

# 路由
ip route show, ip route get

# 防火墙
iptables -L -n, firewall-cmd --list-all
```