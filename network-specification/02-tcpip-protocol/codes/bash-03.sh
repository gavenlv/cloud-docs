# 查看连接序列号信息
ss -i

# TCP序列号计算
# 初始序列号 (ISN): 每次连接时随机生成
# 当前序列号 = ISN + 已发送字节数

# 序列号回绕处理
# TCP使用相对序列号, 便于分析
tcpdump -N 'tcp' -v

# 查看TCP重传统计
netstat -s | grep -i retransmit
cat /proc/net/netstat | grep -i retransmit