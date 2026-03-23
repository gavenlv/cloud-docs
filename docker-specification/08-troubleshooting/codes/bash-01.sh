# 错误1：镜像不存在
# 错误信息：
# Unable to find image 'nginx:latest' locally
# docker: Error response from daemon: pull access denied for nginx, repository does not exist or may require 'docker login': denied: requested access to the resource is denied

# 解决方案：
# 1. 检查镜像名称和标签
docker images | grep nginx

# 2. 拉取镜像
docker pull nginx:latest

# 3. 使用正确的镜像名称和标签
docker run -d --name web-server nginx:latest

# 错误2：端口冲突
# 错误信息：
# docker: Error response from daemon: driver failed programming external connectivity on endpoint web-server (abc123def4567890123456789012345678901234567890123456789012345678): Bind for 0.0.0.0:80 failed: port is already allocated

# 解决方案：
# 1. 查看端口占用
netstat -tulpn | grep :80
# 或
ss -tulpn | grep :80

# 2. 查看占用端口的进程
lsof -i :80

# 3. 停止占用端口的容器
docker stop $(docker ps -q --filter "publish=80")

# 4. 使用不同的端口
docker run -d --name web-server -p 8080:80 nginx

# 5. 停止占用端口的进程
sudo kill -9 <PID>

# 错误3：内存不足
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: process_linux.go:545: container init caused: write /proc/self/attr/keycreate: invalid argument

# 解决方案：
# 1. 查看内存使用情况
free -h

# 2. 查看容器内存限制
docker inspect web-server | grep -A 10 Memory

# 3. 增加内存限制
docker run -d --name web-server --memory="1g" nginx

# 4. 减少其他容器的内存使用
docker update --memory="256m" other-container

# 5. 清理未使用的容器和镜像
docker system prune -a

# 错误4：磁盘空间不足
# 错误信息：
# docker: Error response from daemon: write /var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged: no space left on device

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 查看Docker磁盘使用情况
docker system df

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

# 错误5：配置错误
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: exec: "nginx": executable file not found in $PATH

# 解决方案：
# 1. 检查命令是否正确
docker run -it nginx:latest which nginx

# 2. 使用正确的命令
docker run -d --name web-server nginx:latest nginx -g "daemon off;"

# 3. 检查Dockerfile中的CMD和ENTRYPOINT
cat Dockerfile | grep -E "CMD|ENTRYPOINT"

# 4. 修改Dockerfile
# CMD ["nginx", "-g", "daemon off;"]

# 错误6：权限问题
# 错误信息：
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:380: starting container process caused: exec: "nginx": permission denied

# 解决方案：
# 1. 检查文件权限
ls -la /path/to/file

# 2. 修改文件权限
chmod +x /path/to/file

# 3. 使用正确的用户
docker run -d --name web-server --user nginx nginx

# 4. 检查Dockerfile中的USER指令
cat Dockerfile | grep USER

# 5. 修改Dockerfile
# USER nginx