# VPN和隧道技术

## 本章导学

**学完本章后，你将能够：**

- 理解VPN的**工作原理和应用场景**
- 掌握常见VPN协议（IPSec、OpenVPN、WireGuard）
- 理解隧道技术（GRE、IP-in-IP）
- 掌握Linux隧道配置

**学习方法：**

```
VPN原理 → IPSec → OpenVPN → WireGuard → 隧道技术
```

---

# 1. VPN原理

## 1.1 VPN概述

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPN (Virtual Private Network)                 │
└─────────────────────────────────────────────────────────────────┘

# VPN通过公网建立加密的私有通道
# 模拟点对点专线, 但成本更低

# VPN核心功能:
# 1. 加密: 防止窃听
# 2. 认证: 验证身份
# 3. 隧道: 封装数据包
# 4. 访问控制: 控制资源访问

# 常见应用场景:
# 1. 远程办公: 员工在外访问公司内网
# 2. 站点互联: 连接不同地点的办公室
# 3. 翻墙: 访问受限内容
# 4. 隐私保护: 隐藏真实IP
```

## 1.2 VPN类型

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPN分类                                       │
└─────────────────────────────────────────────────────────────────┘

按协议层分类:
┌─────────────────────────────────────────────────────┐
│ 链路层VPN    │ PPTP, L2TP, L2TPv3                  │
│ 网络层VPN    │ IPSec, GRE, WireGuard                │
│ 应用层VPN    │ SSL VPN, OpenVPN                     │
└─────────────────────────────────────────────────────┘

按用途分类:
┌─────────────────────────────────────────────────────┐
│ 远程访问VPN  │ 个人连接公司网络 (SSL VPN, IPSec)    │
│ 站点到站点VPN│ 连接两个网络 (IPSec, GRE)          │
└─────────────────────────────────────────────────────┘

按拓扑分类:
┌─────────────────────────────────────────────────────┐
│ 端到端VPN   │ 主机到主机                            │
│ 端到网络VPN │ 主机到网络                            │
│ 网络到网络VPN│ 网络到网络                            │
└─────────────────────────────────────────────────────┘
```

---

# 2. IPSec

## 2.1 IPSec组件

```
┌─────────────────────────────────────────────────────────────────┐
│                    IPSec体系结构                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        IPSec                                     │
├──────────────────────────┬──────────────────────────────────────┤
│  安全协议                 │  密钥交换                            │
│  - AH (Authentication)   │  - IKEv1                           │
│  - ESP (Encapsulation)  │  - IKEv2                           │
│    Security Payload)    │                                     │
└──────────────────────────┴──────────────────────────────────────┘

# AH (Authentication Header):
# - 提供数据完整性验证
# - 不加密数据
# - 协议号: 51

# ESP (Encapsulating Security Payload):
# - 提供数据加密
# - 可选完整性验证
# - 协议号: 50

# IKE (Internet Key Exchange):
# - 密钥协商
# - 建立安全关联 (SA)
```

## 2.2 IPSec模式

```
┌─────────────────────────────────────────────────────────────────┐
│                    传输模式 vs 隧道模式                          │
└─────────────────────────────────────────────────────────────────┘

传输模式 (Transport Mode):
┌─────────────────────────────────────────────────────────────────┐
│  原IP头 │ IPSec头 │ TCP头 │ 数据                               │
└─────────────────────────────────────────────────────────────────┘
# 只加密数据部分, 保留原始IP头
# 用于主机到主机

隧道模式 (Tunnel Mode):
┌─────────────────────────────────────────────────────────────────┐
│ 新IP头 │ IPSec头 │ 原IP头 │ TCP头 │ 数据                       │
└─────────────────────────────────────────────────────────────────┘
# 整个数据包被封装
# 用于网络到网络, 或主机到网络
```

## 2.3 IPSec配置

```bash
# 使用strongSwan配置IPSec

# 1. 安装
apt install strongswan strongswan-pki

# 2. 配置 /etc/ipsec.conf
config setup
    charondebug="all"
    uniqueids=yes

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyexchange=ikev2
    authby=secret

conn myvpn
    left=203.0.113.1          # 本端公网IP
    leftsubnet=10.0.1.0/24    # 本端内网
    right=198.51.100.1        # 远端公网IP
    rightsubnet=10.0.2.0/24   # 远端内网
    auto=start
    type=tunnel

# 3. 配置 /etc/ipsec.secrets
: PSK "mypresharedkey"

# 4. 启动
systemctl start strongswan
systemctl enable strongswan

# 5. 查看状态
ipsec status
ipsec statusall
```

---

# 3. OpenVPN

## 3.1 OpenVPN原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    OpenVPN工作原理                               │
└─────────────────────────────────────────────────────────────────┘

# OpenVPN基于SSL/TLS
# 使用TUN/TAP设备创建虚拟网卡
# 工作在应用层

# TUN vs TAP:
# - TUN: 路由模式, 处理IP包 (点对点)
# - TAP: 网桥模式, 处理以太网帧 (可以广播)

# 通信流程:
[客户端] → TLS加密 → [OpenVPN服务器] → 解密 → [内网]
```

## 3.2 OpenVPN配置

```bash
# 1. 安装
apt install openvpn easy-rsa

# 2. 生成证书
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-server server
./easyrsa gen-client client
./easyrsa sign-server server server
./easyrsa sign-client client client

# 3. 服务器配置 /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3

# 4. 启动服务
systemctl start openvpn@server
systemctl enable openvpn@server

# 5. 客户端配置
client
dev tun
proto udp
remote your-server 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
cipher AES-256-CBC
verb 3
```

---

# 4. WireGuard

## 4.1 WireGuard特点

```
┌─────────────────────────────────────────────────────────────────┐
│                    WireGuard特点                                 │
└─────────────────────────────────────────────────────────────────┘

# WireGuard是新一代VPN协议
# 设计目标: 简单, 快速, 安全

# 优势:
# - 代码简洁: 约4000行 (OpenVPN约100,000行)
# - 性能高: 使用Linux内核原生API
# - 安全: 使用现代加密算法 (Curve25519, ChaCha20)
# - 配置简单: 类似SSH的密钥配置
# - 快速: 握手仅需几分钟

# 加密算法:
# - 密钥交换: Curve25519
# - 对称加密: ChaCha20
# - 哈希: Poly1305
# - 签名: Ed25519
```

## 4.2 WireGuard配置

```bash
# 1. 安装
apt install wireguard

# 2. 生成密钥
wg genkey > privatekey
wg pubkey < privatekey > publickey

# 3. 服务器配置 /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# 添加客户端
[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.0.0.2/32

# 4. 客户端配置
[Interface]
Address = 10.0.0.2/24
PrivateKey = <client-private-key>
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = your-server:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# 5. 启动
wg-quick up wg0
wg-quick down wg0
systemctl enable wg-quick@wg0

# 6. 查看状态
wg
wg show
```

---

# 5. 隧道技术

## 5.1 GRE隧道

```
┌─────────────────────────────────────────────────────────────────┐
│                    GRE (Generic Routing Encapsulation)             │
└─────────────────────────────────────────────────────────────────┘

# GRE是思科开发的隧道协议
# 用于封装多种协议
# 不加密

# GRE头格式:
┌─────────────────────────────────────────────────────────────────┐
│ 新IP头 │ GRE头 │ 负载协议头 │ 数据                             │
└─────────────────────────────────────────────────────────────────┘

# GRE特点:
# - 可以封装多种协议 (IP, IPX, AppleTalk等)
# - 不加密, 需要配合IPSec使用
# - 支持组播
```

## 5.2 GRE配置

```bash
# 1. 创建GRE隧道
ip tunnel add gre1 mode gre remote 198.51.100.1 local 203.0.113.1

# 2. 配置IP
ip addr add 10.0.0.1/30 dev gre1

# 3. 启用
ip link set gre1 up

# 4. 添加路由
ip route add 10.0.2.0/24 dev gre1

# 5. 查看
ip tunnel show
ip link show gre1

# 6. 删除
ip link set gre1 down
ip tunnel del gre1
```

## 5.3 IP-in-IP隧道

```bash
# IP-in-IP隧道 (简单封装)

# 创建
ip tunnel add ipip1 mode ipip remote 198.51.100.1 local 203.0.113.1

# 配置
ip addr add 10.0.0.1/30 dev ipip1
ip link set ipip1 up

# 路由
ip route add 10.0.2.0/24 dev ipip1
```

## 5.4 SIT隧道 (IPv6)

```bash
# SIT隧道 (IPv6 over IPv4)

# 创建
ip tunnel add sit1 mode sit remote 198.51.100.1 local 203.0.113.1

# 配置IPv6
ip -6 addr add 2001:db8::1/64 dev sit1
ip link set sit1 up

# 添加默认路由
ip -6 route add ::/0 dev sit1
```

---

## 本章小结

- **VPN**通过公网建立加密通道, 实现安全的远程访问
- **IPSec**是网络层VPN协议, 提供AH(认证)和ESP(加密)
- **OpenVPN**基于SSL/TLS, 使用TUN/TAP设备, 配置灵活
- **WireGuard**是新一代VPN, 简单快速安全, 使用现代加密算法
- **GRE隧道**可封装多种协议, 常配合IPSec使用
- **隧道模式**: 传输模式只加密数据, 隧道模式封装整个IP包

**关键命令回顾:**

```bash
# IPSec
ipsec status, strongswan配置

# OpenVPN
openvpn --config, easy-rsa

# WireGuard
wg genkey, wg-quick up, wg show

# 隧道
ip tunnel add, ip link set up, ip addr add
```