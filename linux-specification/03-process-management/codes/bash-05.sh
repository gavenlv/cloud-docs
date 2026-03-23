# 匿名管道 - 只能用于有亲缘关系的进程

# 创建管道
pipefd=$(python3 -c "import os; r,w=os.pipe(); print(f'{r} {w}')")
read_fd=$(echo $pipefd | cut -d' ' -f1)
write_fd=$(echo $pipefd | cut -d' ' -f2)

# shell管道 (匿名管道示例)
cat /etc/passwd | grep root | head -3
# root:x:0:0:root:/root:/bin/bash

# 进程间管道通信
cat > pipe_demo.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <string.h>

int main() {
    int pipefd[2];
    pid_t pid;
    char buf[100];
    
    if (pipe(pipefd) == -1) {
        perror("pipe");
        return 1;
    }
    
    pid = fork();
    if (pid == -1) {
        perror("fork");
        return 1;
    }
    
    if (pid == 0) {
        // 子进程 - 写入
        close(pipefd[0]);
        write(pipefd[1], "Hello from child!", 16);
        close(pipefd[1]);
    } else {
        // 父进程 - 读取
        close(pipefd[1]);
        read(pipefd[0], buf, sizeof(buf));
        printf("Parent received: %s\n", buf);
        close(pipefd[0]);
    }
    
    return 0;
}
EOF

gcc pipe_demo.c -o pipe_demo
./pipe_demo