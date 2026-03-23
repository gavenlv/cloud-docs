# 安全扫描
nmap -sS -sV -p- target

# 连接监控
ss -tan, netstat -tuln
conntrack -L

# 防火墙
iptables -L -n -v, iptables -A INPUT -j DROP

# 加密通信
ssh-keygen, openssl s_client -connect host:443