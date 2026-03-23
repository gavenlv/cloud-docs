# 命名管道 - 可用于无亲缘关系的进程

# 创建FIFO
mkfifo /tmp/my_fifo

# 终端1 - 写入
echo "Hello FIFO" > /tmp/my_fifo

# 终端2 - 读取
cat /tmp/my_fifo

# C语言示例
cat > fifo_demo.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

int main() {
    const char *fifo_path = "/tmp/my_fifo";
    char buf[100];
    
    // 创建FIFO
    mkfifo(fifo_path, 0666);
    
    pid_t pid = fork();
    if (pid == 0) {
        // 子进程 - 写入
        int fd = open(fifo_path, O_WRONLY);
        write(fd, "Message via FIFO", 16);
        close(fd);
    } else {
        // 父进程 - 读取
        int fd = open(fifo_path, O_RDONLY);
        read(fd, buf, sizeof(buf));
        printf("Received: %s\n", buf);
        close(fd);
    }
    
    return 0;
}
EOF