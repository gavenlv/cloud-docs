# 查看系统信息
uname -r                          # 内核版本
cat /proc/cmdline                 # 启动参数
dmesg | head                      # 内核日志

# 进程管理
ps -ef                            # 查看进程
top / htop                        # 监控进程
pstree                            # 进程树

# 内存管理
free -h                           # 内存使用
cat /proc/meminfo                 # 详细内存信息

# 模块管理
lsmod                             # 已加载模块
modprobe <module>                 # 加载模块
modinfo <module>                  # 模块信息

# systemd
systemctl status                  # 服务状态
systemctl list-units --all        # 所有units
systemd-analyze blame             # 启动耗时分析