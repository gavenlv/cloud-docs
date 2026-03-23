# 查看进程内存映射
cat /proc/self/maps

# 查看内存使用
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           15Gi       2.1Gi       11Gi       150Mi       1.8Gi        12Gi
# Swap:         2.0Gi          0B       2.0Gi

# 查看详细内存信息
cat /proc/meminfo

# 查看进程的内存使用
pmap -x PID