# 1. 查看CPU使用
top
htop

# 找出CPU占用最高的进程
ps aux --sort=-%cpu | head -10

# 2. 查看进程详情
top -p PID
strace -p PID

# 3. 查看系统调用
strace -c -p PID