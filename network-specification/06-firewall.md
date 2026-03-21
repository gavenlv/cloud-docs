# 防火墙和iptables

## 本章导学

**学完本章后，你将能够：**

- 理解Linux防火墙的**netfilter框架原理**
- 掌握iptables的四表五链结构
- 熟练配置NAT和包过滤规则
- 理解nftables和firewalld的工作方式
- 从**内核角度**理解数据包是如何被防火墙处理的

**学习方法：**

```
netfilter框架 → iptables四表五链 → 规则匹配 → NAT → 实战配置
```

---

# 1. netfilter框架

## 1.1 netfilter概述

```
┌─────────────────────────────────────────────────────────────────┐
│                    netfilter框架                                 │
└─────────────────────────────────────────────────────────────────┘

# netfilter是Linux内核的网络包处理框架
# 位于网络协议栈的关键位置, 对数据包进行拦截和处理

┌─────────────────────────────────────────────────────────────────┐
│                    数据包流向                                    │
└─────────────────────────────────────────────────────────────────┘

        收到的包
             │
             ▼
    ┌────────────────┐
    │  PREROUTING   │  ← 路由判决之前
    │  (mangle, nat)│
    └───────┬────────┘
            │
            ▼
    ┌────────────────┐
    │   路由判决     │  ← 判断目标主机还是转发
    └───────┬────────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌──────────┐  ┌────────────────┐
│  INPUT   │  │   FORWARD     │
│ (mangle, │  │  (mangle,     │
│  filter) │  │   filter)     │
└────┬─────┘  └───────┬────────┘
     │                │
     ▼                ▼
┌──────────┐  ┌────────────────┐
│ 本地进程  │  │    POSTROUTING│
│          │  │  (mangle, nat)│
└──────────┘  └────────────────┘

# 数据包分类:
# 1. 目的地是本机: PREROUTING → INPUT → 本地进程
# 2. 需要转发的:   PREROUTING → FORWARD → POSTROUTING
# 3. 从本机发出:   本地进程 → OUTPUT → POSTROUTING
```

## 1.2 HOOK点详解

```bash
# netfilter的5个HOOK点:

1. NF_INET_PRE_ROUTING  (PREROUTING)
   - 数据包接收后, 路由决策之前
   - 用于NAT (DNAT)

2. NF_INET_LOCAL_IN  (INPUT)
   - 目的地是本机的数据包, 路由决策之后
   - 用于包过滤

3. NF_INET_FORWARD  (FORWARD)
   - 需要转发到其他主机的数据包
   - 用于包过滤

4. NF_INET_LOCAL_OUT  (OUTPUT)
   - 从本机发出的数据包
   - 用于包过滤, NAT (SNAT)

5. NF_INET_POST_ROUTING  (POSTROUTING)
   - 数据包发送前, 路由决策之后
   - 用于NAT (SNAT)
```

---

# 2. iptables四表五链

## 2.1 表和链的关系

```
┌─────────────────────────────────────────────────────────────────┐
│                    iptables四表五链                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        四表                                      │
├─────────────────────────────────────────────────────────────────┤
│ filter    │ 包过滤      │ INPUT, FORWARD, OUTPUT               │
│ nat       │ 网络地址转换 │ PREROUTING, INPUT, OUTPUT,          │
│           │             │ POSTROUTING                          │
│ mangle    │ 修改数据包   │ 所有链                               │
│ raw       │ 原始数据    │ PREROUTING, OUTPUT                   │
│ security  │ SELinux    │ INPUT, FORWARD, OUTPUT               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        五链                                      │
├─────────────────────────────────────────────────────────────────┤
│ PREROUTING  │ 路由之前  │ DNAT                                │
│ INPUT       │ 目的地是本机│ filter                              │
│ FORWARD     │ 转发      │ filter                              │
│ OUTPUT      │ 本机发出   │ filter, nat                        │
│ POSTROUTING │ 路由之后  │ SNAT                                │
└─────────────────────────────────────────────────────────────────┘

# 表和链的包含关系:
┌──────────────┬──────────────────────────────────────────────────┐
│ 表           │ 包含的链                                          │
├──────────────┼──────────────────────────────────────────────────┤
│ filter      │ INPUT, FORWARD, OUTPUT                            │
│ nat         │ PREROUTING, INPUT, OUTPUT, POSTROUTING            │
│ mangle      │ PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING   │
│ raw         │ PREROUTING, OUTPUT                                │
└──────────────┴──────────────────────────────────────────────────┘

# 处理优先级 (按顺序):
# raw → mangle → nat → filter → security
```

## 2.2 数据包处理流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    完整数据包处理流程                             │
└─────────────────────────────────────────────────────────────────┘

收到数据包
      │
      ▼
┌─────────────────────┐
│ 1. PREROUTING       │
│    raw (Connection Tracking) │
│    mangle           │
│    nat (DNAT)       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. 路由判决         │
│    目的地: 本机/转发 │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐  ┌─────────────────┐
│ 3. INPUT │  │ 4. FORWARD     │
│  mangle  │  │ mangle          │
│  filter  │  │ filter          │
│  security│  │ security        │
└────┬────┘  └────────┬────────┘
     │                 │
     ▼                 ▼
┌─────────┐  ┌─────────────────┐
│ 本地进程 │  │ 5. POSTROUTING │
└─────────┘  │ mangle          │
            │ nat (SNAT)      │
            └─────────────────┘

OUTPUT路径 (本机发出的包):
┌─────────────────────┐
│ 1. OUTPUT          │
│    raw             │
│    mangle          │
│    nat (SNAT)      │
│    filter          │
│    security        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 2. POSTROUTING     │
│    mangle          │
│    nat (SNAT)      │
└─────────────────────┘
```

---

# 3. iptables命令详解

## 3.1 基本语法

```bash
# iptables语法
iptables [-t table] -A chain [options] -j target

# 常用选项
# -A chain        添加规则到链 (APPEND)
# -I chain [num]  插入规则到链 (INSERT)
# -D chain [num]  删除规则 (DELETE)
# -R chain [num]  替换规则 (REPLACE)
# -L [chain]      列出规则 (LIST)
# -F [chain]      清空规则 (FLUSH)
# -N chain        新建链 (NEW)
# -X chain        删除链 (DELETE)
# -Z              清零计数器

# 匹配选项
# -p protocol     协议 (tcp, udp, icmp, all)
# -s source       源地址
# -d destination  目标地址
# --sport source  源端口
# --dport dest   目标端口
# -i input-if    输入接口
# -o output-if   输出接口
# -m state       连接状态
# -m comment     注释
```

## 3.2 常用匹配

```bash
# 协议匹配
iptables -A INPUT -p tcp -j ACCEPT
iptables -A INPUT -p udp -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# 地址匹配
iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -s 10.0.0.1 -j DROP
iptables -A INPUT ! -s 192.168.1.0/24 -j DROP

# 端口匹配
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 端口范围
iptables -A INPUT -p tcp --dport 1000:2000 -j ACCEPT

# 接口匹配
iptables -A INPUT -i eth0 -j ACCEPT
iptables -A OUTPUT -o eth0 -j ACCEPT

# 复合匹配
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
```

## 3.3 连接状态

```bash
# 连接状态 (Connection Tracking)
# NEW       - 新连接
# ESTABLISHED - 已建立的连接
# RELATED   - 相关连接 (如FTP数据传输)
# INVALID   - 无效连接
# UNTRACKED - 未跟踪的连接

# 允许已建立连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH新连接
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# 允许HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
```

---

# 4. NAT配置

## 4.1 SNAT和DNAT

```
┌─────────────────────────────────────────────────────────────────┐
│                    NAT类型                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ SNAT (Source NAT)                                               │
│  修改源IP, 用于内网访问外网                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [内网PC] ──→ [网关/防火墙] ──→ [互联网]                        │
│  192.168.1.100        203.0.113.1                              │
│                                                                 │
│  出方向: 源IP 192.168.1.100 → 203.0.113.1                      │
│  返回时: 目的IP 203.0.113.1 → 192.168.1.100                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ DNAT (Destination NAT)                                         │
│  修改目标IP, 用于外网访问内网服务                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [互联网] ──→ [网关/防火墙] ──→ [内网服务器]                    │
│              203.0.113.1         192.168.1.100                  │
│                                                                 │
│  进方向: 目标IP 203.0.113.1 → 192.168.1.100                    │
│  返回时: 源IP 192.168.1.100 → 203.0.113.1                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 4.2 NAT配置命令

```bash
# SNAT (源地址转换) - POSTROUTING链
# 固定源IP
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 203.0.113.1

# MASQUERADE (自动获取出口IP)
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# DNAT (目标地址转换) - PREROUTING链
# 端口转发
iptables -t nat -A PREROUTING -p tcp -d 203.0.113.1 --dport 80 \
         -j DNAT --to-destination 192.168.1.100:80

# 转发到内部其他端口
iptables -t nat -A PREROUTING -p tcp -d 203.0.113.1 --dport 8080 \
         -j DNAT --to-destination 192.168.1.100:80

# 本机端口转发 - OUTPUT链
iptables -t nat -A OUTPUT -p tcp --dport 80 \
         -j REDIRECT --to-ports 8080
```

---

# 5. 实战配置

## 5.1 通用防火墙配置

```bash
#!/bin/bash
# 通用防火墙配置脚本

# 清除现有规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许loopback
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH (22端口)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP/HTTPS (80/443端口)
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# 允许Ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 允许DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# 记录被拒绝的包
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables DENIED: "

# 拒绝并记录其他所有
iptables -A INPUT -j LOG --log-prefix "iptables DROP: "
iptables -A INPUT -j DROP

# 保存规则
iptables-save > /etc/iptables/rules.v4
```

## 5.2 端口转发配置

```bash
# 场景: 将外网访问80端口的请求转发到内网192.168.1.100:8080

# 1. 开启IP转发
echo 1 > /proc/sys/net/ipv4/ip_forward
# 永久生效
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# 2. 添加DNAT规则
iptables -t nat -A PREROUTING -p tcp -i eth0 -d 203.0.113.1 --dport 80 \
         -j DNAT --to-destination 192.168.1.100:8080

# 3. 添加SNAT规则 (让返回包能回来)
iptables -t nat -A POSTROUTING -p tcp -d 192.168.1.100 --dport 8080 \
         -j SNAT --to-source 192.168.1.1

# 4. 允许转发
iptables -A FORWARD -p tcp -d 192.168.1.100 --dport 8080 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
```

## 5.3 防攻击配置

```bash
# 防止SYN Flood
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 防止ICMP Flood
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 防止端口扫描
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# 防止IP欺骗
iptables -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT

# 防止广播
iptables -A INPUT -d 255.255.255.255 -j DROP
iptables -A INPUT -d 224.0.0.1 -j DROP
```

---

# 6. nftables和firewalld

## 6.1 nftables

```bash
# nftables是iptables的下一代
# 统一的表结构, 更好的性能

# 查看nftables规则
nft list ruleset

# 创建表
nft add table ip filter

# 创建链
nft add chain ip filter input { type filter hook input priority 0 \; }

# 添加规则
nft add rule ip filter input tcp dport 22 accept

# 替换iptables
# Debian/Ubuntu
update-alternatives --set iptables /usr/sbin/iptables-nft
update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
```

## 6.2 firewalld

```bash
# firewalld是CentOS/RHEL 7+的默认防火墙管理工具
# 基于zone概念

# 查看状态
systemctl status firewalld
firewall-cmd --state

# 查看默认zone
firewall-cmd --get-default-zone

# 查看活动zone
firewall-cmd --get-active-zones

# 列出规则
firewall-cmd --list-all
firewall-cmd --list-all --zone=public

# 添加服务
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent

# 添加端口
firewall-cmd --add-port=8080/tcp --permanent

# 重载配置
firewall-cmd --reload

# 常用zone:
# drop: 丢弃所有
# block: 拒绝所有
# public: 公共网络
# external: 外部网络 (NAT)
# dmz: 非军事区
# work: 工作网络
# home: 家庭网络
# internal: 内部网络
# trusted: 信任所有
```

---

## 本章小结

- **netfilter**是Linux内核的网络包处理框架, 通过HOOK点拦截数据包
- **iptables**是用户空间工具, 管理四表五链的规则
- **四表**: filter(过滤), nat(NAT), mangle(修改), raw(原始)
- **五链**: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING
- **数据包处理流程**: PREROUTING → 路由 → INPUT/FORWARD → POSTROUTING
- **NAT**: SNAT用于内网访问外网, DNAT用于端口转发
- **nftables**是iptables的下一代, 提供更好的性能和统一语法

**关键命令回顾:**

```bash
# iptables
iptables -L -n -v, iptables -A INPUT -j ACCEPT
iptables -t nat -A PREROUTING -j DNAT
iptables -t nat -A POSTROUTING -j MASQUERADE

# firewalld
firewall-cmd --list-all, firewall-cmd --add-service

# nftables
nft list ruleset, nft add rule
```