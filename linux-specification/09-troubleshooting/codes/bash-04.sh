# 1. 查看连接状态
ss -s
netstat -an | grep ESTABLISHED | wc -l

# 2. 查看网络错误
ip -s link show eth0
cat /proc/net/dev

# 3. 测试带宽
iperf3 -s &               # 服务器
iperf3 -c server_ip     # 客户端

# 4. 查看路由跳数
traceroute 8.8.8.8
mtr 8.8.8.8