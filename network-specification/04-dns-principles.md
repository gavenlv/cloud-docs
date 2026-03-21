# DNS原理

## 本章导学

**学完本章后，你将能够：**

- 理解DNS的**层级结构和分布式数据库原理**
- 掌握DNS查询流程（递归查询、迭代查询）
- 理解DNS记录类型（A, AAAA, CNAME, MX, NS, TXT等）
- 理解DNS缓存和TTL机制
- 掌握DNS配置和排错

**学习方法：**

```
DNS层级 → 查询流程 → 记录类型 → 缓存机制 → 实战配置
```

---

# 1. DNS概述

## 1.1 DNS作用

```
┌─────────────────────────────────────────────────────────────────┐
│                    DNS (Domain Name System)                     │
└─────────────────────────────────────────────────────────────────┘

# DNS将域名转换为IP地址
# 例: www.example.com → 93.184.216.34

# 为什么需要DNS?
# - IP地址难记 (IPv4: 4组数字, IPv6: 6组字母数字)
# - IP地址会变化 (托管商更换, 负载均衡)
# - 域名可以代表品牌/服务

# DNS vs /etc/hosts
# - /etc/hosts: 手动映射, 单机有效
# - DNS: 自动解析, 全网生效
```

## 1.2 域名结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    域名层级结构                                  │
└─────────────────────────────────────────────────────────────────┘

# 完整域名: www.example.com.

# 层级 (从右到左):
# . (根域) - 全球13个根服务器
# com (顶级域/TLD) - gTLD(.com,.org,.net) 和 ccTLD(.cn,.jp,.uk)
# example (二级域) - 可注册域名
# www (子域/主机) - 主机名

# 根域 (.):
# - 全球13组根服务器 (a-m.root-servers.net)
# - 根服务器知道所有顶级域服务器

# 顶级域 (.com, .org, .cn 等):
# - gTLD: .com, .org, .net, .info, .biz
# - ccTLD: .cn, .jp, .uk, .de, .fr
# - 新顶级域: .app, .cloud, .io, .dev

# 二级域 (example.com):
# - 可向注册商申请注册
# - 例: google.com, baidu.com, github.com

# 主机名 (www, mail, api):
# - 属于二级域的子域
# - 例: www.baidu.com, mail.google.com
```

---

# 2. DNS查询流程

## 2.1 递归查询 vs 迭代查询

```
┌─────────────────────────────────────────────────────────────────┐
│                    DNS查询类型                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 递归查询 (Recursive Query)                                      │
│ 客户端 → DNS服务器 → DNS服务器完成全部工作,返回最终结果          │
└─────────────────────────────────────────────────────────────────┘

    客户端                              DNS服务器
      │                                    │
      │  查询 www.example.com             │
      │───────────────────────────────────►│
      │                                    │
      │         (DNS服务器代为查询)         │
      │                                    │
      │◄──────────────────────────────────│
      │  返回: 93.184.216.34              │

┌─────────────────────────────────────────────────────────────────┐
│ 迭代查询 (Iterative Query)                                      │
│ DNS服务器返回最佳答案,让客户端继续查询                            │
└─────────────────────────────────────────────────────────────────┘

    DNS服务器                         其他DNS服务器
      │                                    │
      │  查询 www.example.com              │
      │───────────────────────────────────►│ 返回: .com服务器列表
      │                                    │
      │  查询 www.example.com              │
      │───────────────────────────────────►│ 返回: example.com服务器
      │                                    │
      │  查询 www.example.com              │
      │───────────────────────────────────►│ 返回: 93.184.216.34
      │
```

## 2.2 完整查询流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    DNS完整解析流程                               │
└─────────────────────────────────────────────────────────────────┘

    客户端浏览器
         │
         │ 1. 检查浏览器缓存
         │ 2. 检查系统DNS缓存
         │ 3. 检查hosts文件
         │
         ▼
    本地DNS服务器 (通常由ISP提供)
         │
         │ 4. 检查DNS缓存
         │
         ▼
    ┌─────────────────────────────────────────────────┐
    │  根服务器 (.root)                               │
    │  全球13组, 知道所有顶级域服务器                   │
    └─────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────┐
    │  .com顶级域服务器                                │
    │  知道example.com的权威服务器                    │
    └─────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────┐
    │  example.com权威服务器 (NS记录指向)              │
    │  返回www.example.com的IP地址                    │
    └─────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────┐
    │  返回最终结果                                   │
    │  www.example.com = 93.184.216.34                │
    └─────────────────────────────────────────────────┘

# DNS缓存层级:
# 1. 浏览器缓存 (Chrome: 约1分钟)
# 2. 操作系统缓存 (Windows: 约1分钟)
# 3. 本地DNS服务器缓存 (可配置, 通常几小时)
# 4. 递归DNS服务器缓存
# 5. 权威DNS服务器 (权威答案)
```

---

# 3. DNS记录类型

## 3.1 常见记录类型

```bash
# A记录 (Address)
# 域名 → IPv4地址
www.example.com.    IN A     93.184.216.34

# AAAA记录 (IPv6 Address)
# 域名 → IPv6地址
www.example.com.    IN AAAA  2606:2800:220:1::

# CNAME记录 (Canonical Name)
# 域名别名 → 另一个域名
www.example.com.    IN CNAME example.com.
api.example.com.    IN CNAME api.aliyun.com.

# MX记录 (Mail Exchange)
# 邮件服务器地址 (优先级: 数字越小优先级越高)
example.com.        IN MX     10 mail1.example.com.
example.com.        IN MX     20 mail2.example.com.

# NS记录 (Name Server)
# 域名服务器
example.com.        IN NS     ns1.example.com.
example.com.        IN NS     ns2.example.com.

# TXT记录
# 文本记录 (常用于验证、SPF等)
example.com.        IN TXT    "v=spf1 include:_spf.example.com ~all"
_dmarc.example.com. IN TXT    "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# SOA记录 (Start of Authority)
# 权威记录 (DNS zone的起始信息)
example.com.        IN SOA    ns1.example.com. admin.example.com. (
                                2024010101 ; Serial
                                3600       ; Refresh (1小时)
                                1800       ; Retry (30分钟)
                                604800     ; Expire (7天)
                                86400 )    ; Minimum TTL (1天)
```

## 3.2 记录 TTL

```bash
# TTL (Time To Live)
# 缓存时间,单位秒

# 查看记录的TTL
dig www.example.com
# www.example.com.     300     IN      A       93.184.216.34
# 300秒=5分钟

# TTL设置建议:
# - 频繁变更: 300-3600秒 (5分钟-1小时)
# - 稳定记录: 86400秒 (1天)
# - 迁移时: 先调小TTL, 迁移完成后再调大

# DNS轮询 (Round Robin)
# 多个A记录, 每次返回不同顺序
www.example.com.    IN A     93.184.216.34
www.example.com.    IN A     93.184.216.35
www.example.com.    IN A     93.184.216.36
```

---

# 4. DNS服务器配置

## 4.1 DNS客户端配置

```bash
# /etc/resolv.conf (Linux DNS配置)
cat /etc/resolv.conf

# nameserver 8.8.8.8        # Google DNS
# nameserver 1.1.1.1        # Cloudflare DNS
# nameserver 114.114.114.114 # 腾讯DNS
# search localdomain         # 本地搜索域

# 查看DNS缓存
systemd-resolve --statistics
resolvectl statistics

# 清除DNS缓存
# systemd-resolved
systemd-resolve --flush-caches
resolvectl flush-caches

# Windows:
ipconfig /flushdns

# macOS:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## 4.2 常用DNS命令

```bash
# dig (详细DNS查询)
dig @8.8.8.8 www.example.com

# 查看完整解析过程
dig +trace www.example.com

# 指定记录类型
dig @8.8.8.8 example.com MX
dig @8.8.8.8 example.com NS
dig @8.8.8.8 example.com TXT

# 简短输出
dig +short www.example.com

# 查看SOA记录
dig +nssearch example.com

# 反向DNS查询
dig -x 93.184.216.34

# nslookup (简单查询)
nslookup www.example.com
nslookup -type=MX example.com

# host
host www.example.com
host -t MX example.com

# whois (查询域名注册信息)
whois example.com
```

---

# 5. DNS安全

## 5.1 DNSSEC

```
┌─────────────────────────────────────────────────────────────────┐
│                    DNSSEC (DNS Security Extensions)             │
└─────────────────────────────────────────────────────────────────┘

# 目的: 验证DNS响应没有被篡改

# 工作原理:
# 1. 权威服务器对DNS记录进行签名 (RRSIG)
# 2. 父域名对子域名的DS记录进行签名
# 3. 验证链从根域名开始

# 新增记录类型:
# RRSIG: DNS记录的签名
# DNSKEY: 公钥
# DS: Delegation Signer (父到子的信任链)
# CDNSKEY/CSK: -child

# 验证DNSSEC
dig +dnssec www.example.com
# 返回信息包含 RRSIG
```

## 5.2 DNS over HTTPS (DoH)

```bash
# 传统DNS: 明文, 可被监听和篡改
# DoH: DNS查询通过HTTPS加密传输

# 使用DoH (需要支持DoH的DNS客户端)
# Cloudflare: https://cloudflare-dns.com/dns-query
# Google: https://dns.google/dns-query

# curl测试DoH
curl -H 'accept: application/dns-json' \
     'https://cloudflare-dns.com/dns-query?name=www.example.com&type=A'

# Firefox启用DoH
# about:config → network.trr.mode = 2 (DoH启用)
```

---

## 本章小结

- **DNS**是分布式数据库,将域名解析为IP地址
- **域名层级**: 根域 → 顶级域(.com) → 二级域(example.com) → 子域(www)
- **递归查询**: DNS服务器完成全部查询
- **迭代查询**: 各DNS服务器返回下一步线索
- **记录类型**: A(IPv4), AAAA(IPv6), CNAME(别名), MX(邮件), NS(服务器)
- **TTL**: 缓存时间, 变更前应调小TTL
- **DNSSEC**: DNS安全扩展, 防止DNS欺骗

**关键命令回顾:**

```bash
dig @server domain type, dig +trace, dig +short
nslookup domain, host domain
/etc/resolv.conf, systemd-resolve --flush-caches
```