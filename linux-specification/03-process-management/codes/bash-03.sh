# CFS (Completely Fair Scheduler) 设计目标:
# "公平"地分配CPU时间给每个进程

# 核心概念:
# - 虚拟运行时间 (vruntime): 进程运行的实际时间 * 权重因子
# - 权重由nice值决定 (-20到+19, 越低权重越高)
# - 调度器总是选择vruntime最小的进程运行

# 查看调度器信息
cat /sys/kernel/debug/sched/debug
cat /proc/sys/kernel/sched_min_granularity_ns  # 最小调度粒度
cat /proc/sys/kernel/sched_latency_ns          # 调度周期
cat /proc/sys/kernel/sched_nr_migrate           # 每次迁移的进程数