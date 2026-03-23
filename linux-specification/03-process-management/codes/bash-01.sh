# 进程状态说明
ps aux | head -5
# STAT列:
# R - Running/Runnable    # 运行中或就绪
# S - Interruptible Sleep # 可中断睡眠(等待事件)
# D - Uninterruptible Sleep # 不可中断睡眠(通常等待I/O)
# Z - Zombie              # 僵尸进程
# T - Stopped/Traced     # 暂停或被跟踪
# I - Idle               # 空闲线程(内核线程)

# 查看进程状态
cat /proc/PID/status | grep -E "^(State|Pid)"
# State:  S (sleeping)
# Pid:    1234