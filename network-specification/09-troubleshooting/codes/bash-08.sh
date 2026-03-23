# 诊断步骤
# 1. 检查TCP连接状态
ss -tan | awk '{print $1}' | sort | uniq -c

# 2. 检查TIME_WAIT
ss -tan state time-wait | wc -l

# 3. 检查错误
netstat -s | grep -i error
cat /proc/net/netstat

# 常见原因
# 1. NAT连接数满
# 查看NAT表大小
cat /proc/sys/net/netfilter/nf_conntrack_max
# 调整大小
echo 262144 > /proc/sys/net/netfilter/nf_conntrack_max

# 2. TCP参数优化
sysctl -w net.ipv4.tcp_fin_timeout=30