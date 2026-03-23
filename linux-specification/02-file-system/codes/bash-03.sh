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