# ============================================================
# 基础命令
# ============================================================

# 启动所有服务（前台）
docker-compose up

# 启动所有服务（后台）
docker-compose up -d

# 参数说明:
# ├── -d: 后台运行（detached）
# ├── --build: 重新构建镜像
# ├── --force-recreate: 强制重新创建容器
# ├── --no-deps: 不启动依赖的服务
# └── --remove-orphans: 清理孤儿容器


# ============================================================
# 停止命令
# ============================================================

# 停止并删除容器、网络（保留卷）
docker-compose down

# 参数说明:
# ├── -v: 同时删除卷
# ├── --remove-orphans: 清理孤儿容器
# └── --rmi local: 删除本地镜像（不删除远程镜像）


# ============================================================
# 查看和管理
# ============================================================

# 查看运行中的服务
docker-compose ps

# 查看日志
docker-compose logs -f          # 实时日志
docker-compose logs -f web      # 只看web服务日志
docker-compose logs --tail=100  # 只看最后100行
docker-compose logs -t          # 添加时间戳

# 进入容器
docker-compose exec web bash    # exec = docker exec
docker-compose exec web sh

# 在服务中执行命令
docker-compose run web ls -la   # 临时运行命令


# ============================================================
# 扩展和缩放
# ============================================================

# 扩展服务实例数
docker-compose up -d --scale web=3 --scale api=2

# 或使用 scale 命令（新版本已废弃，用up代替）
docker-compose scale web=3


# ============================================================
# 配置验证
# ============================================================

# 验证compose文件
docker-compose config

# 验证并显示配置
docker-compose config --services  # 列出所有服务
docker-compose config --volumes   # 列出所有卷


# ============================================================
# 构建
# ============================================================

# 构建镜像
docker-compose build
docker-compose build --no-cache  # 不使用缓存

# 构建并启动
docker-compose up --build


# ============================================================
# 多文件组合
# ============================================================

# 使用基础文件 + 环境特定文件
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 常用组合:
# ├── 开发: docker-compose.yml + docker-compose.dev.yml
# ├── 测试: docker-compose.yml + docker-compose.test.yml
# └── 生产: docker-compose.yml + docker-compose.prod.yml