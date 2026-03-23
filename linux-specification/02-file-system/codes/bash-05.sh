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