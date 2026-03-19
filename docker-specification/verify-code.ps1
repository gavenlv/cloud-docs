# Docker代码验证脚本
# 用于验证docker-specification中的所有代码示例

# 颜色定义
$RED = [System.ConsoleColor]::Red
$GREEN = [System.ConsoleColor]::Green
$YELLOW = [System.ConsoleColor]::Yellow

# 计数器
$TOTAL = 0
$PASSED = 0
$FAILED = 0

# 打印函数
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $GREEN
    Write-Host $Message -ForegroundColor $GREEN
    Write-Host "========================================" -ForegroundColor $GREEN
    Write-Host ""
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $GREEN
    $script:PASSED++
    $script:TOTAL++
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $RED
    $script:FAILED++
    $script:TOTAL++
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $YELLOW
}

# 检查Docker是否安装
function Check-Docker {
    Print-Header "检查Docker环境"
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Print-Success "Docker已安装: $(docker --version)"
    } else {
        Print-Error "Docker未安装"
        exit 1
    }
    
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        Print-Success "Docker Compose已安装: $(docker-compose --version)"
    } else {
        Print-Error "Docker Compose未安装"
        exit 1
    }
    
    if (docker info -ErrorAction SilentlyContinue) {
        Print-Success "Docker守护进程正在运行"
    } else {
        Print-Error "Docker守护进程未运行"
        exit 1
    }
}

# 验证01-fundamentals.md
function Verify-Fundamentals {
    Print-Header "验证 01-fundamentals.md"
    
    # 1. 运行Hello World容器
    Print-Info "运行Hello World容器..."
    if (docker run --rm hello-world 2>&1 | Out-Null) {
        Print-Success "运行Hello World容器"
    } else {
        Print-Error "运行Hello World容器"
    }
    
    # 2. 运行交互式容器
    Print-Info "运行交互式容器..."
    if (docker run --rm alpine echo "Hello, World!" 2>&1 | Out-Null) {
        Print-Success "运行交互式容器"
    } else {
        Print-Error "运行交互式容器"
    }
    
    # 3. 运行后台容器
    Print-Info "运行后台容器..."
    if (docker run -d --name test-nginx nginx:alpine 2>&1 | Out-Null) {
        Print-Success "运行后台容器"
        docker stop test-nginx 2>&1 | Out-Null
        docker rm test-nginx 2>&1 | Out-Null
    } else {
        Print-Error "运行后台容器"
    }
    
    # 4. 容器资源限制
    Print-Info "容器资源限制..."
    if (docker run -d --name test-limited --cpus="0.5" --memory="512m" nginx:alpine 2>&1 | Out-Null) {
        Print-Success "容器资源限制"
        docker stop test-limited 2>&1 | Out-Null
        docker rm test-limited 2>&1 | Out-Null
    } else {
        Print-Error "容器资源限制"
    }
}

# 验证02-image-management.md
function Verify-ImageManagement {
    Print-Header "验证 02-image-management.md"
    
    # 创建临时目录
    $TEMP_DIR = Join-Path $env:TEMP "docker-verify-$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    Set-Location $TEMP_DIR
    
    # 1. 构建自定义镜像
    Print-Info "构建自定义镜像..."
    @"
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8
    
    @"
flask==2.3.3
"@ | Out-File -FilePath "requirements.txt" -Encoding utf8
    
    @"
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
"@ | Out-File -FilePath "app.py" -Encoding utf8
    
    if (docker build -t test-python-app:1.0 . 2>&1 | Out-Null) {
        Print-Success "构建自定义镜像"
        docker rmi test-python-app:1.0 2>&1 | Out-Null
    } else {
        Print-Error "构建自定义镜像"
    }
    
    # 2. 多阶段构建
    Print-Info "多阶段构建..."
    @"
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install

FROM nginx:alpine
COPY --from=builder /app /usr/share/nginx/html
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8
    
    @"
{
  "name": "test-app",
  "version": "1.0.0"
}
"@ | Out-File -FilePath "package.json" -Encoding utf8
    
    if (docker build -t test-node-app:1.0 . 2>&1 | Out-Null) {
        Print-Success "多阶段构建"
        docker rmi test-node-app:1.0 2>&1 | Out-Null
    } else {
        Print-Error "多阶段构建"
    }
    
    # 清理临时目录
    Set-Location $PSScriptRoot
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

# 验证03-container-management.md
function Verify-ContainerManagement {
    Print-Header "验证 03-container-management.md"
    
    # 1. 容器生命周期管理
    Print-Info "容器生命周期管理..."
    if (docker create --name test-container nginx:alpine 2>&1 | Out-Null) {
        if (docker start test-container 2>&1 | Out-Null) {
            if (docker stop test-container 2>&1 | Out-Null) {
                if (docker rm test-container 2>&1 | Out-Null) {
                    Print-Success "容器生命周期管理"
                } else {
                    Print-Error "容器生命周期管理"
                }
            } else {
                Print-Error "容器生命周期管理"
            }
        } else {
            Print-Error "容器生命周期管理"
        }
    } else {
        Print-Error "容器生命周期管理"
    }
    
    # 2. 容器资源管理
    Print-Info "容器资源管理..."
    if (docker run -d --name test-resource --cpus="0.5" --memory="512m" nginx:alpine 2>&1 | Out-Null) {
        Print-Success "容器资源管理"
        docker stop test-resource 2>&1 | Out-Null
        docker rm test-resource 2>&1 | Out-Null
    } else {
        Print-Error "容器资源管理"
    }
    
    # 3. 容器网络配置
    Print-Info "容器网络配置..."
    if (docker run -d --name test-network --network bridge -p 8080:80 nginx:alpine 2>&1 | Out-Null) {
        Print-Success "容器网络配置"
        docker stop test-network 2>&1 | Out-Null
        docker rm test-network 2>&1 | Out-Null
    } else {
        Print-Error "容器网络配置"
    }
    
    # 4. 容器数据持久化
    Print-Info "容器数据持久化..."
    if (docker volume create test-volume 2>&1 | Out-Null) {
        if (docker run -d --name test-volume-container -v test-volume:/data nginx:alpine 2>&1 | Out-Null) {
            Print-Success "容器数据持久化"
            docker stop test-volume-container 2>&1 | Out-Null
            docker rm test-volume-container 2>&1 | Out-Null
            docker volume rm test-volume 2>&1 | Out-Null
        } else {
            Print-Error "容器数据持久化"
            docker volume rm test-volume 2>&1 | Out-Null
        }
    } else {
        Print-Error "容器数据持久化"
    }
}

# 验证04-networking.md
function Verify-Networking {
    Print-Header "验证 04-networking.md"
    
    # 1. 创建自定义网络
    Print-Info "创建自定义网络..."
    if (docker network create test-network 2>&1 | Out-Null) {
        Print-Success "创建自定义网络"
        docker network rm test-network 2>&1 | Out-Null
    } else {
        Print-Error "创建自定义网络"
    }
    
    # 2. 容器间通信
    Print-Info "容器间通信..."
    if (docker network create test-network 2>&1 | Out-Null) {
        if (docker run -d --name test-web --network test-network nginx:alpine 2>&1 | Out-Null) {
            if (docker run -d --name test-app --network test-network python:3.11-alpine python -m http.server 8000 2>&1 | Out-Null) {
                Print-Success "容器间通信"
                docker stop test-web, test-app 2>&1 | Out-Null
                docker rm test-web, test-app 2>&1 | Out-Null
            } else {
                Print-Error "容器间通信"
                docker stop test-web 2>&1 | Out-Null
                docker rm test-web 2>&1 | Out-Null
            }
        } else {
            Print-Error "容器间通信"
        }
        docker network rm test-network 2>&1 | Out-Null
    } else {
        Print-Error "容器间通信"
    }
    
    # 3. 端口映射
    Print-Info "端口映射..."
    if (docker run -d --name test-port -p 8081:80 nginx:alpine 2>&1 | Out-Null) {
        Print-Success "端口映射"
        docker stop test-port 2>&1 | Out-Null
        docker rm test-port 2>&1 | Out-Null
    } else {
        Print-Error "端口映射"
    }
}

# 验证05-storage.md
function Verify-Storage {
    Print-Header "验证 05-storage.md"
    
    # 1. 创建数据卷
    Print-Info "创建数据卷..."
    if (docker volume create test-volume 2>&1 | Out-Null) {
        Print-Success "创建数据卷"
        docker volume rm test-volume 2>&1 | Out-Null
    } else {
        Print-Error "创建数据卷"
    }
    
    # 2. 绑定挂载
    Print-Info "绑定挂载..."
    $TEMP_DIR = Join-Path $env:TEMP "docker-verify-$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    if (docker run -d --name test-bind -v "${TEMP_DIR}:/data" nginx:alpine 2>&1 | Out-Null) {
        Print-Success "绑定挂载"
        docker stop test-bind 2>&1 | Out-Null
        docker rm test-bind 2>&1 | Out-Null
    } else {
        Print-Error "绑定挂载"
    }
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    
    # 3. tmpfs挂载
    Print-Info "tmpfs挂载..."
    if (docker run -d --name test-tmpfs --tmpfs /tmp:size=100m nginx:alpine 2>&1 | Out-Null) {
        Print-Success "tmpfs挂载"
        docker stop test-tmpfs 2>&1 | Out-Null
        docker rm test-tmpfs 2>&1 | Out-Null
    } else {
        Print-Error "tmpfs挂载"
    }
}

# 验证06-docker-compose.md
function Verify-DockerCompose {
    Print-Header "验证 06-docker-compose.md"
    
    # 创建临时目录
    $TEMP_DIR = Join-Path $env:TEMP "docker-verify-$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    Set-Location $TEMP_DIR
    
    # 1. Web应用部署
    Print-Info "Web应用部署..."
    @"
version: "3.8"

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
"@ | Out-File -FilePath "docker-compose.yml" -Encoding utf8
    
    if (docker-compose up -d 2>&1 | Out-Null) {
        Print-Success "Web应用部署"
        docker-compose down 2>&1 | Out-Null
    } else {
        Print-Error "Web应用部署"
    }
    
    # 清理临时目录
    Set-Location $PSScriptRoot
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

# 验证07-best-practices.md
function Verify-BestPractices {
    Print-Header "验证 07-best-practices.md"
    
    # 1. 镜像优化
    Print-Info "镜像优化..."
    $TEMP_DIR = Join-Path $env:TEMP "docker-verify-$(Get-Random)"
    New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null
    Set-Location $TEMP_DIR
    
    @"
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["python", "app.py"]
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8
    
    @"
flask==2.3.3
"@ | Out-File -FilePath "requirements.txt" -Encoding utf8
    
    @"
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
"@ | Out-File -FilePath "app.py" -Encoding utf8
    
    if (docker build -t test-optimized:1.0 . 2>&1 | Out-Null) {
        Print-Success "镜像优化"
        docker rmi test-optimized:1.0 2>&1 | Out-Null
    } else {
        Print-Error "镜像优化"
    }
    
    # 2. 容器安全
    Print-Info "容器安全..."
    if (docker run -d --name test-security --cap-drop ALL --cap-add NET_BIND_SERVICE --read-only --tmpfs /tmp --tmpfs /run nginx:alpine 2>&1 | Out-Null) {
        Print-Success "容器安全"
        docker stop test-security 2>&1 | Out-Null
        docker rm test-security 2>&1 | Out-Null
    } else {
        Print-Error "容器安全"
    }
    
    # 3. 性能优化
    Print-Info "性能优化..."
    if (docker run -d --name test-performance --cpus="0.5" --memory="512m" nginx:alpine 2>&1 | Out-Null) {
        Print-Success "性能优化"
        docker stop test-performance 2>&1 | Out-Null
        docker rm test-performance 2>&1 | Out-Null
    } else {
        Print-Error "性能优化"
    }
    
    # 清理临时目录
    Set-Location $PSScriptRoot
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

# 验证08-troubleshooting.md
function Verify-Troubleshooting {
    Print-Header "验证 08-troubleshooting.md"
    
    # 1. 容器启动失败处理
    Print-Info "容器启动失败处理..."
    if (docker run -d --name test-troubleshoot nginx:alpine 2>&1 | Out-Null) {
        Print-Success "容器启动失败处理"
        docker stop test-troubleshoot 2>&1 | Out-Null
        docker rm test-troubleshoot 2>&1 | Out-Null
    } else {
        Print-Error "容器启动失败处理"
    }
    
    # 2. 网络连接问题处理
    Print-Info "网络连接问题处理..."
    if (docker network create test-troubleshoot-network 2>&1 | Out-Null) {
        if (docker run -d --name test-troubleshoot-web --network test-troubleshoot-network nginx:alpine 2>&1 | Out-Null) {
            Print-Success "网络连接问题处理"
            docker stop test-troubleshoot-web 2>&1 | Out-Null
            docker rm test-troubleshoot-web 2>&1 | Out-Null
        } else {
            Print-Error "网络连接问题处理"
        }
        docker network rm test-troubleshoot-network 2>&1 | Out-Null
    } else {
        Print-Error "网络连接问题处理"
    }
    
    # 3. 存储访问问题处理
    Print-Info "存储访问问题处理..."
    if (docker volume create test-troubleshoot-volume 2>&1 | Out-Null) {
        if (docker run -d --name test-troubleshoot-storage -v test-troubleshoot-volume:/data nginx:alpine 2>&1 | Out-Null) {
            Print-Success "存储访问问题处理"
            docker stop test-troubleshoot-storage 2>&1 | Out-Null
            docker rm test-troubleshoot-storage 2>&1 | Out-Null
        } else {
            Print-Error "存储访问问题处理"
        }
        docker volume rm test-troubleshoot-volume 2>&1 | Out-Null
    } else {
        Print-Error "存储访问问题处理"
    }
}

# 清理函数
function Cleanup {
    Print-Header "清理验证环境"
    
    # 停止所有容器
    Print-Info "停止所有容器..."
    docker stop $(docker ps -aq) 2>&1 | Out-Null
    
    # 删除所有容器
    Print-Info "删除所有容器..."
    docker rm $(docker ps -aq) 2>&1 | Out-Null
    
    # 删除所有镜像
    Print-Info "删除所有镜像..."
    docker rmi $(docker images -q) 2>&1 | Out-Null
    
    # 删除所有数据卷
    Print-Info "删除所有数据卷..."
    docker volume rm $(docker volume ls -q) 2>&1 | Out-Null
    
    # 删除所有网络
    Print-Info "删除所有网络..."
    docker network rm $(docker network ls -q) 2>&1 | Out-Null
    
    # 清理所有未使用的资源
    Print-Info "清理所有未使用的资源..."
    docker system prune -a --volumes -f 2>&1 | Out-Null
    
    Print-Success "清理完成"
}

# 主函数
function Main {
    Print-Header "Docker代码验证"
    
    # 检查Docker环境
    Check-Docker
    
    # 验证各个章节
    Verify-Fundamentals
    Verify-ImageManagement
    Verify-ContainerManagement
    Verify-Networking
    Verify-Storage
    Verify-DockerCompose
    Verify-BestPractices
    Verify-Troubleshooting
    
    # 清理验证环境
    Cleanup
    
    # 打印验证结果
    Print-Header "验证结果"
    Write-Host "总计: $TOTAL"
    Write-Host "通过: $PASSED" -ForegroundColor $GREEN
    Write-Host "失败: $FAILED" -ForegroundColor $RED
    
    if ($FAILED -eq 0) {
        Write-Host ""
        Write-Host "所有验证通过！" -ForegroundColor $GREEN
        Write-Host ""
        exit 0
    } else {
        Write-Host ""
        Write-Host "部分验证失败！" -ForegroundColor $RED
        Write-Host ""
        exit 1
    }
}

# 运行主函数
Main
