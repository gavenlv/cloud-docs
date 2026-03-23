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