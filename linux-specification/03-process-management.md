# 进程和任务管理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux进程的**底层机制**（创建、调度、状态转换）
- 掌握进程间通信(IPC)的各种方式及其原理
- 熟练使用进程管理命令（ps、top、htop等）
- 理解信号机制和进程优先级
- 从**内核角度**理解多任务是如何实现的

**学习方法：**

```
进程原理 → 状态转换 → 进程通信 → 信号机制 → 资源限制 → 实战操作
```

---

# 1. 进程原理

## 1.1 进程的底层机制

```
┌─────────────────────────────────────────────────────────────────┐
│                    task_struct 结构                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ struct task_struct {                                            │
│     volatile long state;        // 进程状态                      │
│     pid_t pid;                  // 进程ID                        │
│     pid_t tgid;                 // 线程组ID                       │
│     pid_t ppid;                 // 父进程ID                       │
│     struct files_struct *files; // 文件描述符表                  │
│     struct mm_struct *mm;      // 内存描述符                     │
│     struct fs_struct *fs;       // 文件系统信息                   │
│     struct signal_struct *signal; // 信号处理                     │
│     // ... 还有很多其他字段                                       │
│ };                                                             │
└─────────────────────────────────────────────────────────────────┘

# 进程的创建过程:
# 1. 分配PID
# 2. 创建task_struct结构
# 3. 复制或共享父进程资源
# 4. 设置父子关系
# 5. 加入调度队列
```

## 1.2 进程与线程的区别

```
┌─────────────────────────────────────────────────────────────────┐
│                    进程 vs 线程                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┬─────────────────────────────────┐
│            进程                  │            线程                  │
├─────────────────────────────────┼─────────────────────────────────┤
│  独立的虚拟地址空间              │  共享进程的虚拟地址空间          │
│  独立的内核数据结构              │  共享task_struct大部分字段       │
│  通过IPC通信                    │  直接通过共享内存通信             │
│  创建/销毁开销大                 │  创建/销毁开销小                 │
│  进程间隔离                      │  线程间共享,需要同步              │
└─────────────────────────────────┴─────────────────────────────────┘

# Linux中的线程实现:
# - 线程是共享地址空间的进程
# - 通过CLONE_VM标志让多个"进程"共享同一内存空间
# - 通过CLONE_FS共享文件系统信息
# - 通过CLONE_FILES共享文件描述符表

# 线程创建示例 (pthread)
cat > thread_example.c << 'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

void* thread_func(void* arg) {
    printf("Thread %lu: PID=%d, PPID=%d\n",
           pthread_self(), getpid(), getppid());
    return NULL;
}

int main() {
    pthread_t tid1, tid2;
    
    pthread_create(&tid1, NULL, thread_func, NULL);
    pthread_create(&tid2, NULL, thread_func, NULL);
    
    printf("Main thread: PID=%d, TIDs=%lu,%lu\n",
           getpid(), tid1, tid2);
    
    pthread_join(tid1, NULL);
    pthread_join(tid2, NULL);
    
    return 0;
}
EOF

gcc thread_example.c -lpthread -o thread_example
./thread_example
```

---

# 2. 进程状态与转换

## 2.1 进程状态详解

```bash
# 进程状态说明
ps aux | head -5
# STAT列:
# R - Running/Runnable    # 运行中或就绪
# S - Interruptible Sleep # 可中断睡眠(等待事件)
# D - Uninterruptible Sleep # 不可中断睡眠(通常等待I/O)
# Z - Zombie              # 僵尸进程
# T - Stopped/Traced     # 暂停或被跟踪
# I - Idle               # 空闲线程(内核线程)

# 查看进程状态
cat /proc/PID/status | grep -E "^(State|Pid)"
# State:  S (sleeping)
# Pid:    1234
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    进程状态转换图                                 │
└─────────────────────────────────────────────────────────────────┘

                         ┌─────────────────┐
                    ┌───►│   R (运行/就绪)   │◄───────────────┐
                    │    └─────────────────┘                │
                    │                                         │
    时间片用完/        │                        被调度器选中运行
    更高优先级抢占      │                                         │
                    │    ┌─────────────────┐                │
                    └───│   S (可中断睡眠)   │                │
                         └────────┬─────────┘                │
                                  │                           │
            被信号唤醒/             │ 等待I/O                   │
            等待事件完成            │ 完成                       │
                                  ▼                           │
                         ┌─────────────────┐                │
                         │   D (不可中断睡眠)  │                │
                         └────────┬─────────┘                │
                                  │                           │
                              I/O完成                         │
                                  │                           │
                                  ▼                           │
                         ┌─────────────────┐                │
                         │   Z (僵尸进程)   │──────────────► [退出]
                         └─────────────────┘   父进程wait()  │
                                              │              │
                                              ▼              │
                    ┌─────────────────┐  ┌─────────────────┐  │
                    │  T (暂停/跟踪)   │─►│   I (空闲)      │  │
                    └─────────────────┘  └─────────────────┘  │
                         │                                  │
                    SIGCONT信号                            │
```

## 2.2 僵尸进程与孤儿进程

```bash
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
```

---

# 3. 进程调度

## 3.1 CFS调度器原理

```bash
# CFS (Completely Fair Scheduler) 设计目标:
# "公平"地分配CPU时间给每个进程

# 核心概念:
# - 虚拟运行时间 (vruntime): 进程运行的实际时间 * 权重因子
# - 权重由nice值决定 (-20到+19, 越低权重越高)
# - 调度器总是选择vruntime最小的进程运行

# 查看调度器信息
cat /sys/kernel/debug/sched/debug
cat /proc/sys/kernel/sched_min_granularity_ns  # 最小调度粒度
cat /proc/sys/kernel/sched_latency_ns          # 调度周期
cat /proc/sys/kernel/sched_nr_migrate           # 每次迁移的进程数
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    CFS 红黑树                                    │
└─────────────────────────────────────────────────────────────────┘

# CFS使用红黑树(自平衡二叉搜索树)管理就绪进程
# 键值是vruntime

# 树结构:
#                         ┌───────┐
#                      ┌─►│ vruntime=50  │
#                      │  └───────┘
# ┌───────┐         ┌───────┐         ┌───────┐
# │ vruntime=20 │◄──┘       └──►│ vruntime=80 │
# └───────┘                    └───────┘
#      ▲                             ▲
#      │                             │
#      └─────────────┬───────────────┘
#                    │
#              最左节点被调度
#              (最小vruntime)

# nice值对权重的影响:
# nice=-20 → weight=1024*25 ≈ 62786  (最高优先级)
# nice=0   → weight=1024*1  ≈ 1024   (默认)
# nice=+19 → weight=1024*1/887 ≈ 1   (最低优先级)
```

## 3.2 实时调度

```bash
# Linux实时调度策略:
# - SCHED_FIFO: 先进先出,没有时间片
# - SCHED_RR: 轮转,相同优先级进程时间片轮转
# - SCHED_DEADLINE:  deadline调度,最迟优先

# 查看实时进程
ps -eo pid,rtprio,cmd | grep -v "  0 "
# PID RTPRIO CMD
# 1234  99    [kworker/0:1]   # 内核线程

# 设置实时调度
sudo chrt -f 50 command        # FIFO,优先级50
sudo chrt -r 50 command        # RR,优先级50
sudo chrt -d command           # DEADLINE

# 查看进程调度策略
chrt -p PID
# pid 1234's current scheduling policy: SCHED_OTHER
# pid 1234's current nice value: 0
```

---

# 4. 进程间通信 (IPC)

## 4.1 IPC机制总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux IPC 机制                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      用户空间                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │   Pipe   │  │   FIFO   │  │  Socket  │  │   Msg    │        │
│  │  管道    │  │  命名管道 │  │  套接字   │  │   消息   │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│       │              │              │              │              │
└───────┼──────────────┼──────────────┼──────────────┼──────────────┘
        │              │              │              │
        └──────────────┴──────────────┼──────────────┘
                                       │
                              ┌────────┴────────┐
                              │   内核空间       │
                              │                 │
                    ┌─────────┴────────┐  ┌─────┴──────┐
                    │   共享内存        │  │   信号量   │
                    │   (Shared Memory) │  │  (Semaphore)│
                    └─────────────────┘  └────────────┘
```

## 4.2 管道 (Pipe)

```bash
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
```

## 4.3 命名管道 (FIFO)

```bash
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
```

## 4.4 共享内存

```bash
# 共享内存 - 最高效的IPC方式,直接共享内存地址

# System V 共享内存

# 创建共享内存
ipcmk -M 1024
# or
# ipcs -m | grep shm

# 查看共享内存
ipcs -m
# ------ Shared Memory Segments --------
# key        shmid      owner      perms      bytes      nattch     status
# 0x00000000 0          root       600        1024       0

# 附加共享内存
shmid=$(ipcs -m | awk '/my_seg/ {print $2}')
shmat $shmid, NULL, 0

# 分离共享内存
shmdt $shmid

# 删除共享内存
ipcrm -m $shmid

# POSIX共享内存 (更现代的方式)
cat > shm_posix.c << 'EOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    const char *shm_name = "/my_shm";
    int shm_fd;
    void *ptr;
    
    // 创建共享内存对象
    shm_fd = shm_open(shm_name, O_CREAT | O_RDWR, 0666);
    ftruncate(shm_fd, 1024);
    
    // 映射到进程地址空间
    ptr = mmap(NULL, 1024, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    
    // 写入数据
    sprintf(ptr, "Hello from shared memory!");
    
    // 读取数据
    printf("Read from shared memory: %s\n", (char*)ptr);
    
    // 清理
    munmap(ptr, 1024);
    shm_unlink(shm_name);
    
    return 0;
}
EOF

gcc shm_posix.c -lrt -o shm_posix
./shm_posix
```

## 4.5 消息队列

```bash
# 消息队列 - 发送包含类型的数据块

# 创建消息队列
ipcmk -q
# or
# msgget()

# 查看消息队列
ipcs -q
# ------ Message Queues --------
# key        msqid      owner      perms      used-bytes   messages
# 0x00000000 0          root       644        0            0

# 发送消息
cat > msg_send.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/msg.h>

struct msgbuf {
    long mtype;
    char mtext[100];
};

int main() {
    key_t key = ftok("/tmp", 'M');
    int msgid = msgget(key, IPC_CREAT | 0666);
    
    struct msgbuf msg;
    msg.mtype = 1;
    sprintf(msg.mtext, "Hello message queue!");
    
    msgsnd(msgid, &msg, sizeof(msg.mtext), 0);
    
    return 0;
}
EOF

cat > msg_recv.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/msg.h>

struct msgbuf {
    long mtype;
    char mtext[100];
};

int main() {
    key_t key = ftok("/tmp", 'M');
    int msgid = msgget(key, IPC_CREAT | 0666);
    
    struct msgbuf msg;
    msgrcv(msgid, &msg, sizeof(msg.mtext), 1, 0);
    
    printf("Received: %s\n", msg.mtext);
    
    // 删除消息队列
    msgctl(msgid, IPC_RMID, NULL);
    
    return 0;
}
EOF

gcc msg_send.c -o msg_send
gcc msg_recv.c -o msg_recv
./msg_send &
./msg_recv
```

## 4.6 信号量

```bash
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
```

---

# 5. 信号机制

## 5.1 信号详解

```bash
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
```

## 5.2 信号处理

```bash
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
```

---

# 6. 进程资源限制

## 6.1 ulimit与resource

```bash
# ulimit - shell级别的资源限制

# 查看当前限制
ulimit -a
# core file size          (blocks, -c)  0
# data seg size           (kbytes, -d)  unlimited
# file size               (blocks, -f)  unlimited
# pending signals                  (-i)  7424
# max locked memory       (kbytes, -l)  65536
# max memory size         (kbytes, -m)  unlimited
# open files                      (-n)  1024
# pipe size            (512 bytes, -p)  8
# POSIX message queues     (bytes, -q)  819200
# stack size              (kbytes, -s)  8192
# cpu time               (seconds, -t)  unlimited
# max user processes              (-u)  7424
# virtual memory          (kbytes, -v)  unlimited
# file locks                      (-x)  unlimited

# 设置限制
ulimit -n 2048         # 修改最大文件描述符
ulimit -u 100          # 修改最大用户进程数
ulimit -s 16384        # 修改栈大小

# 永久设置 (在/etc/security/limits.conf)
# username  soft   nofile  2048
# username  hard   nofile  4096
```

## 6.2 prlimit - 进程资源限制

```bash
# prlimit - 查看/设置特定进程的资源限制

# 查看进程限制
prlimit --pid PID

# 示例
prlimit --pid $$   # 当前shell
# RESOURCE DESCRIPTION              SOFT              HARD
# CPU        unlimited              unlimited         []
# FSIZE      unlimited              unlimited         []
# DATA       unlimited              unlimited         []
# STACK      8388608                unlimited         []
# CORE       0                      unlimited         []
# NPROC      7424                   unlimited         []
# NOFILE     1024                   1048576           []
# MEMLOCK    65536                  65536             []
# ...

# 修改进程限制
prlimit --pid PID --nproc 100:200
prlimit --pid PID --nofile 2048:4096

# 在进程启动时设置限制
cat > limit_demo.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>

int main() {
    struct rlimit lim;
    
    // 获取当前限制
    getrlimit(RLIMIT_NOFILE, &lim);
    printf("NOFILE soft=%ld hard=%ld\n", lim.rlim_cur, lim.rlim_max);
    
    // 设置新限制
    lim.rlim_cur = 2048;
    lim.rlim_max = 4096;
    setrlimit(RLIMIT_NOFILE, &lim);
    
    return 0;
}
EOF

gcc limit_demo.c -o limit_demo
./limit_demo
```

---

# 7. 进程管理命令

## 7.1 ps命令详解

```bash
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
```

## 7.2 top/htop命令

```bash
# top - 实时进程监控

# 常用交互命令
# h      - 帮助
# q      - 退出
# 1      - 显示所有CPU核心
# M      - 按内存排序
# P      - 按CPU排序
# N      - 按PID排序
# T      - 按时间排序
# k      - 杀死进程
# r      - 重设优先级
# f      - 字段管理
# W      - 保存配置

# top选项
top -d 1              # 每秒刷新
top -p PID            # 监控特定进程
top -u username       # 只显示用户进程
top -b -n 5 > top.log # 批量模式输出

# htop - 更友好的进程监控 (需要安装)
htop
htop -u username
htop -p PID1,PID2
```

## 7.3 其他进程管理命令

```bash
# pgrep - 搜索进程
pgrep nginx
pgrep -u root sshd

# pkill - 按名称杀进程
pkill nginx
pkill -9 -u username

# pidof - 获取进程PID
pidof nginx
pidof -s nginx  # 只返回一个PID

# pstree - 进程树
pstree
pstree -p
pstree -p 1     # 查看PID 1的进程树

# watch - 定期执行命令
watch -n 1 'ps -eo pid,stat,cmd --sort=-%cpu | head -10'

# lsof - 查看进程打开的文件
lsof -p PID
lsof /dev/null
lsof -i :8080

# fuser - 查找使用文件的进程
fuser /var/log/syslog
fuser -v 8080/tcp
```

---

# 8. 任务管理

## 8.1 作业控制

```bash
# jobs - 查看后台作业
jobs

# Ctrl+Z - 暂停当前作业
# bg - 后台继续运行
# fg - 前台继续运行

# 示例
sleep 100 &
# [1] 12345
jobs
# [1]+  Running                 sleep 100 &

# 把作业切到后台
bg %1

# 把作业切到前台
fg %1

# 杀死作业
kill %1

# nohup - 忽略挂断信号
nohup ./long_running_script.sh &
```

## 8.2 crontab定时任务

```bash
# crontab - 定时任务

# 格式: 分 时 日 月 周 命令
# * * * * * command
# │ │ │ │ │
# │ │ │ │ └─── 星期 (0-7, 0和7是周日)
# │ │ │ └───── 月份 (1-12)
# │ │ └─────── 日期 (1-31)
# │ └───────── 小时 (0-23)
# └─────────── 分钟 (0-59)

# 示例
# 每分钟执行
* * * * * /path/to/command

# 每小时执行
0 * * * * /path/to/command

# 每天凌晨3点执行
0 3 * * * /path/to/command

# 每周一执行
0 0 * * 1 /path/to/command

# 每月1号执行
0 0 1 * * /path/to/command

# 每5分钟执行
*/5 * * * * /path/to/command

# 上午9点到下午5点每30分钟执行
*/30 9-17 * * * /path/to/command

# crontab命令
crontab -l              # 列出当前crontab
crontab -e              # 编辑crontab
crontab -r              # 删除crontab
crontab -i              # 删除前确认

# 系统级crontab
# /etc/crontab
# /etc/cron.d/
# /etc/cron.daily/
# /etc/cron.hourly/
# /etc/cron.monthly/
# /etc/cron.weekly/
```

## 8.3 systemd timer

```bash
# systemd timer - 现代化定时任务

# 创建timer单元
cat > /etc/systemd/system/mytask.timer << 'EOF'
[Unit]
Description=My Task Timer

[Timer]
OnCalendar=*:0/5          # 每5分钟
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 创建service单元
cat > /etc/systemd/system/mytask.service << 'EOF'
[Unit]
Description=My Task Service

[Service]
Type=oneshot
ExecStart=/path/to/command

[Install]
WantedBy=multi-user.target
EOF

# 管理timer
sudo systemctl daemon-reload
sudo systemctl enable --now mytask.timer
sudo systemctl list-timers
```

---

## 本章小结

- **进程**是Linux资源分配的基本单位,**线程**是CPU调度的基本单位
- **进程状态**包括运行、睡眠、僵尸、暂停等,状态转换由内核调度器控制
- **CFS调度器**通过vruntime实现公平调度
- **IPC机制**包括管道、FIFO、共享内存、消息队列、信号量、套接字
- **信号**是软件中断,用于通知进程异步事件
- **资源限制**通过ulimit和prlimit管理
- **作业控制**允许进程在前后后台切换
- **定时任务**可通过crontab和systemd timer管理

**关键命令回顾:**

```bash
# 进程查看
ps -ef, ps aux, top, htop, pstree, pgrep

# 进程控制
kill, pkill, killall, nice, renice

# 作业控制
jobs, bg, fg, nohup, Ctrl+Z

# IPC
ipcs, ipcmk, ipcrm

# 定时任务
crontab -e, systemctl list-timers
```