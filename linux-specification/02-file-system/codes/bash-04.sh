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