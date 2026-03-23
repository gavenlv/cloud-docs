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