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