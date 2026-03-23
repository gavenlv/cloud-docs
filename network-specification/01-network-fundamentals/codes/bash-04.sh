# 抓取所有包
sudo tcpdump -i eth0

# 抓取特定主机
sudo tcpdump -i eth0 host 8.8.8.8

# 抓取特定端口
sudo tcpdump -i eth0 port 80

# 抓取HTTP包
sudo tcpdump -i eth0 port 80 -A

# 抓取并保存到文件 (用于Wireshark分析)
sudo tcpdump -i eth0 -w capture.pcap

# 读取抓包文件
tcpdump -r capture.pcap

# 抓取特定协议的包
sudo tcpdump -i eth0 icmp
sudo tcpdump -i eth0 tcp
sudo tcpdump -i eth0 udp

# 抓取特定网段的包
sudo tcpdump -i eth0 net 192.168.1.0/24