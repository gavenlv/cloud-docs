# Linux基础和核心原理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux内核的核心架构和设计理念
- 掌握Linux系统启动流程的底层原理
- 理解进程调度和内存管理的机制
- 掌握Linux内核模块的管理方法
- 从**底层原理**理解Linux如何管理工作负载

**学习方法：**

```
内核架构 → 启动流程 → 进程调度 → 内存管理 → I/O系统 → 实战验证
```

---

# 1. Linux内核架构

## 1.1 内核空间与用户空间

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux系统架构                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      用户空间 (User Space)                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
│  │   Shell │  │   应用程序  │  │   库   │  │   容器   │          │
│  │ (bash)  │  │ (nginx) │  │ (glibc) │  │(docker) │          │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘          │
└───────┼─────────────┼─────────────┼─────────────┼───────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      系统调用接口 (System Call Interface)         │
│                    (write, read, open, fork, exec, etc.)        │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                      内核空间 (Kernel Space)                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  进程调度   │  │   内存管理   │  │   文件系统   │            │
│  │ (Scheduler) │  │   (VM)     │  │   (VFS)    │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   设备驱动   │  │   网络协议栈  │  │   安全模块   │            │
│  │   (Driver)  │  │   (Net)    │  │   (SELinux) │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                      硬件 (Hardware)                             │
│              CPU, Memory, Disk, Network Card                     │
└─────────────────────────────────────────────────────────────────┘
```

**核心概念：**

- **内核空间**：拥有最高权限，可以直接访问硬件，运行关键系统服务
- **用户空间**：应用程序运行的空间，不能直接访问硬件，通过系统调用与内核交互
- **系统调用**：用户空间与内核空间交互的接口（write, read, open, fork, exec等）

### 1.1.1 为什么需要内核空间与用户空间分离？

```c
// 用户空间代码示例 - 不能直接访问硬件
#include <stdio.h>
#include <unistd.h>

int main() {
    // write是系统调用，通过内核完成
    write(STDOUT_FILENO, "Hello from user space!\n", 22);
    
    // 如果直接写内存或访问硬件（如写入磁盘寄存器）会导致段错误
    // *0x12345678 = 1;  // 这会导致Segmentation Fault!
    
    return 0;
}
```

**隔离的好处：**

1. **安全性**：应用程序不能直接破坏硬件或其他程序
2. **稳定性**：单个应用程序崩溃不会导致系统崩溃
3. **可移植性**：应用程序通过标准接口与硬件交互，不依赖具体硬件

### 1.1.2 特权级别

```
┌─────────────────────────────────────────────────────────────────┐
│                    CPU特权级别 (Ring)                             │
└─────────────────────────────────────────────────────────────────┘

        Ring 0 (最高特权)  ──► 内核空间
        Ring 1
        Ring 2
        Ring 3 (最低特权)  ──► 用户空间

x86架构有4个特权级别，但Linux只使用两个：
- Ring 0: 内核态（可以访问所有硬件）
- Ring 3: 用户态（受限访问）
```

---

## 1.2 内核主要子系统

### 1.2.1 进程调度器 (Process Scheduler)

```c
// 进程调度器负责决定哪个进程获得CPU时间
// CFS (Completely Fair Scheduler) 是Linux默认调度器

/*
 * 调度器设计原理：
 * - 每个进程有虚拟运行时间 (vruntime)
 * - 调度器选择vruntime最小的进程运行
 * - 保证每个进程获得公平的CPU时间
 */

struct task_struct {
    volatile long state;          // 进程状态
    void *stack;                  // 栈指针
    unsigned int flags;           // 进程标志
    int prio;                     // 优先级
    int static_prio;              // 静态优先级
    int normal_prio;              // 动态优先级
    unsigned long vruntime;       // 虚拟运行时间 (CFS使用)
    struct sched_entity se;       // 调度实体
    // ... 其他字段
};
```

### 1.2.2 内存管理 (Memory Management)

```c
// 虚拟内存管理允许每个进程有独立的地址空间

/*
 * 虚拟地址空间布局 (32位):
 *
 * 0xFFFFFFFF ──────────────────┐ 高地址
 *         │   内核空间 (1GB)    │
 * 0xC0000000 ├─────────────────┤
 *         │   栈 (向下增长)      │
 *         │        ↓            │
 *         │                   │
 *         │        ↑            │
 *         │   堆 (向上增长)     │
 * 0x08048000 ├─────────────────┤
 *         │   BSS (未初始化数据) │
 *         │   Data (已初始化数据)│
 *         │   Text (代码段)     │
 * 0x00000000 └─────────────────┘ 低地址
 */
```

### 1.2.3 虚拟文件系统 (VFS)

```
┌─────────────────────────────────────────────────────────────────┐
│                    虚拟文件系统 (VFS)                              │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │      VFS        │
                    │   (统一接口)    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │            │            │            │
        ▼            ▼            ▼            ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
   │  ext4   │ │   XFS   │ │  Btrfs  │ │  tmpfs  │
   │ (磁盘)  │ │ (磁盘)  │ │ (磁盘)  │ │ (内存)  │
   └─────────┘ └─────────┘ └─────────┘ └─────────┘

VFS提供统一的API，让应用程序无需关心底层文件系统差异
```

---

# 2. Linux系统启动流程

## 2.1 启动流程总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux系统启动流程                              │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   按下电源按钮    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   BIOS/UEFI      │  ──► 硬件自检 (POST)
│   (固件)         │  ──► 读取启动设备顺序
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│      GRUB2       │  ──► 显示启动菜单
│   (引导加载器)    │  ──► 加载内核镜像和initrd
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│     Kernel       │  ──► 解压内核
│   (Linux内核)    │  ──► 初始化内核子系统
└────────┬─────────┘  ──► 挂载根文件系统
         │
         ▼
┌──────────────────┐
│    systemd       │  ──► 读取默认target
│  (初始化系统)     │  ──► 启动系统服务
└────────┬─────────┘  ──► 显示登录界面
         │
         ▼
┌──────────────────┐
│    Login         │
│   (登录界面)      │
└──────────────────┘
```

## 2.2 BIOS/UEFI阶段

```bash
# BIOS (Basic Input/Output System)
# - 存储在主板ROM芯片中
# - legacy启动模式
# - MBR分区表 (512字节)

# UEFI (Unified Extensible Firmware Interface)
# - 现代化固件接口
# - GPT分区表 (支持 >2TB磁盘)
# - 支持安全启动 (Secure Boot)

# 查看固件类型 (Linux)
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"
```

## 2.3 GRUB2引导加载器

```
┌─────────────────────────────────────────────────────────────────┐
│                    GRUB2配置文件结构                              │
└─────────────────────────────────────────────────────────────────┘

/etc/default/grub          # GRUB默认配置
/boot/grub2/grub.cfg       # GRUB主配置文件 (CentOS/RHEL)
/boot/grub/grub.cfg        # GRUB主配置文件 (Debian/Ubuntu)

# grub.cfg 示例结构：
menuentry 'CentOS Linux' {
    load_video
    set gfxpayload=keep
    insmod gzio
    insmod part_msdos
    insmod ext2
    linux   /boot/vmlinuz-5.4.x root=/dev/sda1 ro quiet
    initrd  /boot/initramfs-5.4.x.img
}
```

```bash
# 常用GRUB命令
grub2-mkconfig -o /boot/grub2/grub.cfg   # 生成配置文件
grub2-install /dev/sda                    # 安装GRUB

# 进入GRUB命令行
# 按 'c' 键在启动时进入命令行模式

# 常用GRUB命令
ls                              # 列出设备
ls (hd0,msdos1)/               # 查看分区内容
set root=(hd0,msdos1)
linux /boot/vmlinuz root=/dev/sda1
initrd /boot/initramfs.img
boot
```

## 2.4 内核初始化

```
┌─────────────────────────────────────────────────────────────────┐
│                    内核启动过程                                   │
└─────────────────────────────────────────────────────────────────┘

1. 内核解压
   - 内核镜像通常压缩存储 (vmlinuz)
   - 解压到内存高端地址

2. 内核初始化
   - CPU初始化
   - 内存管理初始化
   - 初始化内核数据结构 (task_struct, mm_struct)

3. 挂载根文件系统
   - 尝试挂载只读方式
   - 运行init (PID 1)

4. 启动用户空间
   - 切换到用户空间
   - 启动systemd或其他init系统
```

```bash
# 查看内核版本
uname -r
# 5.4. x-generic

# 查看内核启动参数
cat /proc/cmdline
# BOOT_IMAGE=/boot/vmlinuz-5.4.0 root=UUID=xxx ro quiet splash

# 查看内核日志 (dmesg)
dmesg | head -50
dmesg | grep -i error
```

## 2.5 systemd初始化系统

```
┌─────────────────────────────────────────────────────────────────┐
│                    systemd启动流程                                │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │   systemd (PID 1) │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  default.target  │
                    │   (默认启动级别)  │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  graphical.target │ │ multi-user.target │ │  rescue.target  │
│   (图形界面)     │ │   (多用户)       │ │   (救援模式)    │
└─────────────────┘ └─────────────────┘ └─────────────────┘

# Target 依赖关系
graphical.target依赖multi-user.target
multi-user.target依赖basic.target
basic.target依赖sysinit.target
```

```bash
# systemd基础命令

# 查看当前默认target
systemctl get-default

# 设置默认target
sudo systemctl set-default multi-user.target
sudo systemctl set-default graphical.target

# 切换到指定target (不改变默认设置)
sudo systemctl isolate multi-user.target

# 查看所有units
systemctl list-units --all

# 查看服务状态
systemctl status nginx

# 启动/停止/重启服务
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# 开机自启
sudo systemctl enable nginx
sudo systemctl disable nginx

# 查看启动耗时
systemd-analyze
systemd-analyze blame
```

---

# 3. 进程管理原理

## 3.1 进程与线程

```
┌─────────────────────────────────────────────────────────────────┐
│                    进程与线程的区别                               │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│           进程 (Process)          │  │          线程 (Thread)           │
├──────────────────────────────────┤  ├──────────────────────────────────┤
│ 独立的虚拟地址空间                 │  │ 共享进程的地址空间                │
│ 独立的文件描述符表                 │  │ 共享文件描述符表                  │
│ 独立的信号处理                     │  │ 共享信号处理                      │
│ 独立的资源限制                     │  │ 共享资源限制                      │
│ 进程间通信需要IPC                  │  │ 线程间通信直接共享内存             │
└──────────────────────────────────┘  └──────────────────────────────────┘

# 进程是资源分配的最小单位
# 线程是CPU调度的最小单位
```

```c
// 进程的内存布局
/*
 * 高地址
 * ┌──────────────────┐
 * │     栈          │  ← 函数调用、局部变量
 * │     ↓           │
 * │                 │
 * │     ↑           │
 * │     堆          │  ← malloc/new 分配
 * ├──────────────────┤
 * │   BSS段         │  ← 未初始化全局变量
 * │   Data段        │  ← 已初始化全局变量
 * │   Text段        │  ← 代码段 (只读)
 * └──────────────────┘
 * 低地址
 */
```

## 3.2 进程创建 (fork/exec)

```bash
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
```

```bash
# exec - 替换进程映像
# 用新程序替换当前进程的代码和数据

cat > exec_example.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("原程序: PID=%d\n", getpid());
    
    char *args[] = {"ls", "-la", NULL};
    execvp("ls", args);  // 替换当前进程映像
    
    // 如果execvp返回，说明执行失败
    perror("execvp failed");
    return 1;
}
EOF

gcc exec_example.c -o exec_example
./exec_example
```

## 3.3 进程状态与调度

```bash
# 进程状态
ps aux | head -5
# STAT列显示进程状态：
# R - 运行中 (Running)
# S - 可中断睡眠 (Interruptible Sleep)
# D - 不可中断睡眠 (Uninterruptible Sleep)
# Z - 僵尸进程 (Zombie)
# T - 暂停/跟踪 (Stopped/Traced)
# I - 空闲 (Idle)

# 查看进程树
pstree
pstree -p | head -20

# 查看进程状态
cat /proc/PID/status | grep -E "^(Name|State|Pid)"
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    进程状态转换图                                 │
└─────────────────────────────────────────────────────────────────┘

                    ┌────────┐
              ┌────►│  运行  │◄───────┐
              │     └────────┘        │
              │                        │
    调度器选择                        调度器抢走
              │                        │
              │     ┌────────┐        │
              └─────│  就绪  │        │
                    └────────┘        │
                                     │
         ┌───────────────────────────┤
         │                           │
         ▼                           ▼
   ┌───────────┐              ┌───────────┐
   │ 可中断睡眠 │              │不可中断睡眠│
   │   (S)    │              │   (D)    │
   └─────┬─────┘              └─────┬─────┘
         │                          │
         │ 收到信号/Wakeup           │ I/O完成/Wakeup
         │                          │
         └──────────┬─────────────────┘
                    │
                    ▼
              ┌────────┐
              │  僵尸  │
              │  (Z)  │
              └───┬────┘
                  │
                  │ 父进程调用wait()
                  │
                  ▼
              (进程退出)
```

---

# 4. 内存管理原理

## 4.1 虚拟内存机制

```bash
# 查看进程内存映射
cat /proc/self/maps

# 查看内存使用
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           15Gi       2.1Gi       11Gi       150Mi       1.8Gi        12Gi
# Swap:         2.0Gi          0B       2.0Gi

# 查看详细内存信息
cat /proc/meminfo

# 查看进程的内存使用
pmap -x PID
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    虚拟内存管理机制                               │
└─────────────────────────────────────────────────────────────────┘

应用程序请求内存                          内核分配内存
      │                                        │
      ▼                                        ▼
┌─────────────┐    页表查找     ┌─────────────────────────────┐
│ 虚拟地址    │ ──────────────► │ 物理内存 (RAM)               │
│ 0x00400000 │                 │ 或 交换空间 (Swap)           │
└─────────────┘                 └─────────────────────────────┘

# 页表 (Page Table)
# - 虚拟地址到物理地址的映射
# - 每个进程有自己的页表
# - 现代CPU使用TLB加速查找

# 页面 (Page)
# - Linux默认页面大小: 4KB
# - 大页 (Huge Pages): 2MB 或 1GB
```

## 4.2 内存分配机制

```bash
# 查看OOM (Out of Memory) killer日志
dmesg | grep -i "out of memory"
dmesg | grep -i "killed process"

# 查看OOM分数
cat /proc/PID/oom_score

# 调整OOM偏好度 (值越高越容易被杀)
echo 1000 > /proc/PID/oom_score_adj
```

```c
// 内存分配示例
#include <stdio.h>
#include <stdlib.h>

int main() {
    // 栈分配 (自动管理)
    int stack_var = 10;
    
    // 堆分配 (需要手动管理)
    int *heap_var = (int *)malloc(sizeof(int) * 100);
    if (heap_var == NULL) {
        fprintf(stderr, "malloc failed\n");
        return 1;
    }
    
    // 使用内存
    heap_var[0] = 42;
    
    // 释放内存
    free(heap_var);
    
    return 0;
}
```

## 4.3 Swap机制

```bash
# 查看swap使用
swapon -s
# Filename                Type        Size    Used    Priority
# /dev/sda2               partition   2097148 0       -2

# 创建swap文件
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 关闭swap
sudo swapoff /swapfile

# 设置swappiness (0-100, 越高越倾向使用swap)
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness=10
```

---

# 5. I/O系统原理

## 5.1 Linux I/O栈

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux I/O架构                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      应用层                                      │
│              (read/write, fopen/fclose)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    VFS (虚拟文件系统)                             │
│              (ext4, xfs, btrfs, proc, sysfs)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                  页缓存 (Page Cache)                             │
│                    (文件系统元数据缓存)                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│              通用块层 (Generic Block Layer)                      │
│                    (bio → request)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                I/O调度器 (I/O Scheduler)                         │
│           (noop, deadline, cfq, mq-deadline)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    设备驱动 (Device Driver)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    硬件设备 (Hardware)                           │
│                  (SSD, HDD, NVMe, RAID)                         │
└─────────────────────────────────────────────────────────────────┘
```

## 5.2 I/O调度算法

```bash
# 查看当前I/O调度器
cat /sys/block/sda/queue/scheduler
# [mq-deadline] kyber bfq none

# mq-deadline: 适合数据库等延迟敏感应用
# bfq: 适合桌面和多媒体
# none: 不进行调度，适合SSD

# 修改I/O调度器 (临时)
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

# 永久修改 (通过内核参数)
# 添加:elevator=mq-deadline 到 GRUB_CMDLINE_LINUX
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    I/O调度算法对比                               │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┬──────────────────────────────────────────────────┐
│   调度器      │                   特点                           │
├──────────────┼──────────────────────────────────────────────────┤
│  noop        │  先进先出，适合SSD或内存盘                        │
│  deadline    │  写请求期限保证，适合数据库                      │
│  cfq         │  完全公平调度，适合桌面系统                      │
│  mq-deadline │  多队列版本deadline，支持更高并发                 │
│  bfq         │  预算公平队列，适合多媒体                        │
└──────────────┴──────────────────────────────────────────────────┘
```

---

# 6. 内核模块管理

## 6.1 内核模块基础

```bash
# 查看已加载模块
lsmod
# Module                  Size  Used by
# xfs                   12345  1
# virtio_net            23456  2
# ext4                  45678  1

# 查看模块详情
modinfo virtio_net
# filename:       /lib/modules/5.4.0/kernel/drivers/net/virtio_net.ko
# version:        2.6.0
# license:        GPL
# description:    Virtio network driver
# author:         Rusty Russell

# 查看模块依赖
cat /proc/modules
```

## 6.2 模块操作

```bash
# 加载模块
sudo modprobe virtio_net

# 卸载模块
sudo modprobe -r virtio_net

# 强制卸载 (谨慎使用)
sudo modprobe -r --force virtio_net

# 查看模块参数
cat /sys/module/virtio_net/parameters/
```

---

# 7. 实战：搭建Linux环境

## 7.1 在虚拟机中安装Linux

```bash
# 使用QEMU/KVM创建虚拟机

# 1. 安装QEMU
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system

# 2. 创建虚拟机
virt-install \
    --name ubuntu20.04 \
    --ram 2048 \
    --disk path=/var/lib/libvirt/images/ubuntu20.04.qcow2,size=20 \
    --vcpus 2 \
    --os-variant ubuntu20.04 \
    --network network=default \
    --graphics vnc \
    --cdrom /path/to/ubuntu20.04.iso

# 3. 查看虚拟机
virsh list --all
virsh start ubuntu20.04
virsh console ubuntu20.04
```

## 7.2 Docker容器运行Linux

```bash
# 使用Docker运行轻量级Linux环境

# 启动Ubuntu容器
docker run -it --name mylinux ubuntu:20.04 /bin/bash

# 启动Alpine Linux (更轻量)
docker run -it --name alpine alpine /bin/sh

# 启动CentOS
docker run -it --name centos centos:8 /bin/bash

# 在容器中体验不同的Linux发行版
docker exec -it mylinux /bin/bash
```

## 7.3 验证Linux环境

```bash
# 验证内核版本
uname -a
# Linux localhost 5.4.0-generic #1 SMP ...

# 验证系统启动时间
uptime
# 19:11:23 up 2 days, 3:22, 1 user, load average: 0.15, 0.10, 0.08

# 验证运行级别
who -r
# run-level 3  2026-03-21 19:11

# 验证systemd版本
systemctl --version
# systemd 245 (245.4-4ubuntu3)
```

---

## 本章小结

- **内核空间与用户空间分离**提供了安全性和稳定性的基础
- **系统启动流程**从BIOS/UEFI → GRUB → Kernel → systemd
- **进程调度**使用CFS算法，保证公平性
- **内存管理**通过虚拟内存机制，让每个进程有独立地址空间
- **I/O系统**通过VFS和页缓存提供高性能文件操作
- **内核模块**允许动态加载/卸载设备驱动

**关键命令回顾：**

```bash
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
```