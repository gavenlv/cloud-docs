# SNAT (源地址转换) - 发出流量
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# DNAT (目标地址转换) - 流入流量
iptables -t nat -A PREROUTING -d 203.0.113.1 -p tcp --dport 80 \
         -j DNAT --to-destination 192.168.1.100:80

# 端口转发
iptables -t nat -A PREROUTING -p tcp --dport 8080 \
         -j REDIRECT --to-port 80

# 查看NAT表
iptables -t nat -L -n -v

# 查看NAT连接跟踪
conntrack -L