# Network专题

## 概述

本专题提供从基础到专家级的网络教程，涵盖网络基础、TCP/IP协议、路由、DNS原理、网络安全、防火墙、VPN隧道、网络监控和故障排除。

## 目录结构

```
network-specification/
├── README.md                              # 本文件
├── 01-network-fundamentals/              # 网络基础
│   ├── 01-network-fundamentals.md
│   └── codes/
│       └── bash-01.sh ~ bash-06.sh
├── 02-tcpip-protocol/                    # TCP/IP协议
│   ├── 02-tcpip-protocol.md
│   └── codes/
│       └── bash-01.sh ~ bash-07.sh
├── 03-routing/                           # 路由
│   ├── 03-routing.md
│   └── codes/
│       └── bash-01.sh ~ bash-07.sh
├── 04-dns-principles/                    # DNS原理
│   ├── 04-dns-principles.md
│   └── codes/
│       └── bash-01.sh ~ bash-06.sh
├── 05-network-security/                  # 网络安全
│   ├── 05-network-security.md
│   └── codes/
│       └── bash-01.sh ~ bash-07.sh
├── 06-firewall/                         # 防火墙
│   ├── 06-firewall.md
│   └── codes/
│       └── bash-01.sh ~ bash-11.sh
├── 07-vpn-tunnel/                       # VPN隧道
│   ├── 07-vpn-tunnel.md
│   └── codes/
│       └── bash-01.sh ~ bash-07.sh
├── 08-network-monitoring/                # 网络监控
│   ├── 08-network-monitoring.md
│   └── codes/
│       └── bash-01.sh ~ bash-11.sh
├── 09-troubleshooting/                  # 故障排除
│   ├── 09-troubleshooting.md
│   └── codes/
│       └── bash-01.sh ~ bash-13.sh
├── VERIFICATION.md                       # 代码验证说明
├── verify-network.ps1                    # Windows验证脚本
└── verify-network.sh                     # Linux/macOS验证脚本
```

## 快速开始

### 查看网络配置

```bash
ip addr
ifconfig
netstat -tuln
```

### 测试网络连通性

```bash
ping -c 4 8.8.8.8
traceroute 8.8.8.8
```

## 章节运行指南

### 01-network-fundamentals - 网络基础

**运行命令：**
```bash
cd 01-network-fundamentals/codes
bash bash-01.sh
```

### 02-tcpip-protocol - TCP/IP协议

**运行命令：**
```bash
cd 02-tcpip-protocol/codes
bash bash-01.sh
```

### 03-routing - 路由

**运行命令：**
```bash
cd 03-routing/codes
bash bash-01.sh
```

### 04-dns-principles - DNS原理

**运行命令：**
```bash
cd 04-dns-principles/codes
bash bash-01.sh
```

### 05-network-security - 网络安全

**运行命令：**
```bash
cd 05-network-security/codes
bash bash-01.sh
```

### 06-firewall - 防火墙

**运行命令：**
```bash
cd 06-firewall/codes
bash bash-01.sh
```

### 07-vpn-tunnel - VPN隧道

**运行命令：**
```bash
cd 07-vpn-tunnel/codes
bash bash-01.sh
```

### 08-network-monitoring - 网络监控

**运行命令：**
```bash
cd 08-network-monitoring/codes
bash bash-01.sh
```

### 09-troubleshooting - 故障排除

**运行命令：**
```bash
cd 09-troubleshooting/codes
bash bash-01.sh
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-network-fundamentals | bash | 6 |
| 02-tcpip-protocol | bash | 7 |
| 03-routing | bash | 7 |
| 04-dns-principles | bash | 6 |
| 05-network-security | bash | 7 |
| 06-firewall | bash | 11 |
| 07-vpn-tunnel | bash | 7 |
| 08-network-monitoring | bash | 11 |
| 09-troubleshooting | bash | 13 |

## 学习路径

### 初级路径

1. [01-network-fundamentals](./01-network-fundamentals/) - 掌握网络基础
2. [02-tcpip-protocol](./02-tcpip-protocol/) - 掌握TCP/IP协议

### 中级路径

1. [03-routing](./03-routing/) - 掌握路由
2. [04-dns-principles](./04-dns-principles/) - 掌握DNS原理
3. [05-network-security](./05-network-security/) - 掌握网络安全

### 高级路径

1. [06-firewall](./06-firewall/) - 掌握防火墙
2. [07-vpn-tunnel](./07-vpn-tunnel/) - 掌握VPN隧道
3. [08-network-monitoring](./08-network-monitoring/) - 掌握网络监控
4. [09-troubleshooting](./09-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Linux系统或WSL
- 网络工具（ip, ifconfig, netstat, ping等）

## 常见问题

### Q: 网络连接失败？

A: 检查网络配置和路由表：
```bash
ip addr
ip route
ping 8.8.8.8
```

### Q: 端口被占用？

A: 查看端口占用情况：
```bash
netstat -tuln | grep PORT
```

### Q: DNS解析失败？

A: 检查DNS配置：
```bash
cat /etc/resolv.conf
nslookup example.com
```
