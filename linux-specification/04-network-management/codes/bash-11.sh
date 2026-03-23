# conntrack - 连接跟踪

# 查看跟踪的连接
conntrack -L                         # 列出所有连接
conntrack -L -p tcp                   # 只看TCP
conntrack -L --state ESTABLISHED     # 已建立连接

# 示例输出:
# tcp      6 431999 ESTABLISHED src=192.168.1.100 dst=8.8.8.8 sport=54321 dport=443
# tcp      6 431999 ESTABLISHED src=8.8.8.8 dst=192.168.1.100 sport=443 dport=54321

# conntrack参数说明:
# -p: 协议
# --state: 连接状态 (ESTABLISHED, NEW, RELATED, INVALID)

# NAT相关
conntrack -L -n                      # 不解析IP

# conntrack-tools
# conntrackd - 连接跟踪守护进程 (用于高可用)