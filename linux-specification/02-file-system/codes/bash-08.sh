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