# SNAT (源地址转换) - POSTROUTING链
# 固定源IP
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 203.0.113.1

# MASQUERADE (自动获取出口IP)
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# DNAT (目标地址转换) - PREROUTING链
# 端口转发
iptables -t nat -A PREROUTING -p tcp -d 203.0.113.1 --dport 80 \
         -j DNAT --to-destination 192.168.1.100:80

# 转发到内部其他端口
iptables -t nat -A PREROUTING -p tcp -d 203.0.113.1 --dport 8080 \
         -j DNAT --to-destination 192.168.1.100:80

# 本机端口转发 - OUTPUT链
iptables -t nat -A OUTPUT -p tcp --dport 80 \
         -j REDIRECT --to-ports 8080