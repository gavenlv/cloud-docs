# 1. 查看容器挂载
docker inspect web-server | grep -A 20 Mounts

# 2. 查看数据卷列表
docker volume ls

# 3. 查看数据卷详细信息
docker volume inspect my-volume

# 4. 查看数据卷使用情况
docker system df -v | grep VOLUME

# 5. 查看磁盘使用情况
docker exec web-server df -h

# 6. 查看inode使用情况
docker exec web-server df -i

# 7. 查看存储驱动
docker info | grep "Storage Driver"

# 8. 查看存储驱动详细信息
docker info | grep -A 20 "Storage Driver"

# 9. 查看容器文件系统
docker exec web-server ls -la /

# 10. 查看容器文件系统使用情况
docker exec web-server du -sh /path/to/dir

# 11. 查看容器文件系统inode使用情况
docker exec web-server du -si /path/to/dir

# 12. 查看容器文件系统权限
docker exec web-server ls -ld /path/to/dir

# 13. 查看容器文件系统挂载
docker exec web-server mount | grep /path/to/dir

# 14. 查看容器文件系统空间
docker exec web-server df -h /path/to/dir

# 15. 查看容器文件系统inode
docker exec web-server df -i /path/to/dir