# Jenkins Docker Compose部署

## 快速启动

```bash
# 进入目录
cd jenkins-specification/docker

# 启动Jenkins
docker-compose up -d

# 查看日志
docker-compose logs -f

# 获取初始管理员密码
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## 访问Jenkins

- URL: http://localhost:8080
- 首次访问需要解锁Jenkins并安装推荐插件

## 停止和清理

```bash
# 停止服务
docker-compose down

# 删除数据(慎用)
docker-compose down -v
```

## 配置说明

### 环境变量

- `JAVA_OPTS`: JVM参数，默认`-Xmx512m -Xms256m`
- `JENKINS_OPTS`: Jenkins启动选项

### 端口映射

- `8080`: Jenkins Web界面
- `50000`: Agent通信端口

### 数据持久化

- `jenkins_home`卷: 存储Jenkins配置和数据