# 验证内核版本
uname -a
# Linux localhost 5.4.0-generic #1 SMP ...

# 验证系统启动时间
uptime
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08

# 验证运行级别
who -r
# run-level 3  2026-03-21 19:11

# 验证systemd版本
systemctl --version
# systemd 245 (245.4-4ubuntu3)