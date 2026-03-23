# ============================================================
# 技巧1: 选择合适的基础镜像
# ============================================================

# 问题: 为什么要选择特定的基础镜像？
# 
# 镜像大小对比:
# ├── scratch: 0KB (空镜像，需要自己添加所有内容)
# ├── alpine: ~5MB (最小化Linux发行版)
# ├── debian:slim: ~25MB
# ├── ubuntu: ~77MB
# ├── centos: ~200MB
# └── python:3.11: ~1GB (包含完整Python环境)

# 生产环境推荐:
FROM python:3.11-slim  # ~140MB，安装依赖后约200-300MB
FROM node:18-alpine    # ~15MB，安装依赖后约50-100MB

# 极度轻量场景:
FROM gcr.io/distroless/python3-debian11  # 只有Python，无shell


# ============================================================
# 技巧2: 减少层数
# ============================================================

# 问题: 为什么要减少层数？
# 
# 层数影响:
# ├── 更多层 = 更大的镜像 (每层都有元数据)
# ├── 更多层 = 更长的构建时间
# └── 更多层 = 更复杂的缓存管理

# 不好: 多个独立的RUN
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y nginx
RUN rm -rf /var/lib/apt/lists/*

# 好: 合并成一个RUN
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        nginx \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# 技巧3: 利用构建缓存
# ============================================================

# 问题: 为什么要按特定顺序复制文件？
# 
# Docker缓存机制:
# ├── 从上到下执行每条指令
# ├── 如果指令和之前完全相同，使用缓存
# ├── 如果某层变化，后续所有层都需要重建
# └── 变化频繁的放后面

# 不好: 先复制全部代码
COPY . /app
RUN npm install  # 每次代码变化都需要重新安装依赖

# 好: 先复制依赖文件
COPY package*.json /app/
RUN npm install  # 只在依赖变化时重新安装
COPY . /app     # 代码变化不影响依赖安装


# ============================================================
# 技巧4: 清理缓存和临时文件
# ============================================================

# 每个包管理器的清理方式:

# APT (Debian/Ubuntu)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 \
    && rm -rf /var/lib/apt/lists/*

# pip (Python)
RUN pip install --no-cache-dir -r requirements.txt

# npm (Node.js)
RUN npm ci --only=production

# Maven (Java)
RUN mvn package -DskipTests && \
    rm -rf ~/.m2/repository

# yum/dnf (RHEL/CentOS)
RUN dnf install -y package && \
    dnf clean all


# ============================================================
# 技巧5: 使用.dockerignore
# ============================================================

# 问题: 为什么要使用.dockerignore？
# 
# 原因:
# ├── 减小构建上下文
# ├── 加快构建速度
# └── 避免意外复制敏感文件

# .dockerignore 文件示例:
.git              # 版本控制
.gitignore        # 忽略文件
*.md              # 文档文件
node_modules/     # 本地依赖（应该用容器内安装）
npm-debug.log     # npm日志
.env.local        # 本地环境变量
dist/             # 构建输出（应该用容器内构建）
coverage/         # 测试覆盖率
*.log             # 日志文件
.DS_Store         # macOS系统文件
Thumbs.db         # Windows系统文件
.vscode/          # 编辑器配置
.idea/            # IDE配置