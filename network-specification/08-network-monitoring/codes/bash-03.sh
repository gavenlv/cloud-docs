# ss是netstat的现代替代品, 更快

# 基本用法
ss -tan                      # TCP所有连接
ss -tln                      # TCP监听端口
ss -uln                      # UDP监听端口
ss -s                        # 连接统计

# 过滤
ss -tan state established   # 已建立连接
ss -tan state time-wait     # TIME_WAIT状态
ss -tp                      # 显示进程信息
ss -tn sport = :80          # 源端口80

# 常用选项
# -n: 不解析域名
# -a: 所有连接
# -l: 监听端口
# -t: TCP
# -u: UDP
# -p: 显示进程
# -s: 统计
# -o: 显示定时器信息
# -e: 扩展信息
# -m: 内存信息

# 查看详细连接信息
ss -tano
# State      Recv-Q   Send-Q   Local Address:Port    Peer Address:Port
# ESTAB      0        0        192.168.1.100:22      192.168.1.50:54321
# users:(("sshd",pid=1234,fd=3))