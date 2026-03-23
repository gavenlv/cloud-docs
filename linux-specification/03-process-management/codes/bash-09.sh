# 信号量 - 用于进程/线程同步

# 创建信号量
ipcmk -s
# or
# semget()

# 查看信号量
ipcs -s
# ------ Semaphore Arrays --------
# key        semid      owner      perms      nsems
# 0x00000000 0          root       600        1

# 信号量操作
cat > semaphore.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <unistd.h>

union semun {
    int val;
    struct semid_ds *buf;
    unsigned short *array;
};

int main() {
    key_t key = ftok("/tmp", 'S');
    int semid = semget(key, 1, IPC_CREAT | 0666);
    
    union semun arg;
    arg.val = 1;  // 初始值=1 (互斥锁)
    semctl(semid, 0, SETVAL, arg);
    
    pid_t pid = fork();
    if (pid == 0) {
        // 子进程
        struct sembuf p = {0, -1, 0};  // P操作 (wait)
        semop(semid, &p, 1);
        printf("Child in critical section\n");
        sleep(1);
        printf("Child leaving critical section\n");
        struct sembuf v = {0, 1, 0};   // V操作 (signal)
        semop(semid, &v, 1);
    } else {
        // 父进程
        struct sembuf p = {0, -1, 0};
        semop(semid, &p, 1);
        printf("Parent in critical section\n");
        sleep(1);
        printf("Parent leaving critical section\n");
        struct sembuf v = {0, 1, 0};
        semop(semid, &v, 1);
        
        wait(NULL);
        // 删除信号量
        semctl(semid, 0, IPC_RMID);
    }
    
    return 0;
}
EOF

gcc semaphore.c -o semaphore
./semaphore