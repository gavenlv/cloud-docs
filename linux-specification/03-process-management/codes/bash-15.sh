# top - 实时进程监控

# 常用交互命令
# h      - 帮助
# q      - 退出
# 1      - 显示所有CPU核心
# M      - 按内存排序
# P      - 按CPU排序
# N      - 按PID排序
# T      - 按时间排序
# k      - 杀死进程
# r      - 重设优先级
# f      - 字段管理
# W      - 保存配置

# top选项
top -d 1              # 每秒刷新
top -p PID            # 监控特定进程
top -u username       # 只显示用户进程
top -b -n 5 > top.log # 批量模式输出

# htop - 更友好的进程监控 (需要安装)
htop
htop -u username
htop -p PID1,PID2