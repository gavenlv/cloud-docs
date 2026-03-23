# netstat - 网络统计 (已过时,推荐使用ss)
netstat -tuln                  # TCP/UDP监听端口
netstat -an                    # 所有连接
netstat -r                     # 路由表
netstat -i                      # 接口统计
netstat -s                      # 协议统计

# ss - 现代socket统计 (替代netstat)
ss -tuln                       # TCP/UDP监听端口
ss -tan                        # 所有TCP连接
ss -ua                         # 所有UDP连接
ss -s                          # 统计汇总
ss -p                          # 显示进程
ss -o state established '(dport = :80 or sport = :80)'  # 过滤

# 输出字段说明:
# State:  TCP状态 (ESTABLISHED, LISTEN, TIME_WAIT, etc)
# Recv-Q: 接收队列 (字节)
# Send-Q: 发送队列 (字节)
# Local Address: 本地地址
# Peer Address: 远端地址

# 示例:
ss -tuln
# Netid  State   Recv-Q   Send-Q     Local Address:Port     Peer Address:Port
# tcp    LISTEN  0        128              0.0.0.0:22          0.0.0.0:*
# tcp    LISTEN  0        128                    *:80                *:*