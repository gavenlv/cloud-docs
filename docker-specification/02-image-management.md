# Docker镜像管理深度解析

## 2.1 Docker镜像原理

### 2.1.1 镜像分层机制

```
Docker镜像分层原理：

┌─────────────────────────────────────────────────────────────────┐
│  镜像分层结构                                            │
└─────────────────────────────────────────────────────────────────┘

分层存储机制：

1. 只读层（镜像层）
   ├── 所有镜像层都是只读的
   ├── 多个镜像可以共享基础层
   ├── 节省存储空间
   └── 提高构建效率

2. 可写层（容器层）
   ├── 容器启动时创建可写层
   ├── 所有修改都在可写层
   ├── 不影响镜像层
   └── 容器删除时可写层删除

3. Copy-on-Write (CoW)
   ├── 读取时从只读层读取
   ├── 修改时复制到可写层
   ├── 只存储修改的部分
   └── 节省存储空间

分层优势：

1. 存储效率
   ├── 共享基础层
   ├── 减少重复存储
   ├── 节省磁盘空间
   └── 加快镜像分发

2. 构建效率
   ├── 缓存未修改的层
   ├── 只重建修改的层
   ├── 加快构建速度
   └── 减少网络传输

3. 版本管理
   ├── 每层都有唯一ID
   ├── 支持版本回滚
   ├── 支持增量更新
   └── 支持历史追溯
```

### 2.1.2 镜像存储格式

```
Docker镜像存储格式：

┌─────────────────────────────────────────────────────────────────┐
│  OCI镜像格式                                             │
└─────────────────────────────────────────────────────────────────┘

OCI镜像规范：

1. Manifest（清单）
   ├── 镜像元数据
   ├── 层引用
   ├── 配置引用
   └── 签名信息

2. Configuration（配置）
   ├── 环境变量
   ├── 工作目录
   ├── 用户信息
   ├── 入口点
   └── 挂载点

3. Layers（层）
   ├── 文件系统层
   ├── 压缩格式
   ├── 校验和
   └── 下载地址

存储驱动类型：

1. Overlay2（推荐）
   ├── 性能最好
   ├── 支持inode限制
   ├── 支持page cache
   └── 适合生产环境

2. Btrfs
   ├── 支持快照
   ├── 支持子卷
   ├── 支持压缩
   └── 需要特殊文件系统

3. ZFS
   ├── 支持快照
   ├── 支持压缩
   ├── 支持加密
   └── 需要特殊文件系统

4. VFS（Virtual File System）
   ├── 简单可靠
   ├── 不需要特殊文件系统
   ├── 性能较差
   └── 适合开发环境
```

---

## 2.2 Dockerfile详解

### 2.2.1 Dockerfile语法

```
Dockerfile指令：

┌─────────────────────────────────────────────────────────────────┐
│  Dockerfile指令列表                                        │
└─────────────────────────────────────────────────────────────────┘

基础指令：

1. FROM
   ├── 指定基础镜像
   ├── 必须是第一条指令
   ├── 支持多阶段构建
   └── 示例：FROM ubuntu:22.04

2. RUN
   ├── 执行构建命令
   ├── 每条RUN创建新层
   ├── 支持shell格式
   └── 示例：RUN apt-get update && apt-get install -y nginx

3. CMD
   ├── 指定容器启动命令
   ├── 只能有一个CMD
   ├── 可以被docker run覆盖
   └── 示例：CMD ["nginx", "-g", "daemon off;"]

4. ENTRYPOINT
   ├── 指定容器入口点
   ├── 不会被docker run覆盖
   ├── 可以和CMD配合使用
   └── 示例：ENTRYPOINT ["/docker-entrypoint.sh"]

5. COPY
   ├── 复制文件到镜像
   ├── 从构建上下文复制
   ├── 支持通配符
   └── 示例：COPY . /app

6. ADD
   ├── 复制文件到镜像
   ├── 支持URL下载
   ├── 支持自动解压
   └── 示例：ADD https://example.com/file.tar.gz /tmp

7. ENV
   ├── 设置环境变量
   ├── 影响后续指令
   ├── 影响容器运行
   └── 示例：ENV APP_ENV=production

8. ARG
   ├── 定义构建参数
   ├── 只在构建时有效
   ├── 可以通过--build-arg传递
   └── 示例：ARG VERSION=1.0

9. EXPOSE
   ├── 声明监听端口
   ├── 不实际发布端口
   ├── 只是文档说明
   └── 示例：EXPOSE 80 443

10. VOLUME
    ├── 声明挂载点
    ├── 创建匿名卷
    ├── 防止数据丢失
    └── 示例：VOLUME /var/lib/mysql

11. USER
    ├── 指定运行用户
    ├── 影响后续指令
    ├── 影响容器运行
    └── 示例：USER nginx

12. WORKDIR
    ├── 设置工作目录
    ├── 影响后续指令
    ├── 影响容器运行
    └── 示例：WORKDIR /app

13. LABEL
    ├── 添加元数据
    ├── 支持键值对
    ├── 用于镜像管理
    └── 示例：LABEL version="1.0" description="Web application"

14. HEALTHCHECK
    ├── 定义健康检查
    ├── 定期检查容器状态
    ├── 支持多种检查方式
    └── 示例：HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1

15. ONBUILD
    ├── 触发指令
    ├── 在子镜像构建时执行
    ├── 用于基础镜像
    └── 示例：ONBUILD COPY . /app

16. STOPSIGNAL
    ├── 指定停止信号
    ├── 影响容器停止行为
    ├── 支持信号名称和数字
    └── 示例：STOPSIGNAL SIGTERM

17. SHELL
    ├── 指定shell格式
    ├── 影响后续指令
    ├── 支持多种shell
    └── 示例：SHELL ["/bin/bash", "-c"]

18. MAINTAINER（已废弃）
    ├── 指定维护者信息
    ├── 已被LABEL替代
    ├── 不推荐使用
    └── 示例：MAINTAINER John Doe <john@example.com>
```

### 2.2.2 多阶段构建

```
多阶段构建原理：

┌─────────────────────────────────────────────────────────────────┐
│  多阶段构建流程                                          │
└─────────────────────────────────────────────────────────────────┘

传统构建问题：
├── 镜像体积大（包含构建工具）
├── 安全性低（包含源代码）
├── 构建时间长（需要下载依赖）
└── 维护困难（包含不必要文件）

多阶段构建优势：
├── 镜像体积小（只包含运行时）
├── 安全性高（不包含源代码）
├── 构建时间短（复用构建缓存）
└── 维护简单（只包含必要文件）

多阶段构建示例：

# 第一阶段：构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# 第二阶段：运行时阶段
FROM nginx:alpine

# 从构建阶段复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 只包含运行时依赖
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

优势分析：

1. 镜像体积
   ├── 传统构建：500MB+
   ├── 多阶段构建：50MB
   ├── 减少90%+
   └── 加快部署速度

2. 安全性
   ├── 传统构建：包含源代码
   ├── 多阶段构建：不包含源代码
   ├── 减少攻击面
   └── 提高安全性

3. 构建效率
   ├── 传统构建：每次都重新构建
   ├── 多阶段构建：复用构建缓存
   ├── 减少50%+构建时间
   └── 节省CI/CD资源
```

### 2.2.3 镜像优化技巧

```
镜像优化策略：

┌─────────────────────────────────────────────────────────────────┐
│  镜像优化方法                                            │
└─────────────────────────────────────────────────────────────────┘

1. 使用Alpine基础镜像
   ├── 体积小（5MB vs 200MB）
   ├── 安全性高（攻击面小）
   ├── 兼容性好（glibc兼容）
   └── 示例：FROM alpine:3.18

2. 合并RUN指令
   ├── 减少镜像层数
   ├── 减少镜像体积
   ├── 提高构建效率
   └── 示例：RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

3. 使用.dockerignore
   ├── 排除不需要的文件
   ├── 减少构建上下文
   ├── 提高构建速度
   └── 示例：.dockerignore文件

4. 多阶段构建
   ├── 分离构建和运行时
   ├── 只包含必要文件
   ├── 减少镜像体积
   └── 示例：见上一节

5. 清理缓存
   ├── 删除包管理器缓存
   ├── 删除临时文件
   ├── 减少镜像体积
   └── 示例：RUN apt-get clean && rm -rf /var/lib/apt/lists/*

6. 使用多阶段构建
   ├── 分离构建和运行时
   ├── 只包含必要文件
   ├── 减少镜像体积
   └── 示例：见上一节

7. 使用最小基础镜像
   ├── scratch：空镜像
   ├── distroless：无包管理器
   ├── 只包含运行时
   └── 示例：FROM scratch

8. 优化层顺序
   ├── 不常变化的层放前面
   ├── 常变化的层放后面
   ├── 提高缓存命中率
   └── 示例：COPY package*.json ./ 在 COPY . ./ 之前
```

---

## 2.3 Docker镜像管理实战

### 2.3.1 构建自定义镜像

**场景：构建Python Web应用镜像**

```dockerfile
# Dockerfile
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV APP_ENV=production

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# 运行应用
CMD ["python", "app.py"]
```

**requirements.txt：**

```text
flask==2.3.3
gunicorn==20.1.0
```

**app.py：**

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({"message": "Hello, World!"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

**构建镜像：**

```bash
# 构建镜像
docker build -t my-python-app:1.0 .

# 查看镜像
docker images

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    1.0       abc123def456   5 minutes ago   125MB

# 查看镜像详细信息
docker inspect my-python-app:1.0

# 输出（部分）：
# [
#     {
#         "Id": "sha256:abc123def456789012345678901234567890123456789012",
#         "RepoTags": [
#             "my-python-app:1.0"
#         ],
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Size": 125000000,
#         "VirtualSize": 125000000,
#         "Config": {
#             "Env": [
#                 "PYTHONUNBUFFERED=1",
#                 "APP_ENV=production",
#                 "PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
#             ],
#             "ExposedPorts": {
#                 "8000/tcp": {}
#             },
#             "WorkingDir": "/app"
#         }
#     }
# ]
```

### 2.3.2 多阶段构建实战

**场景：构建Node.js应用镜像**

```dockerfile
# Dockerfile
# 第一阶段：构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 第二阶段：运行时阶段
FROM nginx:alpine

# 从构建阶段复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# 运行nginx
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf：**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        listen 80;
        server_name _;

        root /usr/share/nginx/html;
        index index.html index.htm;

        location / {
            try_files $uri $uri/ /index.html;
        }

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

**构建镜像：**

```bash
# 构建镜像
docker build -t my-node-app:1.0 .

# 查看镜像
docker images

# 输出：
# REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
# my-node-app     1.0       abc123def456   5 minutes ago   25MB

# 查看镜像历史
docker history my-node-app:1.0

# 输出：
# IMAGE          CREATED         CREATED BY                                      SIZE
# abc123def456   5 minutes ago   /bin/sh -c #(nop) ADD file:abc123def456 in /    0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) CMD [nginx -g daemon off;] 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) EXPOSE map[80/tcp:80/tcp] 0B
# abc123def456   5 minutes ago   |1 COPY /etc/nginx/nginx.conf /etc/nginx/nginx.conf  1.2kB
# abc123def456   5 minutes ago   |2 COPY /app/dist /usr/share/nginx/html  15MB
# abc123def456   5 minutes ago   /bin/sh -c #(nop) LABEL maintainer=... 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) HEALTHCHECK &{...} 0B
# abc123def456   5 minutes ago   /bin/sh -c #(nop) FROM node:18-alpine  120MB
```

### 2.3.3 镜像优化实战

**场景：优化Python应用镜像**

```dockerfile
# 优化前：传统构建
FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：900MB
```

```dockerfile
# 优化后：多阶段构建 + Alpine
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --user=appuser -r requirements.txt

COPY . .
RUN python -m pip install --user .

FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /root/.local /root/.local
COPY --from=builder /app /app

ENV PATH=/root/.local/bin:$PATH

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]

# 镜像大小：125MB
```

**优化效果对比：**

```bash
# 查看优化前的镜像
docker images my-python-app:old

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    old       abc123def456   10 minutes ago  900MB

# 查看优化后的镜像
docker images my-python-app:optimized

# 输出：
# REPOSITORY        TAG       IMAGE ID       CREATED         SIZE
# my-python-app    optimized abc123def456   5 minutes ago   125MB

# 优化效果：
# - 减少86%的镜像体积
# - 减少90%的构建时间
# - 减少95%的下载时间
```

---

## 2.4 镜像版本管理

### 2.4.1 镜像标签策略

```
镜像标签最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  镜像标签策略                                            │
└─────────────────────────────────────────────────────────────────┘

标签类型：

1. 版本标签
   ├── 主版本：1.0
   ├── 次版本：1.0.1
   ├── 修订版本：1.0.1.2
   └── 示例：myapp:1.0.1.2

2. 环境标签
   ├── 开发环境：dev
   ├── 测试环境：test
   ├── 预发布环境：staging
   └── 生产环境：prod

3. 构建标签
   ├── Git提交：abc1234
   ├── 构建编号：build-123
   ├── 时间戳：20240115-103000
   └── 示例：myapp:abc1234

4. 功能标签
   ├── 最新版本：latest
   ├── 稳定版本：stable
   ├── 开发版本：dev
   └── 示例：myapp:latest

标签策略：

1. 语义化版本
   ├── 主版本：不兼容的API修改
   ├── 次版本：向下兼容的功能性新增
   ├── 修订版本：向下兼容的问题修正
   └── 示例：1.2.3

2. Git标签
   ├── 使用Git提交哈希
   ├── 使用Git标签
   ├── 使用Git分支
   └── 示例：myapp:abc1234

3. CI/CD标签
   ├── 使用构建编号
   ├── 使用时间戳
   ├── 使用环境变量
   └── 示例：myapp:build-123
```

### 2.4.2 镜像推送和拉取

```bash
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
```

---

## 本章小结

- Docker镜像使用分层存储机制
- Union File System提供Copy-on-Write
- Dockerfile定义镜像构建过程
- 多阶段构建可以大幅减小镜像体积
- 镜像优化可以减少90%+的体积
- 镜像标签支持版本管理
- 镜像推送和拉取支持分布式部署

---

**下一章：Docker容器管理**
