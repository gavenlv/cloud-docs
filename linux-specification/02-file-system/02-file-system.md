# 文件系统管理

## 本章导学

**学完本章后，你将能够：**

- 理解Linux文件系统的**底层架构**（VFS、页缓存、ext4内部原理）
- 掌握磁盘分区、格式化、挂载的完整流程
- 熟练使用inode和硬链接/软链接
- 理解磁盘配额和ACL的机制
- 从**原理**理解文件系统如何存储和检索数据

**学习方法：**

```
VFS架构 → 磁盘分区 → 文件系统创建 → 挂载配置 → 权限管理 → 实战操作
```

---

# 1. Linux文件系统架构

## 1.1 虚拟文件系统 (VFS)

```
┌─────────────────────────────────────────────────────────────────┐
│                    VFS (Virtual File System Switch)             │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │     应用程序     │
                    └────────┬────────┘
                             │ read()/write()
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      VFS (统一接口层)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ super_block │  │   inode     │  │  dentry     │           │
│  │ (文件系统信息) │  │ (文件元数据)  │  │ (目录项缓存) │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└────────┬────────────────┬────────────────┬─────────────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐
│    ext4     │  │     XFS     │  │   Btrfs     │  │  tmpfs  │
│  (ext4 FS)  │  │   (XFS FS)  │  │  (Btrfs FS) │  │ (内存 FS) │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────┘
```

**VFS核心数据结构：**

```c
// super_block - 文件系统超级块
struct super_block {
    struct list_head    s_list;          // 超级块链表
    struct super_operations *s_op;       // 超级块操作
    struct dentry       *s_root;          // 根目录dentry
    struct writeback_control *s_wb;      // 写回控制
    // ...
    void                *s_fs_info;       // 文件系统私有数据
};

// inode - 文件索引节点
struct inode {
    umode_t             i_mode;           // 文件类型和权限
    unsigned long       i_ino;            // inode号
    atomic_t            i_count;         // 引用计数
    loff_t              i_size;          // 文件大小
    struct timespec     i_atime;         // 访问时间
    struct timespec     i_mtime;         // 修改时间
    struct timespec     i_ctime;         // 状态改变时间
    const struct inode_operations *i_op; // inode操作
    struct super_block  *i_sb;           // 所属超级块
    // ...
};

// dentry - 目录项
struct dentry {
    unsigned int d_flags;                // 目录标志
    struct inode *d_inode;              // 关联的inode
    struct qstr   d_name;               // 文件名
    struct dentry *d_parent;            // 父目录
    struct list_head d_subdirs;         // 子目录
    // ...
};
```

## 1.2 页缓存 (Page Cache)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux页缓存机制                                │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐     ┌──────────────────────────────────┐
│          磁盘上的文件               │     │          内存中的页缓存            │
│                                  │     │                                  │
│  ┌──────────────────────────┐   │     │  ┌──────────────────────────┐   │
│  │      文件数据             │   │     │  │      struct page          │   │
│  │      (4KB page)          │   │◄───►│  │  - mapping: struct address_space * │
│  │                          │   │ 读取 │  │  - index: 页帧号           │   │
│  └──────────────────────────┘   │     │  │  - flags: PG_dirty等       │   │
│                                  │     │  └──────────────────────────┘   │
└──────────────────────────────────┘     └──────────────────────────────────┘

# write()流程:
# 1. 应用程序调用write()
# 2. 数据写入页缓存 (Page Cache)
# 3. 页缓存标记为脏页 (PG_dirty)
# 4. pdflush/flush内核线程定期刷回磁盘

# read()流程:
# 1. 应用程序调用read()
# 2. 检查页缓存是否存在
# 3. 如果存在，直接从缓存返回 (缓存命中)
# 4. 如果不存在，从磁盘读取并加入缓存 (缓存未命中)
```

---

# 2. 磁盘分区管理

## 2.1 MBR与GPT分区表

```
┌─────────────────────────────────────────────────────────────────┐
│                    MBR vs GPT 分区表                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────┬────────────────────────────────────────┐
│          MBR            │                 GPT                     │
├─────────────────────────┼────────────────────────────────────────┤
│  磁盘开头512字节        │  使用整个磁盘，无容量限制                 │
│  最大支持2TB磁盘        │  支持 >2TB 磁盘                        │
│  最多4个主分区          │  最多128个分区                         │
│  兼容性最好             │  需要UEFI支持                          │
│  分区信息存在DPT中      │  分区信息存在GPT头和备份GPT中            │
└─────────────────────────┴────────────────────────────────────────┘

# MBR布局
┌─────────────────────────────────────┐
│        主引导扇区 (512字节)          │
├─────────────┬───────────────────────┤
│  446字节    │   64字节分区表 (4项)   │
│  引导代码    │   每项16字节           │
├─────────────┴───────┬────────────────┤
│    2字节           │   55AA (结束标志)  │
│    签名            │                   │
└───────────────────┴───────────────────┘
```

## 2.2 分区操作命令

```bash
# 查看磁盘分区
lsblk
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda      8:0    0   100G  0 disk
# ├─sda1   8:1    0   500M  0 part /boot/efi
# ├─sda2   8:2    0    50G  0 part /
# └─sda3   8:3    0   49.5G 0 part /data

# 查看分区表
fdisk -l /dev/sda

# 使用fdisk分区 (交互式)
sudo fdisk /dev/sdb
# 常用命令:
# m - 显示帮助
# p - 显示分区表
# n - 创建新分区
# d - 删除分区
# t - 改变分区类型
# w - 保存并退出
# q - 不保存退出

# 使用parted分区 (支持GPT)
sudo parted /dev/sdb
(parted) mklabel gpt
(parted) mkpart primary ext4 0% 100%
(parted) print
(parted) quit

# 刷新分区表
sudo partprobe /dev/sdb

# 查看分区UUID
blkid
sudo blkid /dev/sda1
```

## 2.3 分区实战

```bash
# 场景: 添加一块新磁盘，创建分区并挂载

# 1. 查看新磁盘
ls -la /dev/sd*
# sda (系统盘)
# sdb (新磁盘，未分区)

# 2. 使用fdisk创建分区
sudo fdisk /dev/sdb
# 输入:
# n (新建分区)
# p (主分区)
# 1 (分区号)
# 回车 (默认起始扇区)
# 回车 (默认结束扇区，使用整个磁盘)
# w (保存)

# 3. 查看新分区
lsblk /dev/sdb
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sdb      8:16   0   100G  0 disk
# └─sdb1   8:17   0   100G  0 part

# 4. 格式化分区
sudo mkfs.ext4 /dev/sdb1

# 5. 创建挂载点
sudo mkdir -p /data

# 6. 临时挂载
sudo mount /dev/sdb1 /data

# 7. 永久挂载 (添加fstab)
echo '/dev/sdb1 /data ext4 defaults 0 2' | sudo tee -a /etc/fstab

# 8. 验证
df -h /data
mount | grep /data
```

---

# 3. 文件系统操作

## 3.1 常见文件系统对比

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux常见文件系统对比                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────────┐
│ 文件系统 │  最大文件 │  最大卷  │  日志    │  特性      │    适用场景    │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────────┤
│  ext4   │  16TB   │  1EB   │  支持   │  向后兼容 │  通用场景    │
│  XFS    │  8EB   │  8EB   │  支持   │  高性能   │  大文件/数据库 │
│  Btrfs  │  16EB  │  16EB  │  支持   │  快照/压缩 │  现代工作负载  │
│  tmpfs  │  RAM大小│  RAM大小│  无     │  内存文件系统│  临时文件    │
│  NFS    │  依赖服务器│  依赖服务器│  支持   │  网络共享   │  网络存储    │
│  ZFS    │  16EB  │  256ZB │  支持   │  快照/校验 │  数据中心    │
└─────────┴─────────┴─────────┴─────────┴─────────┴─────────────┘
```

## 3.2 创建文件系统

```bash
# 创建ext4文件系统
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.ext4 -L DATA /dev/sdb1        # 带卷标
sudo mkfs.ext4 -E stride=64,stripe-width=128 /dev/sdb1  # RAID优化

# 创建XFS文件系统
sudo mkfs.xfs /dev/sdb1
sudo mkfs.xfs -L DATA /dev/sdb1

# 创建Btrfs文件系统
sudo mkfs.btrfs /dev/sdb1

# 创建tmpfs (内存文件系统)
sudo mount -t tmpfs -o size=2G tmpfs /mnt/tmp

# 查看文件系统信息
sudo dumpe2fs /dev/sdb1 | head -50      # ext4
sudo xfs_info /dev/sdb1                  # XFS
sudo btrfs filesystem show /dev/sdb1     # Btrfs
```

## 3.3 文件系统检查与修复

```bash
# ext4文件系统检查
sudo fsck.ext4 /dev/sdb1                # 检查
sudo fsck.ext4 -p /dev/sdb1             # 自动修复
sudo fsck.ext4 -y /dev/sdb1             # 修复所有问题

# XFS文件系统检查
sudo xfs_check /dev/sdb1                # 检查
sudo xfs_repair /dev/sdb1               # 修复 (不能在线修复)

# Btrfs检查
sudo btrfs check /dev/sdb1              # 检查
sudo btrfs check --repair /dev/sdb1     # 修复

# 查看inode使用情况
sudo df -i /data

# 修复损坏的超级块 (ext4)
sudo mkfs.ext4 -n /dev/sdb1            # 查看备份超级块位置
sudo fsck.ext4 -b 32768 /dev/sdb1       # 使用备份超级块修复
```

---

# 4. 挂载与fstab

## 4.1 mount命令详解

```bash
# 基础挂载
sudo mount /dev/sdb1 /data

# 指定文件系统类型
sudo mount -t ext4 /dev/sdb1 /data
sudo mount -t nfs4 server:/share /mnt/nfs

# 挂载选项
sudo mount -o rw,suid,dev,exec,auto,nouser,async /dev/sdb1 /data

# 常用挂载选项:
# ro       - 只读
# rw       - 读写
# suid     - 允许setuid
# dev      - 允许设备文件
# exec     - 允许执行二进制
# auto     - 开机自动挂载
# noauto   -不开机自动挂载
# user     - 允许普通用户挂载
# nouser   - 只允许root挂载
# async    - 异步I/O
# sync     - 同步I/O
# defaults - rw,suid,dev,exec,auto,nouser,async

# 重新挂载 (修改挂载选项)
sudo mount -o remount,rw /

# 绑定挂载
sudo mount --bind /old /new

# 查看所有挂载
mount
mount | grep /dev/sdb

# 查看进程挂载空间
df -h
df -h /data
```

## 4.2 fstab配置

```
┌─────────────────────────────────────────────────────────────────┐
│                    /etc/fstab 配置格式                          │
└─────────────────────────────────────────────────────────────────┘

# 格式: <device> <mount point> <type> <options> <dump> <pass>

# 字段说明:
# device     - 设备文件、UUID、LABEL
# mount point- 挂载点路径
# type       - 文件系统类型 (ext4, xfs, nfs, etc)
# options    - 挂载选项 (defaults, ro, noauto, etc)
# dump       - dump备份标志 (0=不备份, 1=备份)
# pass       - fsck顺序 (0=不检查, 1=根分区, 2=其他分区)

# 示例:
UUID=xxxx-xxxx-xxxx   /boot/efi   vfat    defaults        0 2
UUID=xxxx-xxxx-xxxx   /           ext4    defaults        0 1
UUID=xxxx-xxxx-xxxx   /data       ext4    defaults        0 2
server:/share         /mnt/nfs    nfs4    defaults        0 0
```

```bash
# fstab常用配置示例

# 1. 通过UUID挂载 (推荐)
UUID=550e8400-e29b-41d4-a716-446655440000 /data ext4 defaults 0 2

# 2. 通过LABEL挂载
LABEL=DATA /data ext4 defaults 0 2

# 3. 挂载NFS
server.example.com:/nfs/share /mnt/nfs nfs4 defaults 0 0

# 4. 挂载ISO
/home/user/image.iso /mnt/iso iso9660 loop,ro 0 0

# 5. 挂载tmpfs (内存文件系统)
tmpfs /mnt/tmp tmpfs defaults,size=2g 0 0

# 验证fstab配置 (在不挂载的情况下测试)
sudo findmnt --verify /etc/fstab
sudo mount -a                           # 尝试挂载所有fstab中的项
```

## 4.3 systemd挂载单元

```bash
# systemd使用.mount单元代替fstab

# 示例: /data挂载单元
cat /etc/systemd/system/data.mount
#[Unit]
#Description=Data Mount
#After=local-fs.target
#
#[Mount]
#What=/dev/sdb1
#Where=/data
#Type=ext4
#Options=defaults
#
#[Install]
#WantedBy=multi-user.target

# 管理systemd挂载
sudo systemctl daemon-reload
sudo systemctl start data.mount
sudo systemctl enable data.mount
sudo systemctl status data.mount
```

---

# 5. inode与链接

## 5.1 inode详解

```
┌─────────────────────────────────────────────────────────────────┐
│                    inode (索引节点) 结构                          │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                        inode 内容                             │
├──────────────────────────────────────────────────────────────┤
│  inode编号 (i_ino)                                           │
│  文件类型和权限 (i_mode)                                     │
│  硬链接计数 (i_links_count)                                  │
│  用户ID (i_uid)                                             │
│  组ID (i_gid)                                               │
│  文件大小 (i_size) / 占用的块数 (i_blocks)                    │
│  访问时间 atime (i_atime)                                   │
│  修改时间 mtime (i_mtime)                                   │
│  状态改变时间 ctime (i_ctime)                                │
│  块指针 (i_block[15]) - 指向数据块                           │
└──────────────────────────────────────────────────────────────┘

# inode直接/间接块指针 (ext4):
# i_block[0-11]  - 直接块 (12 * 4KB = 48KB)
# i_block[12]    - 间接块 (1024 * 4KB = 4MB)
# i_block[13]    - 双间接块 (1024 * 1024 * 4KB = 4GB)
# i_block[14]    - 三间接块 (1024^3 * 4KB = 4TB)
```

```bash
# 查看inode信息
stat /etc/passwd
# File: /etc/passwd
# Size: 2345       Blocks: 8          IO Block: 4096   regular file
# Device: 08:01     Inode: 131073      Links: 1
# Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
# Access: 2026-03-21 19:11:23.123456789 +0800
# Modify: 2026-01-15 10:30:00.000000000 +0800
# Change: 2026-03-21 19:10:56.123456789 +0800

# 查看文件系统inode使用情况
df -i
# Filesystem      Inodes  IUsed   IFree IUse% Mounted on
# /dev/sda2      655360  89543  565817   14% /

# 查看目录inode号
ls -li /etc

# 查看文件inode号
ls -i /etc/passwd
```

## 5.2 硬链接与软链接

```
┌─────────────────────────────────────────────────────────────────┐
│                    硬链接 vs 软链接                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┬─────────────────────────────────┐
│            硬链接 (Hard Link)    │           软链接 (Symbolic Link) │
├─────────────────────────────────┼─────────────────────────────────┤
│  多个文件名指向同一个inode       │  创建一个特殊文件,包含目标路径     │
│  不能跨文件系统                 │  可以跨文件系统                   │
│  不能链接目录                   │  可以链接目录                     │
│  删除一个,其他仍有效             │  删除源文件,链接失效              │
│  inode链接计数减为0才删除        │  类似快捷方式                     │
└─────────────────────────────────┴─────────────────────────────────┘

# 原理图:

# 硬链接:
# ┌─────────────────┐        ┌─────────────────┐
# │ filename: file1 │        │ filename: file2 │
# │ inode: 123456   │        │ inode: 123456   │
# └────────┬────────┘        └────────┬────────┘
#          │                          │
#          └──────────┬───────────────┘
#                     │
#                     ▼
#              ┌─────────────┐
#              │   inode     │
#              │   123456    │
#              │ links: 2    │
#              └─────────────┘

# 软链接:
# ┌─────────────────┐        ┌─────────────────┐
# │ file1 -> file2  │        │   file2         │
# │ (软链接文件)    │   ──►  │ (原文件)         │
# │ type: symlink   │  指向  │ type: regular   │
# └─────────────────┘        └─────────────────┘
```

```bash
# 创建硬链接
ln /path/to/source /path/to/hardlink

# 创建软链接
ln -s /path/to/source /path/to/symlink

# 示例
touch original.txt
ln original.txt hardlink.txt
ln -s original.txt symlink.txt

# 查看
ls -li original.txt hardlink.txt symlink.txt
# 1310813 -rw-r--r-- 2 user group  0 Mar 21 19:11 original.txt
# 1310813 -rw-r--r-- 1 user group  0 Mar 21 19:11 hardlink.txt    # 同一inode
# 1310814 lrwxrwxrwx 1 user group 11 Mar 21 19:11 symlink.txt -> original.txt  # 软链接

# 查看链接指向
readlink symlink.txt
readlink -f symlink.txt                # 解析最终目标

# 删除原文件测试
rm original.txt
cat hardlink.txt                       # 仍可访问
cat symlink.txt                        # 报错: No such file or directory

# 目录链接计数
mkdir /tmp/testdir
ls -ld /tmp/testdir
# 目录的链接数 = 2 + 子目录数 (每个子目录包含 .. 指向父目录)
```

---

# 6. 磁盘配额

## 6.1 配额原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    Linux磁盘配额机制                              │
└─────────────────────────────────────────────────────────────────┘

# 配额限制类型:
# - 块限制: 限制使用的磁盘空间
# - inode限制: 限制创建的文件数量

# 配额用户/组:
# - 用户配额: 针对单个用户
# - 组配额: 针对单个组

# 软限制和硬限制:
# - 软限制 (soft limit): 达到时警告,但仍可写入
# - 硬限制 (hard limit): 绝对不能超过
# - 宽限期 (grace period): 超过软限制后的宽限期

# 配额文件:
# - aquota.user: 用户配额
# - aquota.group: 组配额
```

## 6.2 配额配置

```bash
# 1. 安装配额工具
sudo apt install quota                      # Debian/Ubuntu
sudo yum install quota                      # CentOS/RHEL

# 2. 启用文件系统配额支持
sudo mount -o remount,usrquota,grpquota /data

# 3. 永久启用配额 (/etc/fstab)
# /dev/sdb1 /data ext4 defaults,usrquota,grpquota 0 2

# 4. 创建配额文件
sudo quotacheck -cug /data

# 5. 启用配额
sudo quotaon /data

# 6. 设置用户配额
sudo edquota username
# Disk quotas for user username (uid 1000):
#   Filesystem                   blocks               soft               hard       inodes               soft     hard
#   /dev/sdb1                       10                  1000               2000          5                 100      200

# 7. 设置宽限期
sudo edquota -t
# Grace period before enforcing soft limits for users:
# Time units may be: days, hours, minutes, or seconds
#   Filesystem                block grace period                 inode grace period
#   /dev/sdb1                      7 days                              7 days

# 8. 复制配额到其他用户
sudo edquota -p user1 user2 user3

# 9. 查看配额
sudo quota -u username
sudo quota -g groupname
sudo repquota -a
```

## 6.3 配额实战

```bash
# 场景: 为/data设置用户配额,限制用户jack最多使用10GB

# 1. 查看/data文件系统
df -h /data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdb1        50G   10G   40G  20% /data

# 2. 确保配额已启用
sudo mount | grep /data
# /dev/sdb1 on /data type ext4 (rw,relatime,quota,usrquota,grpquota)

# 3. 创建配额文件
sudo quotacheck -cug /data

# 4. 启用配额
sudo quotaon /data

# 5. 设置用户配额 (10GB软限制,12GB硬限制)
sudo edquota -u jack
# 设置:
# /dev/sdb1  0 10485760 12582912  0 0 0

# 6. 验证配额
sudo quota -u jack
# Disk quotas for user jack (uid 1001):
#   Filesystem  blocks   quota   limit   grace   files   quota   limit   grace
#   /dev/sdb1       0   10485760   12582912               0         0         0

# 7. 测试配额
su - jack
dd if=/dev/zero of=/data/test bs=1M count=10000
# dd: error writing '/data/test': Disk quota exceeded  # 达到限制!
```

---

# 7. ACL访问控制列表

## 7.1 ACL原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    POSIX ACL 机制                                │
└─────────────────────────────────────────────────────────────────┘

# 传统Linux权限: user-group-other (UGO)
# ACL扩展: 可以为多个用户/组设置不同权限

# ACL条目类型:
# - owner@: 文件所有者
# - group@: 文件所属组
# - user::mask: 用户权限掩码
# - group::mask: 组权限掩码
# - other:: 其他人权限
# - user:UID: 指定用户权限
# - group:GID: 指定组权限

# ACL计算过程:
# 1. 如果进程有效用户ID等于文件所有者 -> 应用 owner@ 权限
# 2. 如果进程有效用户ID匹配user:条目 -> 应用该条目权限(受mask限制)
# 3. 如果进程有效组ID或附属组ID匹配group@或group:GID条目 -> 应用匹配条目权限(受mask限制)
# 4. 否则 -> 应用 other@ 权限
```

## 7.2 ACL操作

```bash
# 查看文件ACL
getfacl /path/to/file

# 示例输出:
# # file: test.txt
# # owner: alice
# # group: alice
# user::rw-
# group::r--
# other::r--
# user:bob:rw-
# group:dev:r-x

# 设置ACL
setfacl -m u:bob:rw /path/to/file        # 设置用户bob读写权限
setfacl -m g:dev:r-x /path/to/file       # 设置组dev读执行权限
setfacl -m o::r /path/to/file            # 设置其他人只读权限
setfacl -m m::rwx /path/to/file          # 设置权限掩码

# 删除ACL条目
setfacl -x u:bob /path/to/file           # 删除用户bob的ACL
setfacl -x g:dev /path/to/file           # 删除组dev的ACL
setfacl -b /path/to/file                  # 删除所有扩展ACL

# 复制ACL
getfacl file1 | setfacl --set-file=- file2

# 目录默认ACL
setfacl -m d:u:bob:rw /path/to/dir       # 设置目录默认ACL
                                             # 该目录下新建文件自动继承

# 递归设置
setfacl -R -m u:bob:rw /path/to/dir      # 递归设置
setfacl -R -m d:u:bob:rw /path/to/dir   # 递归设置默认ACL
```

## 7.3 ACL实战

```bash
# 场景: /projects目录,需要不同团队有不同权限

# 1. 查看目录结构
ls -la /projects
# drwxr-x-x  3 root root 4096 Mar 21 19:11 .
# drwxr-xr-x  2 root root 4096 Mar 21 19:11 ..
# drwxrws---  2 alice  project-a 4096 Mar 21 19:11 project-a
# drwxrws---  2 alice  project-b 4096 Mar 21 19:11 project-b

# 2. 查看当前ACL
getfacl /projects/project-a
# # file: project-a
# # owner: alice
# # group: project-a
# user::rwx
# group::r-x
# other::---

# 3. 设置ACL - 允许dev团队读写project-a
sudo setfacl -m g:dev:rw /projects/project-a

# 4. 验证
getfacl /projects/project-a
# user::rwx
# group::r-x
# group::dev:rw-
# mask::rwx
# other::---

# 5. 测试权限
# 以dev组用户身份
touch /projects/project-a/test.txt      # 应该成功
touch /projects/project-b/test.txt       # 应该失败 (Permission denied)

# 6. 查看权限是否生效
ls -la /projects/
# drwxrws---+ 2 alice  project-a 4096 Mar 21 19:11 project-a
#                                          ^
#                                          | ACL标记
```

---

# 8. 特殊文件系统

## 8.1 伪文件系统

```bash
# /proc - 进程和内核信息
ls /proc/
# 1/      1234/    cpuinfo    meminfo     mounts      net/

cat /proc/cpuinfo | head -10
cat /proc/meminfo | head -10
cat /proc/uptime
cat /proc/loadavg

# /sys - sysfs, 内核对象信息
ls /sys/
# block/  bus/  class/  dev/  devices/  firmware/  fs/  kernel/  module/

# /dev - 设备文件
ls /dev/
# null  zero  random  urandom  tty  sda  sda1  ...

# /tmp - 临时文件 (通常tmpfs)
mount | grep /tmp
# tmpfs on /tmp type tmpfs (rw,nosuid,nodev)

# /run - 运行数据 (tmpfs)
ls /run/
# systemd/  lock/  log/
```

## 8.2 特殊设备文件

```bash
# 特殊设备:
# /dev/null   - 丢弃所有写入的数据
# /dev/zero   - 提供无限零字节
# /dev/random - 提供加密安全的随机数
# /dev/urandom - 提供非阻塞随机数
# /dev/full   - 总是报告磁盘满
# /dev/null   - 黑洞设备

# 使用示例
cat /dev/zero | head -c 100 > /dev/null   # 丢弃
dd if=/dev/zero of=testfile bs=1M count=100  # 创建100MB零文件
cat /dev/random | tr -dc 'a-zA-Z0-9' | head -c 32  # 生成随机字符串

# 创建loop设备
sudo losetup -f                           # 查找空闲loop设备
sudo losetup /dev/loop0 /path/to/image   # 关联文件到loop设备
sudo losetup -d /dev/loop0               # 解除关联
```

---

# 9. 实战: 搭建LAMP环境

```bash
# 场景: 搭建LAMP环境,分离数据和系统盘

# 1. 添加新磁盘并分区
sudo fdisk /dev/sdb
# n, p, 1, w

# 2. 格式化
sudo mkfs.ext4 /dev/sdb1

# 3. 创建MySQL数据目录
sudo mkdir -p /data/mysql

# 4. 挂载
echo '/dev/sdb1 /data ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo mount -a

# 5. 设置权限
sudo chown -R mysql:mysql /data/mysql
sudo chmod 750 /data/mysql

# 6. 安装MySQL
sudo apt install mysql-server

# 7. 配置MySQL使用新数据目录
sudo systemctl stop mysql
sudo rsync -av /var/lib/mysql/ /data/mysql/

# 8. 修改MySQL配置
# 编辑/etc/mysql/mysql.conf.d/mysqld.cnf
# datadir = /data/mysql

# 9. AppArmor/selinux配置
sudo apparmor_parser -r /etc/apparmor.d/*

# 10. 启动验证
sudo systemctl start mysql
mysql -u root -p -e "SHOW VARIABLES LIKE 'datadir';"
```

---

## 本章小结

- **VFS**提供统一接口,让不同文件系统对上层透明
- **页缓存**通过内存缓存磁盘数据,提高I/O性能
- **MBR/GPT**分区表格式影响磁盘容量和分区数量
- **挂载**将文件系统关联到目录树,fstab实现永久挂载
- **inode**存储文件元数据,是文件系统的核心结构
- **硬链接**多个名字指向同一inode,**软链接**是特殊文件包含目标路径
- **磁盘配额**通过软限制/硬限制控制用户磁盘使用
- **ACL**提供比UGO更细粒度的权限控制

**关键命令回顾:**

```bash
# 分区和文件系统
lsblk, fdisk, parted, mkfs.ext4, mkfs.xfs, mkfs.btrfs

# 挂载
mount, umount, findmnt, /etc/fstab, systemctl status *.mount

# inode和链接
stat, ls -li, ln, ln -s, readlink

# 配额
quota, edquota, repquota, quotacheck, quotaon

# ACL
getfacl, setfacl

# 检查和修复
fsck, dumpe2fs, xfs_info, xfs_repair
```