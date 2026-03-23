# 场景: 将外网访问80端口的请求转发到内网192.168.1.100:8080

# 1. 开启IP转发
echo 1 > /proc/sys/net/ipv4/ip_forward
# 永久生效
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# 2. 添加DNAT规则
iptables -t nat -A PREROUTING -p tcp -i eth0 -d 203.0.113.1 --dport 80 \
         -j DNAT --to-destination 192.168.1.100:8080

# 3. 添加SNAT规则 (让返回包能回来)
iptables -t nat -A POSTROUTING -p tcp -d 192.168.1.100 --dport 8080 \
         -j SNAT --to-source 192.168.1.1

# 4. 允许转发
iptables -A FORWARD -p tcp -d 192.168.1.100 --dport 8080 -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT