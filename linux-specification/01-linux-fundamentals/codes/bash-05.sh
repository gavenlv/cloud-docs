# fork - 创建子进程
# 子进程获得父进程内存空间的副本

ps -ef | head -5
# UID        PID  PPID  C STIME TTY          TIME CMD
# root         1     0  0 10:00 ?        00:00:02 /sbin/init
# root       123   123  ...

# PID: 进程ID
# PPID: 父进程ID

# 创建进程示例
cat > fork_example.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    pid_t pid = fork();
    
    if (pid < 0) {
        perror("fork failed");
        return 1;
    } else if (pid == 0) {
        printf("子进程: PID=%d, PPID=%d\n", getpid(), getppid());
    } else {
        printf("父进程: PID=%d, 子进程PID=%d\n", getpid(), pid);
    }
    
    return 0;
}
EOF

gcc fork_example.c -o fork_example
./fork_example