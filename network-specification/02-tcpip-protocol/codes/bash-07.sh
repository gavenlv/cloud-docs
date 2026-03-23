# 查看连接
ss -tan, ss -ti, ss -tm

# 查看状态
netstat -tan, netstat -s

# 抓包分析
tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-ack) != 0'

# TCP参数
sysctl -a | grep tcp
cat /proc/net/tcp