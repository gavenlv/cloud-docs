# Docker Compose深度解析

## 6.1 Docker Compose原理

### 6.1.1 Compose架构

```
Docker Compose架构：

┌─────────────────────────────────────────────────────────────────┐
│  Docker Compose架构图                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  用户层                                                  │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker Compose CLI (docker-compose命令)              │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ docker-compose.yml (配置文件)                        │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Docker Compose层                                         │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker Compose Engine (docker-compose引擎)            │    │
│  │  ├── 配置解析                                        │    │
│  │  ├── 依赖管理                                        │    │
│  │  ├── 服务编排                                        │    │
│  │  └── 状态管理                                        │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  Docker Engine层                                          │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Docker Daemon (dockerd)                         │    │
│  │  ├── 镜像管理                                  │    │
│  │  ├── 容器管理                                  │    │
│  │  ├── 网络管理                                  │    │
│  │  └── 存储管理                                  │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

Compose核心概念：

1. Service（服务）
   ├── 定义容器配置
   ├── 支持扩缩容
   ├── 支持依赖关系
   └── 支持健康检查

2. Network（网络）
   ├── 定义网络配置
   ├── 支持多种驱动
   ├── 支持网络隔离
   └── 支持服务发现

3. Volume（卷）
   ├── 定义存储配置
   ├── 支持多种类型
   ├── 支持数据持久化
   └── 支持数据共享

4. Config（配置）
   ├── 定义配置文件
   ├── 支持环境变量
   ├── 支持参数化
   └── 支持配置管理
```

### 6.1.2 Compose工作流程

```
Compose工作流程：

┌─────────────────────────────────────────────────────────────────┐
│  Compose工作流程图                                        │
└─────────────────────────────────────────────────────────────────┘

1. 解析配置文件
   ├── 读取docker-compose.yml
   ├── 解析服务配置
   ├── 解析网络配置
   ├── 解析卷配置
   └── 验证配置有效性

2. 创建网络
   ├── 创建自定义网络
   ├── 配置网络驱动
   ├── 配置网络参数
   └── 连接服务到网络

3. 创建卷
   ├── 创建数据卷
   ├── 配置卷驱动
   ├── 配置卷参数
   └── 挂载卷到服务

4. 创建服务
   ├── 拉取镜像
   ├── 创建容器
   ├── 配置网络
   ├── 配置卷
   ├── 配置环境变量
   ├── 配置资源限制
   └── 启动服务

5. 管理服务
   ├── 监控服务状态
   ├── 处理服务依赖
   ├── 重启失败服务
   └── 更新服务配置
```

---

## 6.2 Compose文件语法

### 6.2.1 基本语法

```yaml
version: "3.8"

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - frontend

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

volumes:
  db-data:
    driver: local
```

### 6.2.2 服务配置

```yaml
version: "3.8"

services:
  web:
    # 镜像配置
    image: nginx:latest
    build:
      context: ./web
      dockerfile: Dockerfile
      args:
        BUILD_ENV: production

    # 端口配置
    ports:
      - "80:80"
      - "443:443"
    expose:
      - "80"
      - "443"

    # 环境变量
    environment:
      - APP_ENV=production
      - DEBUG=false
    env_file:
      - ./web.env

    # 命令配置
    command: ["nginx", "-g", "daemon off;"]
    entrypoint: ["/docker-entrypoint.sh"]

    # 工作目录
    working_dir: /app

    # 用户配置
    user: "1000:1000"

    # 网络配置
    networks:
      - frontend
      - backend
    network_mode: bridge
    dns:
      - 8.8.8.8
      - 8.8.4.4
    dns_search:
      - example.com

    # 存储配置
    volumes:
      - ./html:/usr/share/nginx/html
      - web-logs:/var/log/nginx
    tmpfs:
      - /tmp:size=100m
    volume_driver: local

    # 资源限制
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    cpu_shares: 512
    mem_limit: 512m
    mem_reservation: 256m

    # 重启策略
    restart: always

    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

    # 依赖关系
    depends_on:
      - db
      - redis

    # 标签
    labels:
      - "com.example.description=Web server"
      - "com.example.department=IT"

    # 日志配置
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

    # 安全配置
    security_opt:
      - no-new-privileges:true
    cap_add:
      - NET_ADMIN
    cap_drop:
      - ALL
    privileged: false
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m

    # PID模式
    pid: "host"

    # IPC模式
    ipc: "host"

    # 其他配置
    stop_grace_period: 10s
    stop_signal: SIGTERM
    stdin_open: true
    tty: true
```

### 6.2.3 网络配置

```yaml
version: "3.8"

networks:
  frontend:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: br-frontend
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
    attachable: true
    internal: false
    labels:
      - "com.example.description=Frontend network"

  backend:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
    internal: true
    labels:
      - "com.example.description=Backend network"

  external-network:
    external: true
    name: my-external-network
```

### 6.2.4 卷配置

```yaml
version: "3.8"

volumes:
  db-data:
    driver: local
    driver_opts:
      type: none
      device: /data/mysql
      o: bind
    labels:
      - "com.example.description=Database data"

  web-logs:
    driver: local
    driver_opts:
      type: tmpfs
      device: tmpfs
      o: size=100m,uid=1000
    labels:
      - "com.example.description=Web logs"

  cache-data:
    driver: local
    labels:
      - "com.example.description=Cache data"

  external-volume:
    external: true
    name: my-external-volume
```

---

## 6.3 Compose实战

### 6.3.1 Web应用部署

**场景：部署一个包含Nginx、Python应用、MySQL、Redis的完整Web应用**

```yaml
version: "3.8"

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - web-static:/usr/share/nginx/html
    depends_on:
      - web
    networks:
      - frontend
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  web:
    build:
      context: ./web
      dockerfile: Dockerfile
      args:
        BUILD_ENV: production
    environment:
      - APP_ENV=production
      - DATABASE_URL=mysql://root:example@db:3306/mydb
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - web-static:/app/static
      - web-logs:/app/logs
    depends_on:
      - db
      - redis
    networks:
      - frontend
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=example
      - MYSQL_DATABASE=mydb
      - MYSQL_USER=myuser
      - MYSQL_PASSWORD=mypassword
    volumes:
      - db-data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d:ro
    networks:
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  db-data:
    driver: local
  redis-data:
    driver: local
  web-static:
    driver: local
  web-logs:
    driver: local
```

**部署步骤：**

```bash
# 创建项目目录
mkdir web-app && cd web-app

# 创建docker-compose.yml文件
cat > docker-compose.yml << 'EOF'
version: "3.8"

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - web-static:/usr/share/nginx/html
    depends_on:
      - web
    networks:
      - frontend
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  web:
    build:
      context: ./web
      dockerfile: Dockerfile
      args:
        BUILD_ENV: production
    environment:
      - APP_ENV=production
      - DATABASE_URL=mysql://root:example@db:3306/mydb
      - REDIS_URL=redis://redis:6379/0
    volumes:
      - web-static:/app/static
      - web-logs:/app/logs
    depends_on:
      - db
      - redis
    networks:
      - frontend
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=example
      - MYSQL_DATABASE=mydb
      - MYSQL_USER=myuser
      - MYSQL_PASSWORD=mypassword
    volumes:
      - db-data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d:ro
    networks:
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  db-data:
    driver: local
  redis-data:
    driver: local
  web-static:
    driver: local
  web-logs:
    driver: local
EOF

# 创建Nginx配置
mkdir -p nginx
cat > nginx/nginx.conf << 'EOF'
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

    upstream web {
        server web:8000;
    }

    server {
        listen 80;
        server_name _;

        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            proxy_pass http://web;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            alias /usr/share/nginx/html/;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# 创建Web应用
mkdir -p web
cat > web/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /app/static /app/logs

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["python", "app.py"]
EOF

cat > web/requirements.txt << 'EOF'
flask==2.3.3
gunicorn==20.1.0
mysql-connector-python==8.0.33
redis==4.6.0
EOF

cat > web/app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({"message": "Hello, World!"})

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

# 创建MySQL初始化脚本
mkdir -p mysql/init
cat > mysql/init/init.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS mydb;
USE mydb;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com');
EOF

# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 输出：
# NAME            COMMAND                  SERVICE   STATUS         PORTS
# web-app-db-1    "docker-entrypoint.s…"   db        Up 10 seconds  3306/tcp
# web-app-nginx-1 "/docker-entrypoint.…"   nginx     Up 10 seconds  0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
# web-app-redis-1 "docker-entrypoint.s…"   redis     Up 10 seconds  6379/tcp
# web-app-web-1   "python app.py"          web       Up 10 seconds  8000/tcp

# 查看服务日志
docker-compose logs -f

# 访问应用
curl http://localhost

# 输出：
# {"message":"Hello, World!"}

# 停止服务
docker-compose down

# 停止服务并删除卷
docker-compose down -v
```

### 6.3.2 微服务部署

**场景：部署一个包含多个微服务的应用**

```yaml
version: "3.8"

services:
  api-gateway:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./api-gateway/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - user-service
      - product-service
      - order-service
    networks:
      - frontend
    restart: always

  user-service:
    build:
      context: ./user-service
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=mysql://root:example@user-db:3306/userdb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - user-db
      - redis
    networks:
      - backend
    restart: always

  product-service:
    build:
      context: ./product-service
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=mysql://root:example@product-db:3306/productdb
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - product-db
      - redis
    networks:
      - backend
    restart: always

  order-service:
    build:
      context: ./order-service
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=mysql://root:example@order-db:3306/orderdb
      - REDIS_URL=redis://redis:6379/0
      - USER_SERVICE_URL=http://user-service:8000
      - PRODUCT_SERVICE_URL=http://product-service:8000
    depends_on:
      - order-db
      - redis
      - user-service
      - product-service
    networks:
      - backend
    restart: always

  user-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=example
      - MYSQL_DATABASE=userdb
    volumes:
      - user-db-data:/var/lib/mysql
    networks:
      - backend
    restart: always

  product-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=example
      - MYSQL_DATABASE=productdb
    volumes:
      - product-db-data:/var/lib/mysql
    networks:
      - backend
    restart: always

  order-db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=example
      - MYSQL_DATABASE=orderdb
    volumes:
      - order-db-data:/var/lib/mysql
    networks:
      - backend
    restart: always

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend
    restart: always

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  user-db-data:
    driver: local
  product-db-data:
    driver: local
  order-db-data:
    driver: local
  redis-data:
    driver: local
```

---

## 6.4 Compose高级特性

### 6.4.1 环境变量

```yaml
version: "3.8"

services:
  web:
    image: nginx:latest
    ports:
      - "${WEB_PORT:-80}:80"
    environment:
      - APP_ENV=${APP_ENV:-production}
      - DEBUG=${DEBUG:-false}
    env_file:
      - .env
      - .env.${APP_ENV:-production}
    networks:
      - frontend

networks:
  frontend:
    driver: bridge
```

**.env文件：**

```env
APP_ENV=production
DEBUG=false
WEB_PORT=80
```

**.env.production文件：**

```env
APP_ENV=production
DEBUG=false
WEB_PORT=80
```

**.env.development文件：**

```env
APP_ENV=development
DEBUG=true
WEB_PORT=8080
```

### 6.4.2 扩展字段

```yaml
version: "3.8"

x-common-variables: &common-variables
  APP_ENV: production
  DEBUG: false

x-common-volumes: &common-volumes
  - ./logs:/app/logs

services:
  web:
    image: nginx:latest
    environment:
      <<: *common-variables
      WEB_PORT: 80
    volumes:
      <<: *common-volumes
      - ./html:/usr/share/nginx/html
    networks:
      - frontend

  api:
    build: ./api
    environment:
      <<: *common-variables
      API_PORT: 8000
    volumes:
      <<: *common-volumes
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### 6.4.3 多文件配置

**docker-compose.yml：**

```yaml
version: "3.8"

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    networks:
      - frontend

networks:
  frontend:
    driver: bridge
```

**docker-compose.override.yml：**

```yaml
version: "3.8"

services:
  web:
    volumes:
      - ./html:/usr/share/nginx/html
    environment:
      - DEBUG=true
```

**使用：**

```bash
# 开发环境（使用override文件）
docker-compose up -d

# 生产环境（不使用override文件）
docker-compose -f docker-compose.yml up -d
```

---

## 本章小结

- Docker Compose用于定义和运行多容器应用
- Compose文件使用YAML格式定义服务、网络、卷
- 服务配置包括镜像、端口、环境变量、卷、网络等
- Compose支持依赖关系、健康检查、资源限制等高级特性
- Compose支持环境变量、扩展字段、多文件配置等
- Compose可以快速部署复杂的应用架构

---

**下一章：Docker最佳实践**
