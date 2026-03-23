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