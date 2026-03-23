# 1. 忘记root密码
# 解决: 进入单用户模式重置密码

# Grub菜单按e编辑
# 找到 linux 行的末尾
# 添加: init=/bin/bash
# 按Ctrl+x启动
# 挂载根文件系统
mount -o remount,rw /
# 修改密码
passwd root
# 重启
exec /sbin/init

# 2. 修复Grub
# 使用Live CD启动
# 挂载系统分区
mount /dev/sda1 /mnt
# 重新安装Grub
grub-install --root-directory=/mnt /dev/sda

# 3. 文件系统损坏
# 检查并修复
fsck /dev/sda1
fsck.ext4 -p /dev/sda1  # 自动修复

# 4. 查看启动日志
journalctl -b -1          # 上次启动日志
dmesg | grep -i error
cat /var/log/boot.log