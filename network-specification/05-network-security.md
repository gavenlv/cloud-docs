# 网络安全

## 本章导学

**学完本章后，你将能够：**

- 理解TLS/SSL的**加密原理和握手过程**
- 掌握常见网络攻击类型（DDoS、SYN Flood、ARP欺骗等）
- 理解防火墙的基本原理
- 掌握网络隔离和分段策略
- 理解VPN的加密机制

**学习方法：**

```
加密基础 → TLS/SSL → 常见攻击 → 防御策略 → 实战配置
```

---

# 1. 加密基础

## 1.1 对称加密 vs 非对称加密

```
┌─────────────────────────────────────────────────────────────────┐
│                    加密算法分类                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 对称加密 (Symmetric Encryption)                                  │
├─────────────────────────────────────────────────────────────────┤
│  加密: 明文 + 密钥 → 密文                                        │
│  解密: 密文 + 密钥 → 明文                                        │
│                                                                 │
│  特点:                                                          │
│  - 使用同一密钥加密和解密                                        │
│  - 速度快, 适合大量数据                                          │
│  - 密钥传输存在风险                                              │
│                                                                 │
│  算法: AES (128/192/256位), DES (56位), 3DES, ChaCha20          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 非对称加密 (Asymmetric Encryption)                               │
├─────────────────────────────────────────────────────────────────┤
│  加密: 明文 + 公钥 → 密文                                       │
│  解密: 密文 + 私钥 → 明文                                       │
│                                                                 │
│  特点:                                                          │
│  - 使用公钥加密, 私钥解密                                        │
│  - 速度慢, 适合少量数据                                          │
│  - 密钥对可公开分享                                              │
│                                                                 │
│  算法: RSA (2048/4096位), ECC, DH                                │
│  用途: 密钥交换, 数字签名                                        │
└─────────────────────────────────────────────────────────────────┘

# 混合加密 (TLS使用):
# 1. 用非对称加密交换密钥
# 2. 用对称加密加密数据
```

## 1.2 数字签名和证书

```
┌─────────────────────────────────────────────────────────────────┐
│                    数字签名原理                                   │
└─────────────────────────────────────────────────────────────────┘

发送方:
1. 计算消息哈希 (Hash)
2. 用私钥加密哈希 = 数字签名
3. 发送: 消息 + 数字签名

接收方:
1. 用公钥解密签名, 得到哈希1
2. 计算消息哈希, 得到哈希2
3. 比较: 哈希1 == 哈希2 → 验证成功

┌─────────────────────────────────────────────────────────────────┐
│                    数字证书 (Certificate)                        │
└─────────────────────────────────────────────────────────────────┘

# 证书内容:
# - 公钥
# - 持有者信息
# - 颁发者信息 (CA)
# - 有效期
# - 序列号
# - 签名 (CA用私钥签名)

# 证书链:
# 根CA (Root CA) → 中间CA (Intermediate CA) → 终端实体 (Server)
# 根CA证书内置于操作系统/浏览器
```

---

# 2. TLS/SSL协议

## 2.1 TLS握手过程

```
┌─────────────────────────────────────────────────────────────────┐
│                    TLS 1.2 握手过程                              │
└─────────────────────────────────────────────────────────────────┘

    客户端                              服务端
      │                                    │
      │  1. ClientHello                   │
      │     (TLS版本, 支持的加密套件,     │
      │      随机数, Session ID)          │
      │──────────────────────────────────►│
      │                                    │
      │  2. ServerHello                   │
      │     (选定TLS版本, 加密套件,       │
      │      随机数)                      │
      │◄──────────────────────────────────│
      │                                    │
      │  3. Certificate                   │
      │     (服务端证书链)                 │
      │◄──────────────────────────────────│
      │                                    │
      │  4. ServerHelloDone               │
      │◄──────────────────────────────────│
      │                                    │
      │  5. ClientKeyExchange             │
      │     (PreMasterSecret, 用公钥加密) │
      │──────────────────────────────────►│
      │                                    │
      │  双方计算 MasterSecret            │
      │                                    │
      │  6. ChangeCipherSpec              │
      │──────────────────────────────────►│
      │                                    │
      │  7. Finished (加密的握手消息)      │
      │──────────────────────────────────►│
      │                                    │
      │  8. ChangeCipherSpec              │
      │◄──────────────────────────────────│
      │                                    │
      │  9. Finished                      │
      │◄──────────────────────────────────│
      │                                    │
      │     加密通信开始                   │
      │◄────────────────────────────────►│

# TLS 1.3 简化握手 (1-RTT):
# - 客户端直接发送支持的加密套件和公钥
# - 服务端立即开始加密通信
```

## 2.2 TLS加密套件

```bash
# TLS 1.3 常用加密套件
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
TLS_AES_128_GCM_SHA256

# TLS 1.2 加密套件格式
TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
#    │      │      │       │
#    │      │      │       └─ 摘要算法 (SHA256)
#    │      │      └─ 加密算法 (AES-128-GCM)
#    │      └─ 密钥交换 (ECDHE)
#    └─ 认证算法 (RSA)

# 查看支持的加密套件
openssl ciphers -v 'ALL:!NULL:!EXPORT'

# 测试网站TLS配置
testssl.sh example.com
```

---

# 3. 常见网络攻击

## 3.1 DDoS攻击

```
┌─────────────────────────────────────────────────────────────────┐
│                    DDoS (Distributed Denial of Service)          │
└─────────────────────────────────────────────────────────────────┘

# 攻击类型:
# 1. 带宽消耗型
#    - UDP Flood: 发送大量UDP包
#    - ICMP Flood: 发送大量ICMP包
#    - DNS Amplification: 利用DNS放大攻击
#
# 2. 连接消耗型
#    - SYN Flood: 发送大量SYN包,不完成握手
#    - Connection Flood: 维持大量连接
#
# 3. 应用层攻击
#    - HTTP Flood: 大量HTTP请求
#    - Slowloris: 缓慢发送HTTP头
#    - CC攻击: 消耗服务器资源

# SYN Flood原理:
# 攻击者发送SYN, 服务器返回SYN+ACK
# 但攻击者不发送ACK, 服务器等待超时
# 半连接队列填满, 正常连接被拒绝
```

## 3.2 中间人攻击 (MITM)

```
┌─────────────────────────────────────────────────────────────────┐
│                    中间人攻击 (Man-in-the-Middle)                 │
└─────────────────────────────────────────────────────────────────┘

正常通信:
[Alice] ←──加密──→ [Bob]

中间人攻击:
[Alice] ←───加密──→ [Mallory] ←───加密──→ [Bob]
                   (窃听/篡改)

# 常见场景:
# 1. ARP欺骗: 伪造MAC地址
# 2. DNS劫持: 伪造DNS响应
# 3. SSLStrip: 降级HTTPS到HTTP
# 4. 伪造WiFi热点

# 防御:
# - 使用HTTPS (TLS)
# - 证书校验
# - HSTS (HTTP Strict Transport Security)
# - 证书固定 (Certificate Pinning)
```

## 3.3 ARP欺骗

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARP欺骗原理                                   │
└─────────────────────────────────────────────────────────────────┘

正常ARP:
[PC] 发送: "谁的IP是192.168.1.1?" (广播)
[网关] 回复: "192.168.1.1的MAC是AA:BB:CC:DD:EE:FF"

ARP缓存表:
192.168.1.1 → AA:BB:CC:DD:EE:FF (网关MAC)

ARP欺骗:
[攻击者] 发送: "192.168.1.1的MAC是11:22:33:44:55:66" (伪造)
[PC] 更新缓存: 192.168.1.1 → 11:22:33:44:55:66 (攻击者MAC)

# 结果:
# PC以为网关MAC是攻击者
# 所有流量经过攻击者
# 攻击者可以窃听/篡改
```

---

# 4. 常见防御策略

## 4.1 网络隔离

```bash
# VLAN隔离
# 将不同部门/用途的设备划分到不同VLAN
vlan 10 (研发)
vlan 20 (市场)
vlan 30 (服务器)

# 子网划分
# 10.0.1.0/24 (办公网络)
# 10.0.10.0/24 (服务器网络)
# 10.0.20.0/24 (数据库网络)

# 防火墙规则
# 办公网络 → 服务器网络: 允许 (80, 443)
# 办公网络 → 数据库网络: 拒绝
# 服务器网络 → 数据库网络: 仅允许3306 (MySQL)
```

## 4.2 访问控制

```bash
# iptables基本访问控制
# 允许已建立连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH (仅限特定IP)
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT

# 允许HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 拒绝其他所有入站
iptables -A INPUT -j DROP

# 限流防护
# 防止SYN Flood
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 防止ICMP Flood
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT
```

## 4.3 加密通信

```bash
# SSH密钥登录
ssh-keygen -t ed25519 -C "comment"
ssh-copy-id user@host

# SSH配置优化
cat ~/.ssh/config
Host *
    StrictHostKeyChecking no
    ServerAliveInterval 60
    ServerAliveCountMax 3

# HTTPS配置 (nginx)
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Security "max-age=31536000" always;
}
```

---

# 5. 网络安全实战

## 5.1 安全扫描

```bash
# nmap端口扫描
nmap -sS -sV -p- 192.168.1.1        # SYN扫描, 版本检测, 全端口
nmap -sV -sC -oA scan_result 10.0.0.1  # 脚本扫描, 输出所有格式

# 漏洞扫描
nikto -h https://example.com          # Web漏洞扫描
openvas-start                        # 启动OpenVAS

# 查看开放端口
ss -tuln
netstat -tuln
```

## 5.2 网络监控

```bash
# 实时监控网络连接
watch -n 1 'ss -tan | head -20'

# 监控可疑连接
ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# 查看ARP表 (检查ARP欺骗)
arp -a
ip neigh show

# 查看连接跟踪状态
conntrack -L | head
conntrack -L | grep ESTABLISHED | wc -l
```

---

## 本章小结

- **对称加密**速度快, 用于数据加密; **非对称加密**用于密钥交换和签名
- **TLS握手**通过非对称加密交换密钥, 然后用对称加密传输数据
- **DDoS攻击**通过大量请求耗尽资源, 可用限流、清洗等方式防御
- **中间人攻击**通过窃听/篡改通信, 用TLS和证书校验防御
- **ARP欺骗**通过伪造MAC地址, 用静态ARP和VLAN隔离防御
- **网络隔离**是基本安全策略, 通过VLAN和防火墙实现

**关键命令回顾:**

```bash
# 安全扫描
nmap -sS -sV -p- target

# 连接监控
ss -tan, netstat -tuln
conntrack -L

# 防火墙
iptables -L -n -v, iptables -A INPUT -j DROP

# 加密通信
ssh-keygen, openssl s_client -connect host:443
```