# 诊断
# 查看连接数异常
ss -s

# 查看TOP IP
ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# 查看流量异常
iftop -i eth0

# 防御
# 限流
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# 封禁IP
iptables -A INPUT -s 1.2.3.4 -j DROP