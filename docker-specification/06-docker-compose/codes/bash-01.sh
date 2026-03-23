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