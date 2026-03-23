# 错误1: Maven构建失败
# 原因: 依赖下载失败/编译错误

# 解决方案:
# 1. 使用本地仓库
# 2. 清理并重试
sh 'mvn clean package'

# 3. 检查Maven设置
cat ~/.m2/settings.xml

# 错误2: Git检出失败
# 原因: 仓库不存在/权限不足/分支不存在

# 解决方案:
# 1. 检查仓库URL
git ls-remote https://github.com/example/repo.git

# 2. 检查凭证
# Manage Jenkins → Credentials

# 3. 检查分支名称
git branch -a

# 错误3: Docker构建失败
# 原因: Dockerfile错误/上下文问题

# 解决方案:
# 1. 检查Dockerfile语法
# 2. 检查.dockerignore
# 3. 使用构建日志
docker build -t myapp . --progress=plain