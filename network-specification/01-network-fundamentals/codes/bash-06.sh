# 查看配置
ip link show, ip addr show, ip route show, ss -s

# 抓包分析
tcpdump -i eth0, tcpdump -i eth0 host x.x.x.x, tcpdump -i eth0 port 80

# 路径分析
traceroute, mtr, dig, nslookup

# 查看ARP表
ip neigh show