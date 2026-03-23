# 僵尸进程 (Zombie)
# 进程已结束,但父进程尚未调用wait()回收其退出状态
# 进程表项仍然存在,占用PID

# 创建僵尸进程示例
cat > zombie.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    pid_t pid = fork();
    
    if (pid == 0) {
        // 子进程立即退出,变成僵尸
        printf("Child (PID=%d) exiting...\n", getpid());
        _exit(0);
    }
    
    // 父进程不调用wait(),子进程变成僵尸
    printf("Parent (PID=%d), child=%d\n", getpid(), pid);
    sleep(60);  // 等待期间用ps查看僵尸
    
    wait(NULL); // 回收子进程
    return 0;
}
EOF

gcc zombie.c -o zombie
./zombie &
ps -ef | grep zombie | grep -v grep
# root  12345  12344  0 19:11 pts/0  00:00:00 ./zombie
# root  12346  12345  0 19:11 pts/0  00:00:00 [zombie] <defunct>

# 孤儿进程 (Orphan)
# 父进程已退出,子进程被init/systemd收养

# 创建孤儿进程示例
cat > orphan.c << 'EOF'
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main() {
    pid_t pid = fork();
    
    if (pid > 0) {
        // 父进程立即退出
        printf("Parent (PID=%d) exiting, child=%d\n", getpid(), pid);
        exit(0);
    }
    
    // 子进程继续运行,变成孤儿
    printf("Orphan (PID=%d, PPID=%d)\n", getpid(), getppid());
    sleep(5);
    printf("Orphan (PID=%d, new PPID=%d)\n", getpid(), getppid());
    
    return 0;
}
EOF

gcc orphan.c -o orphan
./orphan
# 观察PPID从12344变成1(init)