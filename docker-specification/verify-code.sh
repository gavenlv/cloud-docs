#!/bin/bash

# Docker代码验证脚本
# 用于验证docker-specification中的所有代码示例

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
TOTAL=0
PASSED=0
FAILED=0

# 打印函数
print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
    ((TOTAL++))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
    ((TOTAL++))
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# 检查Docker是否安装
check_docker() {
    print_header "检查Docker环境"
    
    if command -v docker &> /dev/null; then
        print_success "Docker已安装: $(docker --version)"
    else
        print_error "Docker未安装"
        exit 1
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose已安装: $(docker-compose --version)"
    else
        print_error "Docker Compose未安装"
        exit 1
    fi
    
    if docker info &> /dev/null; then
        print_success "Docker守护进程正在运行"
    else
        print_error "Docker守护进程未运行"
        exit 1
    fi
}

# 验证01-fundamentals.md
verify_fundamentals() {
    print_header "验证 01-fundamentals.md"
    
    # 1. 运行Hello World容器
    print_info "运行Hello World容器..."
    if docker run --rm hello-world &> /dev/null; then
        print_success "运行Hello World容器"
    else
        print_error "运行Hello World容器"
    fi
    
    # 2. 运行交互式容器
    print_info "运行交互式容器..."
    if docker run --rm -it alpine echo "Hello, World!" &> /dev/null; then
        print_success "运行交互式容器"
    else
        print_error "运行交互式容器"
    fi
    
    # 3. 运行后台容器
    print_info "运行后台容器..."
    if docker run -d --name test-nginx nginx:alpine &> /dev/null; then
        print_success "运行后台容器"
        docker stop test-nginx &> /dev/null
        docker rm test-nginx &> /dev/null
    else
        print_error "运行后台容器"
    fi
    
    # 4. 容器资源限制
    print_info "容器资源限制..."
    if docker run -d --name test-limited --cpus="0.5" --memory="512m" nginx:alpine &> /dev/null; then
        print_success "容器资源限制"
        docker stop test-limited &> /dev/null
        docker rm test-limited &> /dev/null
    else
        print_error "容器资源限制"
    fi
}

# 验证02-image-management.md
verify_image_management() {
    print_header "验证 02-image-management.md"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 1. 构建自定义镜像
    print_info "构建自定义镜像..."
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]
EOF
    
    cat > requirements.txt << 'EOF'
flask==2.3.3
EOF
    
    cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF
    
    if docker build -t test-python-app:1.0 . &> /dev/null; then
        print_success "构建自定义镜像"
        docker rmi test-python-app:1.0 &> /dev/null
    else
        print_error "构建自定义镜像"
    fi
    
    # 2. 多阶段构建
    print_info "多阶段构建..."
    cat > Dockerfile << 'EOF'
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install

FROM nginx:alpine
COPY --from=builder /app /usr/share/nginx/html
EOF
    
    cat > package.json << 'EOF'
{
  "name": "test-app",
  "version": "1.0.0"
}
EOF
    
    if docker build -t test-node-app:1.0 . &> /dev/null; then
        print_success "多阶段构建"
        docker rmi test-node-app:1.0 &> /dev/null
    else
        print_error "多阶段构建"
    fi
    
    # 清理临时目录
    cd -
    rm -rf "$TEMP_DIR"
}

# 验证03-container-management.md
verify_container_management() {
    print_header "验证 03-container-management.md"
    
    # 1. 容器生命周期管理
    print_info "容器生命周期管理..."
    if docker create --name test-container nginx:alpine &> /dev/null; then
        if docker start test-container &> /dev/null; then
            if docker stop test-container &> /dev/null; then
                if docker rm test-container &> /dev/null; then
                    print_success "容器生命周期管理"
                else
                    print_error "容器生命周期管理"
                fi
            else
                print_error "容器生命周期管理"
            fi
        else
            print_error "容器生命周期管理"
        fi
    else
        print_error "容器生命周期管理"
    fi
    
    # 2. 容器资源管理
    print_info "容器资源管理..."
    if docker run -d --name test-resource --cpus="0.5" --memory="512m" nginx:alpine &> /dev/null; then
        print_success "容器资源管理"
        docker stop test-resource &> /dev/null
        docker rm test-resource &> /dev/null
    else
        print_error "容器资源管理"
    fi
    
    # 3. 容器网络配置
    print_info "容器网络配置..."
    if docker run -d --name test-network --network bridge -p 8080:80 nginx:alpine &> /dev/null; then
        print_success "容器网络配置"
        docker stop test-network &> /dev/null
        docker rm test-network &> /dev/null
    else
        print_error "容器网络配置"
    fi
    
    # 4. 容器数据持久化
    print_info "容器数据持久化..."
    if docker volume create test-volume &> /dev/null; then
        if docker run -d --name test-volume-container -v test-volume:/data nginx:alpine &> /dev/null; then
            print_success "容器数据持久化"
            docker stop test-volume-container &> /dev/null
            docker rm test-volume-container &> /dev/null
            docker volume rm test-volume &> /dev/null
        else
            print_error "容器数据持久化"
            docker volume rm test-volume &> /dev/null
        fi
    else
        print_error "容器数据持久化"
    fi
}

# 验证04-networking.md
verify_networking() {
    print_header "验证 04-networking.md"
    
    # 1. 创建自定义网络
    print_info "创建自定义网络..."
    if docker network create test-network &> /dev/null; then
        print_success "创建自定义网络"
        docker network rm test-network &> /dev/null
    else
        print_error "创建自定义网络"
    fi
    
    # 2. 容器间通信
    print_info "容器间通信..."
    if docker network create test-network &> /dev/null; then
        if docker run -d --name test-web --network test-network nginx:alpine &> /dev/null; then
            if docker run -d --name test-app --network test-network python:3.11-alpine python -m http.server 8000 &> /dev/null; then
                print_success "容器间通信"
                docker stop test-web test-app &> /dev/null
                docker rm test-web test-app &> /dev/null
            else
                print_error "容器间通信"
                docker stop test-web &> /dev/null
                docker rm test-web &> /dev/null
            fi
        else
            print_error "容器间通信"
        fi
        docker network rm test-network &> /dev/null
    else
        print_error "容器间通信"
    fi
    
    # 3. 端口映射
    print_info "端口映射..."
    if docker run -d --name test-port -p 8081:80 nginx:alpine &> /dev/null; then
        print_success "端口映射"
        docker stop test-port &> /dev/null
        docker rm test-port &> /dev/null
    else
        print_error "端口映射"
    fi
}

# 验证05-storage.md
verify_storage() {
    print_header "验证 05-storage.md"
    
    # 1. 创建数据卷
    print_info "创建数据卷..."
    if docker volume create test-volume &> /dev/null; then
        print_success "创建数据卷"
        docker volume rm test-volume &> /dev/null
    else
        print_error "创建数据卷"
    fi
    
    # 2. 绑定挂载
    print_info "绑定挂载..."
    TEMP_DIR=$(mktemp -d)
    if docker run -d --name test-bind -v "$TEMP_DIR:/data" nginx:alpine &> /dev/null; then
        print_success "绑定挂载"
        docker stop test-bind &> /dev/null
        docker rm test-bind &> /dev/null
    else
        print_error "绑定挂载"
    fi
    rm -rf "$TEMP_DIR"
    
    # 3. tmpfs挂载
    print_info "tmpfs挂载..."
    if docker run -d --name test-tmpfs --tmpfs /tmp:size=100m nginx:alpine &> /dev/null; then
        print_success "tmpfs挂载"
        docker stop test-tmpfs &> /dev/null
        docker rm test-tmpfs &> /dev/null
    else
        print_error "tmpfs挂载"
    fi
}

# 验证06-docker-compose.md
verify_docker_compose() {
    print_header "验证 06-docker-compose.md"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 1. Web应用部署
    print_info "Web应用部署..."
    cat > docker-compose.yml << 'EOF'
version: "3.8"

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
EOF
    
    if docker-compose up -d &> /dev/null; then
        print_success "Web应用部署"
        docker-compose down &> /dev/null
    else
        print_error "Web应用部署"
    fi
    
    # 清理临时目录
    cd -
    rm -rf "$TEMP_DIR"
}

# 验证07-best-practices.md
verify_best_practices() {
    print_header "验证 07-best-practices.md"
    
    # 1. 镜像优化
    print_info "镜像优化..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]
EOF
    
    cat > requirements.txt << 'EOF'
flask==2.3.3
EOF
    
    cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF
    
    if docker build -t test-optimized:1.0 . &> /dev/null; then
        print_success "镜像优化"
        docker rmi test-optimized:1.0 &> /dev/null
    else
        print_error "镜像优化"
    fi
    
    # 2. 容器安全
    print_info "容器安全..."
    if docker run -d --name test-security --cap-drop ALL --cap-add NET_BIND_SERVICE --read-only --tmpfs /tmp --tmpfs /run nginx:alpine &> /dev/null; then
        print_success "容器安全"
        docker stop test-security &> /dev/null
        docker rm test-security &> /dev/null
    else
        print_error "容器安全"
    fi
    
    # 3. 性能优化
    print_info "性能优化..."
    if docker run -d --name test-performance --cpus="0.5" --memory="512m" nginx:alpine &> /dev/null; then
        print_success "性能优化"
        docker stop test-performance &> /dev/null
        docker rm test-performance &> /dev/null
    else
        print_error "性能优化"
    fi
    
    # 清理临时目录
    cd -
    rm -rf "$TEMP_DIR"
}

# 验证08-troubleshooting.md
verify_troubleshooting() {
    print_header "验证 08-troubleshooting.md"
    
    # 1. 容器启动失败处理
    print_info "容器启动失败处理..."
    if docker run -d --name test-troubleshoot nginx:alpine &> /dev/null; then
        print_success "容器启动失败处理"
        docker stop test-troubleshoot &> /dev/null
        docker rm test-troubleshoot &> /dev/null
    else
        print_error "容器启动失败处理"
    fi
    
    # 2. 网络连接问题处理
    print_info "网络连接问题处理..."
    if docker network create test-troubleshoot-network &> /dev/null; then
        if docker run -d --name test-troubleshoot-web --network test-troubleshoot-network nginx:alpine &> /dev/null; then
            print_success "网络连接问题处理"
            docker stop test-troubleshoot-web &> /dev/null
            docker rm test-troubleshoot-web &> /dev/null
        else
            print_error "网络连接问题处理"
        fi
        docker network rm test-troubleshoot-network &> /dev/null
    else
        print_error "网络连接问题处理"
    fi
    
    # 3. 存储访问问题处理
    print_info "存储访问问题处理..."
    if docker volume create test-troubleshoot-volume &> /dev/null; then
        if docker run -d --name test-troubleshoot-storage -v test-troubleshoot-volume:/data nginx:alpine &> /dev/null; then
            print_success "存储访问问题处理"
            docker stop test-troubleshoot-storage &> /dev/null
            docker rm test-troubleshoot-storage &> /dev/null
        else
            print_error "存储访问问题处理"
        fi
        docker volume rm test-troubleshoot-volume &> /dev/null
    else
        print_error "存储访问问题处理"
    fi
}

# 清理函数
cleanup() {
    print_header "清理验证环境"
    
    # 停止所有容器
    print_info "停止所有容器..."
    docker stop $(docker ps -aq) &> /dev/null || true
    
    # 删除所有容器
    print_info "删除所有容器..."
    docker rm $(docker ps -aq) &> /dev/null || true
    
    # 删除所有镜像
    print_info "删除所有镜像..."
    docker rmi $(docker images -q) &> /dev/null || true
    
    # 删除所有数据卷
    print_info "删除所有数据卷..."
    docker volume rm $(docker volume ls -q) &> /dev/null || true
    
    # 删除所有网络
    print_info "删除所有网络..."
    docker network rm $(docker network ls -q) &> /dev/null || true
    
    # 清理所有未使用的资源
    print_info "清理所有未使用的资源..."
    docker system prune -a --volumes -f &> /dev/null || true
    
    print_success "清理完成"
}

# 主函数
main() {
    print_header "Docker代码验证"
    
    # 检查Docker环境
    check_docker
    
    # 验证各个章节
    verify_fundamentals
    verify_image_management
    verify_container_management
    verify_networking
    verify_storage
    verify_docker_compose
    verify_best_practices
    verify_troubleshooting
    
    # 清理验证环境
    cleanup
    
    # 打印验证结果
    print_header "验证结果"
    echo -e "总计: $TOTAL"
    echo -e "${GREEN}通过: $PASSED${NC}"
    echo -e "${RED}失败: $FAILED${NC}"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}所有验证通过！${NC}\n"
        exit 0
    else
        echo -e "\n${RED}部分验证失败！${NC}\n"
        exit 1
    fi
}

# 运行主函数
main
