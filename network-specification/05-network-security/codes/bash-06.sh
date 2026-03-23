# 实时监控网络连接
watch -n 1 'ss -tan | head -20'

# 监控可疑连接
ss -tan | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head

# 查看ARP表 (检查ARP欺骗)
arp -a
ip neigh show

# 查看连接跟踪状态
conntrack -L | head
conntrack -L | grep ESTABLISHED | wc -l