# Docker安装Jenkins

# 1. 拉取镜像 (LTS版本)
docker pull jenkins/jenkins:lts

# 2. 运行容器
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# 3. 查看日志获取初始密码
docker logs jenkins
# 或
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# 4. 访问Web界面
# http://localhost:8080

# 常用Docker选项:
# -v jenkins_home:/var/jenkins_home  # 数据持久化
# -p 8080:8080                        # Web界面端口
# -p 50000:50000                      # Agent通信端口
# --restart unless-stopped            # 自动重启