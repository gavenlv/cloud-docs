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