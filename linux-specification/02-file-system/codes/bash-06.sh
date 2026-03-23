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