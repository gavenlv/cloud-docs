# 诊断
arp -a
ip neigh show

# 发现问题
# 查看是否有重复MAC
arp -a | awk '{print $4}' | sort | uniq -c

# 防御
# 静态ARP绑定
ip neigh add 192.168.1.1 lladdr AA:BB:CC:DD:EE:FF dev eth0
# 写入/etc/ethers
echo "192.168.1.1 AA:BB:CC:DD:EE:FF" >> /etc/ethers

# 启用ARP防护
echo 1 > /proc/sys/net/ipv4/conf/all/arp_filter