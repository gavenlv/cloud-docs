# Linux实时调度策略:
# - SCHED_FIFO: 先进先出,没有时间片
# - SCHED_RR: 轮转,相同优先级进程时间片轮转
# - SCHED_DEADLINE:  deadline调度,最迟优先

# 查看实时进程
ps -eo pid,rtprio,cmd | grep -v "  0 "
# PID RTPRIO CMD
# 1234  99    [kworker/0:1]   # 内核线程

# 设置实时调度
sudo chrt -f 50 command        # FIFO,优先级50
sudo chrt -r 50 command        # RR,优先级50
sudo chrt -d command           # DEADLINE

# 查看进程调度策略
chrt -p PID
# pid 1234's current scheduling policy: SCHED_OTHER
# pid 1234's current nice value: 0