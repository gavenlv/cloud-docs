# 错误1：权限问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/var/lib/docker/volumes/my-volume/_data" to rootfs at "/data" caused: permission denied

# 解决方案：
# 1. 检查文件权限
ls -la /path/to/file

# 2. 修改文件权限
chmod 755 /path/to/file
chown -R 1000:1000 /path/to/file

# 3. 使用正确的用户
docker run -d --name web-server --user 1000:1000 -v /path/to/file:/data nginx

# 4. 使用--userns-remap
docker run -d --name web-server --userns-remap default -v /path/to/file:/data nginx

# 5. 配置SELinux
chcon -Rt svirt_sandbox_file_t /path/to/file

# 6. 配置AppArmor
# 编辑AppArmor配置文件

# 错误2：磁盘空间不足
# 错误信息：
# docker: Error response from daemon: write /var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged: no space left on device

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 查看inode使用情况
df -i

# 3. 清理未使用的镜像
docker image prune -a

# 4. 清理未使用的容器
docker container prune

# 5. 清理未使用的数据卷
docker volume prune

# 6. 清理所有未使用的资源
docker system prune -a --volumes

# 7. 增加磁盘空间
# （需要系统管理员操作）

# 8. 清理Docker缓存
docker builder prune

# 错误3：挂载点错误
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/var/lib/docker/volumes/my-volume/_data" to rootfs at "/data" caused: no such file or directory

# 解决方案：
# 1. 检查挂载点是否存在
ls -la /path/to/mount

# 2. 创建挂载点
mkdir -p /path/to/mount

# 3. 修改挂载点权限
chmod 755 /path/to/mount

# 4. 使用正确的挂载点
docker run -d --name web-server -v /path/to/mount:/data nginx

# 5. 使用数据卷
docker volume create my-volume
docker run -d --name web-server -v my-volume:/data nginx

# 错误4：数据卷问题
# 错误信息：
# docker: Error response from daemon: volume my-volume not found

# 解决方案：
# 1. 检查数据卷是否存在
docker volume ls | grep my-volume

# 2. 创建数据卷
docker volume create my-volume

# 3. 查看数据卷详细信息
docker volume inspect my-volume

# 4. 使用正确的数据卷名称
docker run -d --name web-server -v my-volume:/data nginx

# 5. 检查数据卷权限
ls -la /var/lib/docker/volumes/my-volume/_data

# 6. 修改数据卷权限
chmod 755 /var/lib/docker/volumes/my-volume/_data

# 错误5：绑定挂载问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: rootfs_linux.go:75: mounting "/path/to/host/dir" to rootfs at "/data" caused: no such file or directory

# 解决方案：
# 1. 检查源路径是否存在
ls -la /path/to/host/dir

# 2. 创建源路径
mkdir -p /path/to/host/dir

# 3. 修改源路径权限
chmod 755 /path/to/host/dir

# 4. 使用正确的源路径
docker run -d --name web-server -v /path/to/host/dir:/data nginx

# 5. 使用绝对路径
docker run -d --name web-server -v $(pwd)/data:/data nginx

# 6. 检查挂载选项
docker run -d --name web-server -v /path/to/host/dir:/data:ro nginx