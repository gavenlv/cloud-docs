# 查看连接状态
ss -tan state fin-wait-1
ss -tan state fin-wait-2
ss -tan state time-wait

# 查看TCP详细信息
cat /proc/net/tcp

# 查看各状态的连接数
ss -tan | awk '{print $1}' | sort | uniq -c

# 常见状态:
# ESTABISHED: 正常数据传输
# SYN_SENT: 正在建立连接
# SYN_RECV: 收到连接请求
# FIN_WAIT_1: 主动关闭
# FIN_WAIT_2: 等待对方关闭
# TIME_WAIT: 等待2MSL
# CLOSE_WAIT: 被动关闭等待
# LAST_ACK: 最后确认
# CLOSED: 已关闭