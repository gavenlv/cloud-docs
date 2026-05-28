# GCP 环境设置指南

## 概述

本文档介绍如何在本地配置 GCP 开发环境，包括 gcloud CLI 安装、认证配置、以及 kubectl 连接 GKE 集群。

---

## 1. 安装 gcloud CLI

### 1.1 下载安装

**Windows:**

1. 下载安装包：https://cloud.google.com/sdk/docs/install
2. 运行安装程序
3. 安装完成后，打开新的终端窗口

**macOS:**

```bash
brew install --cask google-cloud-sdk
```

**Linux:**

```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### 1.2 验证安装

```bash
gcloud --version
```

### 1.3 初始化配置

```bash
gcloud init
```

这会引导你完成：
- 登录 Google 账号
- 选择或创建 GCP 项目
- 设置默认区域和可用区

---

## 2. 认证配置

### 2.1 用户账号认证

```bash
gcloud auth login
```

这会打开浏览器进行 OAuth 认证。

### 2.2 应用默认凭据 (ADC)

用于应用程序访问 GCP API：

```bash
gcloud auth application-default login
```

### 2.3 服务账号认证

```bash
gcloud auth activate-service-account SERVICE_ACCOUNT_EMAIL \
    --key-file=KEY_FILE_PATH
```

### 2.4 查看当前认证状态

```bash
gcloud auth list
```

---

## 3. 项目配置

### 3.1 设置默认项目

```bash
gcloud config set project PROJECT_ID
```

### 3.2 设置默认区域和可用区

```bash
gcloud config set compute/region asia-east1
gcloud config set compute/zone asia-east1-a
```

### 3.3 查看当前配置

```bash
gcloud config list
```

### 3.4 查看当前项目

```bash
gcloud config get-value project
```

---

## 4. kubectl 连接 GKE 集群

### 4.1 安装 kubectl

```bash
gcloud components install kubectl
```

验证安装：

```bash
kubectl version --client
```

### 4.2 安装 GKE 认证插件（必需）

从 Kubernetes 1.26 开始，需要安装 `gke-gcloud-auth-plugin`：

```bash
gcloud components install gke-gcloud-auth-plugin
```

验证安装：

```bash
gke-gcloud-auth-plugin --version
```

**重要提示：** 如果未安装此插件，kubectl 会报错：

```
CRITICAL: ACTION REQUIRED: gke-gcloud-auth-plugin, which is needed for continued use of kubectl, was not found or is not executable.
```

### 4.3 获取 GKE 集群凭据

**区域集群：**

```bash
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION
```

**可用区集群：**

```bash
gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE
```

**示例：**

```bash
# 区域集群
gcloud container clusters get-credentials my-gke-cluster --region=asia-east1

# 可用区集群
gcloud container clusters get-credentials my-gke-cluster --zone=asia-east1-a
```

### 4.4 验证连接

```bash
# 查看集群信息
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看命名空间
kubectl get namespaces
```

---

## 5. 多集群管理

### 5.1 查看所有 GKE 集群

```bash
gcloud container clusters list
```

### 5.2 查看 kubeconfig contexts

```bash
kubectl config get-contexts
```

### 5.3 查看当前 context

```bash
kubectl config current-context
```

### 5.4 切换 context

```bash
kubectl config use-contexts CONTEXT_NAME
```

### 5.5 多集群配置示例

```bash
# 添加集群 A
gcloud container clusters get-credentials cluster-a --region=us-central1

# 添加集群 B
gcloud container clusters get-credentials cluster-b --region=asia-east1

# 列出所有 context
kubectl config get-contexts

# 切换到集群 B
kubectl config use-contexts gke_project-id_asia-east1_cluster-b
```

---

## 6. 权限配置

### 6.1 所需 IAM 权限

连接 GKE 集群需要以下权限之一：

| 角色 | 权限范围 |
|------|----------|
| `roles/container.clusterViewer` | 只读访问集群 |
| `roles/container.developer` | 开发者权限 |
| `roles/container.admin` | 完全管理权限 |

### 6.2 授予权限

```bash
# 授予集群管理员权限
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="user:USER_EMAIL" \
    --role="roles/container.admin"
```

---

## 7. 常见问题排查

### 7.1 认证插件未安装

**错误信息：**

```
CRITICAL: ACTION REQUIRED: gke-gcloud-auth-plugin, which is needed for continued use of kubectl, was not found or is not executable.
```

**解决方案：**

```bash
gcloud components install gke-gcloud-auth-plugin
```

### 7.2 无法连接集群

**检查项：**

1. 确认集群存在：

```bash
gcloud container clusters list
```

2. 确认区域/可用区正确：

```bash
gcloud container clusters describe CLUSTER_NAME --region=REGION
```

3. 确认网络连通性：

```bash
gcloud compute networks describe default
```

### 7.3 权限不足

**错误信息：**

```
ERROR: (gcloud.container.clusters.get-credentials) ResponseError: code=403, message=Required "container.clusters.get" permission.
```

**解决方案：**

联系项目管理员授予 `roles/container.clusterViewer` 或更高权限。

### 7.4 kubeconfig 文件位置

默认位置：

- Linux/macOS: `~/.kube/config`
- Windows: `%USERPROFILE%\.kube\config`

自定义位置：

```bash
export KUBECONFIG=/path/to/custom/kubeconfig
```

---

## 8. 完整设置流程

### 8.1 新环境快速配置

```bash
# 1. 初始化 gcloud
gcloud init

# 2. 登录认证
gcloud auth login

# 3. 设置项目
gcloud config set project PROJECT_ID

# 4. 安装 kubectl
gcloud components install kubectl

# 5. 安装认证插件
gcloud components install gke-gcloud-auth-plugin

# 6. 获取集群凭据
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION

# 7. 验证连接
kubectl get nodes
```

### 8.2 验证所有组件

```bash
# 检查 gcloud 版本
gcloud version

# 检查 kubectl 版本
kubectl version --client

# 检查认证插件版本
gke-gcloud-auth-plugin --version

# 检查当前配置
gcloud config list

# 检查认证状态
gcloud auth list

# 检查集群连接
kubectl cluster-info
```

---

## 9. Terraform vs gcloud 分工

在项目中，建议按以下方式分工：

### 9.1 Terraform 管理的资源

- VPC、Subnets、Firewall Rules
- GKE Clusters、Node Pools
- Cloud SQL、Cloud Storage
- Service Accounts、IAM Policies
- 监控、日志配置

### 9.2 gcloud 适合的操作

- 临时调试：`gcloud compute ssh`
- 日志查看：`gcloud logging read`
- 镜像推送：`gcloud builds submit`
- 数据库连接：`gcloud sql connect`
- 集群凭据获取：`gcloud container clusters get-credentials`

### 9.3 核心原则

| 资源类型 | 管理工具 | 原因 |
|----------|----------|------|
| 基础设施 | Terraform | 版本控制、可重复、可审计 |
| 应用部署 | gcloud/CI | 灵活、快速、无需 state |
| 临时操作 | gcloud | 交互式、即时生效 |

---

## 参考链接

- [gcloud CLI 安装指南](https://cloud.google.com/sdk/docs/install)
- [kubectl 安装与配置](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)
- [GKE 认证插件](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin)
- [IAM 权限管理](https://cloud.google.com/iam/docs/overview)
