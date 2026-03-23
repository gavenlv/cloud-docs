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