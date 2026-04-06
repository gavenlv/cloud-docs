# Chart仓库管理

## 6.1 仓库类型

### 6.1.1 仓库类型概览

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart仓库类型                                                   │
└─────────────────────────────────────────────────────────────────┘

1. 公共仓库
├── Artifact Hub (https://artifacthub.io/)
├── Bitnami (https://charts.bitnami.com/bitnami)
├── 官方仓库 (https://charts.helm.sh/stable)
└── 社区仓库 (GitHub Pages等)

2. 私有HTTP仓库
├── ChartMuseum
├── Harbor
├── S3/GCS存储
└── 自建HTTP服务器

3. OCI注册表
├── Docker Hub
├── GitHub Container Registry
├── AWS ECR
├── Azure Container Registry
├── Google Artifact Registry
└── Harbor

选择建议：
├── 开源项目：使用公共仓库
├── 企业内部：使用私有仓库或OCI
├── CI/CD集成：使用OCI注册表
└── 多云部署：使用OCI注册表
```

---

## 6.2 公共仓库

### 6.2.1 添加和使用仓库

```bash
# 添加仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# 更新仓库索引
helm repo update

# 列出已添加的仓库
helm repo list

# 输出：
# NAME                    URL
# bitnami                 https://charts.bitnami.com/bitnami
# prometheus-community    https://prometheus-community.github.io/helm-charts

# 搜索Chart
helm search repo nginx
helm search repo nginx --versions

# 搜索Artifact Hub
helm search hub nginx

# 查看Chart信息
helm show chart bitnami/nginx
helm show values bitnami/nginx
helm show readme bitnami/nginx
helm show all bitnami/nginx
```

### 6.2.2 Artifact Hub

```bash
# Artifact Hub是Chart的中央发现平台
# https://artifacthub.io/

# 搜索Chart
helm search hub nginx

# 输出：
# URL                                                CHART VERSION   APP VERSION     DESCRIPTION
# https://artifacthub.io/packages/helm/bitnami/nginx 15.0.0          1.25.0          NGINX Open Source...

# 安装从Hub发现的Chart
helm install my-nginx oci://registry-1.docker.io/bitnamicharts/nginx
```

---

## 6.3 私有HTTP仓库

### 6.3.1 ChartMuseum

```bash
# 安装ChartMuseum
helm repo add chartmuseum https://chartmuseum.github.io/charts
helm install chartmuseum chartmuseum/chartmuseum

# 或使用Docker
docker run -d -p 8080:8080 -v $(pwd)/charts:/charts \
  chartmuseum/chartmuseum:latest

# 添加私有仓库
helm repo add myrepo http://localhost:8080

# 推送Chart（需要helm-push插件）
helm plugin install https://github.com/chartmuseum/helm-push
helm push mychart-0.1.0.tgz myrepo

# 更新索引
helm repo update

# 搜索和安装
helm search repo mychart
helm install myapp myrepo/mychart
```

### 6.3.2 Harbor

```bash
# Harbor是功能完整的容器注册表，支持Chart

# 添加Harbor Chart仓库
helm repo add harbor https://helm.goharbor.io

# 安装Harbor
helm install harbor harbor/harbor \
  --set expose.type=nodePort \
  --set persistence.enabled=false

# 添加Harbor中的Chart仓库
helm repo add myharbor https://harbor.example.com/chartrepo/myproject

# 推送Chart到Harbor
helm push mychart-0.1.0.tgz myharbor
```

### 6.3.3 S3/GCS存储

```bash
# 使用S3作为Chart仓库
# 安装S3插件
helm plugin install https://github.com/hypnoglow/helm-s3.git

# 初始化S3仓库
helm s3 init s3://my-bucket/charts

# 添加S3仓库
helm repo add mys3 s3://my-bucket/charts

# 推送Chart
helm s3 push mychart-0.1.0.tgz mys3

# 使用GCS
helm plugin install https://github.com/hayorov/helm-gcs.git
helm gcs init gs://my-bucket/charts
helm repo add mygcs gs://my-bucket/charts
```

---

## 6.4 OCI注册表

### 6.4.1 OCI概述

```
┌─────────────────────────────────────────────────────────────────┐
│  OCI注册表优势                                                   │
└─────────────────────────────────────────────────────────────────┘

1. 统一管理
├── 容器镜像和Chart使用相同注册表
├── 统一的认证和授权
└── 统一的安全策略

2. 安全性
├── 支持签名验证
├── 支持漏洞扫描
└── 支持访问控制

3. 可靠性
├── 成熟的存储后端
├── 高可用部署
└── 全球分发

4. 兼容性
├── OCI标准
├── 支持多种注册表
└── 工具链支持
```

### 6.4.2 使用OCI注册表

```bash
# 登录OCI注册表
helm registry login registry.example.com

# 推送Chart到OCI
helm push mychart-0.1.0.tgz oci://registry.example.com/charts

# 输出：
# Pushed: registry.example.com/charts/mychart:0.1.0
# Digest: sha256:xxx

# 拉取Chart
helm pull oci://registry.example.com/charts/mychart --version 0.1.0

# 安装OCI Chart
helm install myapp oci://registry.example.com/charts/mychart --version 0.1.0

# 查看OCI Chart信息
helm show chart oci://registry.example.com/charts/mychart --version 0.1.0
helm show values oci://registry.example.com/charts/mychart --version 0.1.0

# 登出
helm registry logout registry.example.com
```

### 6.4.3 Docker Hub

```bash
# 登录Docker Hub
helm registry login registry-1.docker.io

# 推送到Docker Hub
helm push mychart-0.1.0.tgz oci://registry-1.docker.io/myuser

# 安装
helm install myapp oci://registry-1.docker.io/myuser/mychart --version 0.1.0
```

### 6.4.4 GitHub Container Registry

```bash
# 使用GitHub Token登录
helm registry login ghcr.io -u myuser -p ghp_xxx

# 推送到GHCR
helm push mychart-0.1.0.tgz oci://ghcr.io/myorg/charts

# 安装
helm install myapp oci://ghcr.io/myorg/charts/mychart --version 0.1.0
```

### 6.4.5 AWS ECR

```bash
# 登录AWS ECR
aws ecr get-login-password --region us-east-1 | helm registry login \
  --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# 创建ECR仓库
aws ecr create-repository --repository-name mychart

# 推送到ECR
helm push mychart-0.1.0.tgz oci://123456789.dkr.ecr.us-east-1.amazonaws.com

# 安装
helm install myapp oci://123456789.dkr.ecr.us-east-1.amazonaws.com/mychart \
  --version 0.1.0
```

---

## 6.5 仓库认证

### 6.5.1 基本认证

```bash
# 添加带认证的仓库
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password mypassword

# 使用环境变量
export HELM_REPO_USERNAME=myuser
export HELM_REPO_PASSWORD=mypassword
helm repo add myrepo https://charts.example.com

# 密码存储在文件中
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password-file /path/to/password
```

### 6.5.2 TLS认证

```bash
# 使用TLS证书
helm repo add myrepo https://charts.example.com \
  --ca-file /path/to/ca.crt \
  --cert-file /path/to/client.crt \
  --key-file /path/to/client.key

# 跳过TLS验证（不推荐生产使用）
helm repo add myrepo https://charts.example.com --insecure-skip-tls-verify
```

### 6.5.3 OCI认证

```bash
# 登录OCI注册表
helm registry login registry.example.com \
  --username myuser \
  --password mypassword

# 从文件读取密码
helm registry login registry.example.com \
  --username myuser \
  --password-stdin < /path/to/password

# 使用Docker配置
# Helm会自动使用~/.docker/config.json中的认证信息
```

---

## 6.6 Chart签名验证

### 6.6.1 签名Chart

```bash
# 生成GPG密钥（如果没有）
gpg --full-generate-key

# 签名Chart
helm package ./mychart --sign --key 'John Doe' --keyring ~/.gnupg/pubring.gpg

# 输出：
# Successfully packaged chart and saved it to: /path/to/mychart-0.1.0.tgz
# Successfully signed chart and saved it to: /path/to/mychart-0.1.0.tgz.prov

# 文件：
# mychart-0.1.0.tgz       Chart包
# mychart-0.1.0.tgz.prov  签名文件
```

### 6.6.2 验证签名

```bash
# 验证Chart签名
helm verify mychart-0.1.0.tgz --keyring ~/.gnupg/pubring.gpg

# 安装时验证
helm install myapp ./mychart-0.1.0.tgz \
  --verify \
  --keyring ~/.gnupg/pubring.gpg

# 验证失败示例
# Error: openpgp: signature made by unknown entity
```

### 6.6.3 发布签名Chart

```bash
# 上传到仓库时需要同时上传.tgz和.tgz.prov文件

# ChartMuseum
curl -u user:pass -T mychart-0.1.0.tgz http://localhost:8080/api/charts
curl -u user:pass -T mychart-0.1.0.tgz.prov http://localhost:8080/api/prov

# OCI注册表会自动处理签名
helm push mychart-0.1.0.tgz oci://registry.example.com/charts
```

---

## 6.7 自建仓库

### 6.7.1 简单HTTP服务器

```bash
# 目录结构
charts/
├── index.yaml
├── mychart-0.1.0.tgz
└── mychart-0.2.0.tgz

# 生成index.yaml
helm repo index ./charts --url https://charts.example.com

# index.yaml内容
apiVersion: v1
entries:
  mychart:
    - apiVersion: v2
      appVersion: 1.0.0
      created: "2024-01-15T00:00:00Z"
      description: My Helm Chart
      digest: sha256:xxx
      name: mychart
      type: application
      urls:
        - https://charts.example.com/mychart-0.2.0.tgz
      version: 0.2.0
    - apiVersion: v2
      appVersion: 1.0.0
      created: "2024-01-14T00:00:00Z"
      description: My Helm Chart
      digest: sha256:xxx
      name: mychart
      type: application
      urls:
        - https://charts.example.com/mychart-0.1.0.tgz
      version: 0.1.0
generated: "2024-01-15T00:00:00Z"

# 使用Python启动简单服务器
cd charts && python -m http.server 8080

# 添加仓库
helm repo add local http://localhost:8080
```

### 6.7.2 GitHub Pages

```bash
# 1. 创建GitHub仓库
# 2. 创建gh-pages分支
# 3. 上传Chart和index.yaml

# 使用GitHub Actions自动发布
# .github/workflows/release-chart.yaml
name: Release Charts

on:
  push:
    branches:
      - main

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.5.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

# 用户添加仓库
helm repo add myrepo https://myuser.github.io/my-charts
```

---

## 6.8 仓库管理最佳实践

### 6.8.1 索引管理

```bash
# 合并新Chart到现有索引
helm repo index ./charts --url https://charts.example.com --merge ./charts/index.yaml

# 更新索引
helm repo update

# 强制更新
helm repo update --force-update
```

### 6.8.2 安全建议

```
┌─────────────────────────────────────────────────────────────────┐
│  仓库安全最佳实践                                                │
└─────────────────────────────────────────────────────────────────┘

1. 使用HTTPS
   ├── 加密传输
   ├── 防止中间人攻击
   └── 使用可信证书

2. 启用认证
   ├── 用户名密码
   ├── Token认证
   └── TLS客户端证书

3. 签名验证
   ├── 签名所有Chart
   ├── 安装时验证签名
   └── 管理好GPG密钥

4. 访问控制
   ├── 最小权限原则
   ├── 按项目隔离
   └── 审计日志

5. 漏洞扫描
   ├── 扫描Chart内容
   ├── 扫描依赖镜像
   └── 定期重新扫描
```

### 6.8.3 高可用部署

```yaml
# Harbor高可用部署示例
harbor:
  expose:
    type: loadBalancer
  persistence:
    enabled: true
    resourcePolicy: "keep"
  database:
    type: external
    external:
      host: postgres.example.com
  redis:
    type: external
    external:
      addr: redis.example.com:6379
```
