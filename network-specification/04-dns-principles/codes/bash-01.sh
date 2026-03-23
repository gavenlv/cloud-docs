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