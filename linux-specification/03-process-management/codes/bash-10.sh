# 信号是软件中断,用于通知进程发生了某种事件

# 常用信号
kill -l
# 1) SIGHUP      2) SIGINT      3) SIGQUIT     4) SIGILL
# 5) SIGTRAP     6) SIGABRT     7) SIGBUS      8) SIGFPE
# 9) SIGKILL    10) SIGUSR1    11) SIGSEGV    12) SIGUSR2
# 13) SIGPIPE    14) SIGALRM    15) SIGTERM    17) SIGCHLD
# 18) SIGCONT    19) SIGSTOP    20) SIGTSTP

# 常用信号说明:
# SIGINT  (2)  - Ctrl+C 中断
# SIGTERM (15) - 优雅终止 (可捕获)
# SIGKILL (9)  - 强制终止 (不可捕获)
# SIGSTOP (19) - 暂停进程 (不可捕获)
# SIGCONT (18) - 继续运行
# SIGCHLD (17) - 子进程结束
# SIGUSR1/2    - 用户自定义