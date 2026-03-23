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