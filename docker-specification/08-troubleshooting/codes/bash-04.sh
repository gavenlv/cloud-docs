# 错误1：语法错误
# 错误信息：
# [+] Building 0.0s (2/2)
# ERROR [1/2] FROM docker.io/library/python:3.11
# ----
# > [1/2] FROM docker.io/library/python:3.11
# ----
# failed to solve: rpc error: code = Unknown desc = failed to solve with frontend dockerfile.v0: failed to create LLB definition: dockerfile parse error line 3: unknown instruction: FORM"

# 解决方案：
# 1. 检查Dockerfile语法
cat Dockerfile

# 2. 修正语法错误
# FORM python:3.11
# 改为
# FROM python:3.11

# 3. 使用Dockerfile linter
docker run --rm -i hadolint/hadolint < Dockerfile

# 4. 使用docker build --check
docker build --check -f Dockerfile .

# 错误2：基础镜像不存在
# 错误信息：
# [+] Building 0.0s (2/2)
# ERROR [1/2] FROM docker.io/library/python:3.11
# ----
# > [1/2] FROM docker.io/library/python:3.11
# ----
# failed to solve: pull access denied for python, repository does not exist or may require 'docker login': denied: requested access to the resource is denied

# 解决方案：
# 1. 检查基础镜像是否存在
docker images | grep python

# 2. 拉取基础镜像
docker pull python:3.11

# 3. 使用正确的镜像名称和标签
FROM python:3.11-slim

# 4. 登录Docker Hub
docker login

# 5. 使用私有镜像
FROM my-registry.com/python:3.11

# 错误3：依赖包下载失败
# 错误信息：
# ERROR [3/5] RUN pip install -r requirements.txt:
# ----
# > [3/5] RUN pip install -r requirements.txt:
# ----
# #8 0.596 Collecting flask==2.3.3
# #8 0.735   Downloading flask-2.3.3-py3-none-any.whl (96 kB)
# #8 1.452 ERROR: Could not find a version that satisfies the requirement flask==2.3.3 (from versions: none)
# #8 1.452 ERROR: No matching distribution found for flask==2.3.3

# 解决方案：
# 1. 检查requirements.txt
cat requirements.txt

# 2. 使用正确的包版本
flask==2.3.2

# 3. 使用国内镜像源
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

# 4. 使用--no-cache-dir选项
RUN pip install --no-cache-dir -r requirements.txt

# 5. 检查网络连接
docker run --rm python:3.11 pip install flask

# 错误4：网络问题
# 错误信息：
# ERROR [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# > [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# #8 0.596 Get:1 http://deb.debian.org/debian bullseye InRelease [116 kB]
# #8 0.735 Get:2 http://deb.debian.org/debian bullseye/main amd64 Packages [8183 kB]
# #8 30.452 Err:2 http://deb.debian.org/debian bullseye/main amd64 Packages
# #8 30.452   Connection failed [IP: 151.101.1.148 80]
# #8 30.452 Reading package lists...
# #8 30.452 W: Failed to fetch http://deb.debian.org/debian/dists/bullseye/InRelease  Connection failed [IP: 151.101.1.148 80]
# #8 30.452 W: Some index files failed to download. They have been ignored, or old ones used instead.

# 解决方案：
# 1. 使用国内镜像源
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# 2. 使用--network host选项
docker build --network host -t myapp .

# 3. 配置代理
docker build --build-arg HTTP_PROXY=http://proxy.example.com:8080 -t myapp .

# 4. 检查网络连接
docker run --rm python:3.11 ping -c 3 deb.debian.org

# 5. 使用--no-cache选项
docker build --no-cache -t myapp .

# 错误5：磁盘空间不足
# 错误信息：
# ERROR [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# > [3/5] RUN apt-get update && apt-get install -y nginx:
# ----
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache
# #8 30.452 E: Write error - write (28: No space left on device)
# #8 30.452 E: IO Error saving source cache

# 解决方案：
# 1. 查看磁盘使用情况
df -h

# 2. 清理未使用的镜像
docker image prune -a

# 3. 清理构建缓存
docker builder prune

# 4. 清理所有未使用的资源
docker system prune -a --volumes

# 5. 增加磁盘空间
# （需要系统管理员操作）

# 6. 使用--no-cache选项
docker build --no-cache -t myapp .

# 错误6：权限问题
# 错误信息：
# ERROR [3/5] COPY . /app:
# ----
# > [3/5] COPY . /app:
# ----
# #8 0.596 ERROR: "/app" is not a directory

# 解决方案：
# 1. 检查Dockerfile
cat Dockerfile | grep COPY

# 2. 检查源路径是否存在
ls -la .

# 3. 创建目标目录
RUN mkdir -p /app

# 4. 使用正确的路径
COPY . /app/

# 5. 检查文件权限
ls -la /path/to/file

# 6. 修改文件权限
chmod 755 /path/to/file