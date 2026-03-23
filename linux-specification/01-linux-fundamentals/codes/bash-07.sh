# 进程状态
ps aux | head -5
# STAT列显示进程状态：
# R - 运行中 (Running)
# S - 可中断睡眠 (Interruptible Sleep)
# D - 不可中断睡眠 (Uninterruptible Sleep)
# Z - 僵尸进程 (Zombie)
# T - 暂停/跟踪 (Stopped/Traced)
# I - 空闲 (Idle)

# 查看进程树
pstree
pstree -p | head -20

# 查看进程状态
cat /proc/PID/status | grep -E "^(Name|State|Pid)"