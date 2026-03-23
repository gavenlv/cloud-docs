# 1. 查看容器日志
docker logs web-server

# 2. 查看容器日志（实时）
docker logs -f web-server

# 3. 查看容器日志（最后100行）
docker logs --tail 100 web-server

# 4. 查看容器日志（带时间戳）
docker logs -t web-server

# 5. 进入容器
docker exec -it web-server /bin/bash

# 6. 查看容器进程
docker top web-server

# 7. 查看容器资源使用
docker stats web-server

# 8. 查看容器详细信息
docker inspect web-server

# 9. 查看容器端口
docker port web-server

# 10. 查看容器变化
docker diff web-server

# 11. 查看容器文件系统
docker export web-server | tar -xvf -

# 12. 复制文件到容器
docker cp /path/to/file web-server:/path/in/container

# 13. 从容器复制文件
docker cp web-server:/path/in/container /path/to/file

# 14. 在容器中执行命令
docker exec web-server ls -la

# 15. 在容器中执行交互式命令
docker exec -it web-server /bin/bash