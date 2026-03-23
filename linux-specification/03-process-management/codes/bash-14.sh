# ps - 显示进程状态

# 常用选项组合
ps                     # BSD风格,显示当前终端进程
ps -e                  # 显示所有进程
ps -f                  # Full格式
ps -ef                 # 完整格式显示所有进程
ps -eLf                # 显示线程(LWP,nlwp)
ps aux                 # BSD风格,显示所有进程 (包含CPU/内存)

# 输出格式说明
ps -ef | head -3
# UID        PID  PPID  C STIME TTY          TIME CMD
# root         1     0  0 10:00 ?        00:00:02 /sbin/init

ps aux | head -3
# USER   PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
# root     1  0.0  0.1 168900  4560 ?        Ss   10:00   0:02 /sbin/init

# 字段说明:
# PID    - 进程ID
# PPID   - 父进程ID
# C      - CPU使用率
# STIME  - 启动时间
# TTY    - 关联终端
# TIME   - 累计CPU时间
# CMD    - 命令

# 按格式输出
ps -eo pid,ppid,cmd,%cpu,%mem,etime
ps -eo pid,stat,euid,egid,supgid,suppgsid
ps --format=pid,ppid,cmd

# 自定义列
ps -eo pid,ppid,cmd --forest      # 树形显示
ps -eo pid,ppid,cmd | grep nginx