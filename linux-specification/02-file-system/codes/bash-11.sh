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