# 诊断步骤
# 1. 测试各段延迟
traceroute target_ip
mtr target_ip

# 2. 分析瓶颈
# 哪一跳延迟最高?

# 3. 检查网络负载
iftop -i eth0
nethogs

# 常见原因
# 1. 带宽不足
# 使用iperf3测试
iperf3 -c server_ip

# 2. 网络拥塞
# 限速或QoS
tc qdisc show

# 3. DNS慢
# 使用快速DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf