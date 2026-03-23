# 抓取TCP三次握手
sudo tcpdump -i eth0 'tcp[tcpflags] == tcp-syn' -n

# 完整抓包分析
sudo tcpdump -i eth0 'tcp' -n -A

# 查看握手过程 (过滤SYN, SYN+ACK, ACK)
sudo tcpdump -i eth0 'tcp[tcpflags] & (tcp-syn|tcp-ack) != 0' -n

# telnet测试握手
telnet example.com 80
# 按Ctrl+]退出

# curl测试
curl -v http://example.com
# 可以看到 TCP connection established -> HTTP request/response