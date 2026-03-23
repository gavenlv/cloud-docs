# 路由追踪 (使用ICMP)
traceroute 8.8.8.8

# 路由追踪 (使用TCP, 穿透防火墙)
traceroute -T -p 80 8.8.8.8

#mtr - 实时路由追踪
mtr 8.8.8.8

# 查看DNS解析
dig example.com
nslookup example.com
host example.com

# 查看WHOIS信息
whois example.com