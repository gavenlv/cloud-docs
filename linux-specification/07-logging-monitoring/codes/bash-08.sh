# uptime - 系统运行时间
uptime
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08

# w - 当前登录用户和负载
w
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08
# USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
# user     pts/0    192.168.1.100    19:11    0.00s  0.00s  0.00s w

# top - 实时监控
top
# 按M按内存排序,按P按CPU排序,按1显示所有核心

# vmstat - 虚拟内存统计
vmstat 1 5
vmstat -a                     # 活跃/非活跃内存
vmstat -s                     # 详细统计

# mpstat - 多处理器统计
mpstat -P ALL 1 5

# iostat - I/O统计
iostat -xz 1 5
iostat -d /dev/sda 1 3