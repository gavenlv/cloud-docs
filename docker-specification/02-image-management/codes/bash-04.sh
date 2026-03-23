# 推送镜像到Docker Hub
docker push my-python-app:1.0

# 推送所有标签
docker push my-python-app:latest
docker push my-python-app:1.0
docker push my-python-app:1.0.1
docker push my-python-app:1.0.1.2

# 拉取镜像
docker pull my-python-app:1.0

# 拉取所有标签
docker pull my-python-app:latest
docker pull my-python-app:1.0
docker pull my-python-app:1.0.1
docker pull my-python-app:1.0.1.2

# 拉取特定平台
docker pull --platform linux/amd64 my-python-app:1.0
docker pull --platform linux/arm64 my-python-app:1.0

# 查看镜像历史
docker history my-python-app:1.0

# 输出：
# IMAGE          CREATED         CREATED BY                                      SIZE
# abc123def456   5 minutes ago   /bin/sh -c #(nop) ADD file:abc123def456 in /    0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) CMD [python app.py] 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) EXPOSE map[8000/tcp:8000/tcp] 0B
# abc123def456   5 minutes ago   |1 COPY . /app  10MB
# abc123def456   5 minutes ago   /bin/sh -c #(nop) COPY requirements.txt /app  5KB
# abc123def456   5 minutes ago   /bin/sh -c pip install --no-cache-dir -r requirements.txt  100MB
# abc123def456   5 minutes ago   /bin/sh -c #(nop) WORKDIR /app  0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) FROM python:3.11-slim  115MB