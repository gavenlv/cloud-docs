# 发送信号
kill -SIGTERM PID
kill -15 PID
kill -SIGKILL PID
kill -9 PID

# 发送信号给进程组
kill -SIGTERM -PGID

# 键盘发送
Ctrl+C  -> SIGINT
Ctrl+Z  -> SIGTSTP
Ctrl+\  -> SIGQUIT

# 自定义信号处理
cat > signal_handler.c << 'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

volatile sig_atomic_t got_signal = 0;

void handler(int sig) {
    got_signal = 1;
}

int main() {
    struct sigaction sa;
    sa.sa_handler = handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    
    sigaction(SIGUSR1, &sa, NULL);
    
    printf("My PID: %d\n", getpid());
    printf("Send signal: kill -USR1 %d\n", getpid());
    
    while (!got_signal) {
        pause();  // 等待信号
    }
    
    printf("Received SIGUSR1!\n");
    
    return 0;
}
EOF

gcc signal_handler.c -o signal_handler
./signal_handler &
# 在另一个终端:
kill -USR1 PID