# GCP Secret Manager 深入解析

## 本章概述

Secret Manager是GCP提供的托管式密钥管理服务，用于安全存储和管理敏感信息，如API密钥、密码、证书和其他机密数据。本章深入讲解Secret Manager的原理、GKE集成、Service使用方式以及最佳安全实践。

## 学习目标

- 深入理解Secret Manager架构和核心概念
- 掌握Secret Manager的基本操作命令
- 掌握Secret Manager与GKE的集成方式
- 掌握在Cloud Run、Cloud Functions等服务中使用Secret Manager
- 理解密钥版本管理和IAM策略控制
- 掌握Secret Manager安全最佳实践

---

## 1. Secret Manager核心概念

### 1.1 为什么需要Secret Manager？

```
传统密钥管理问题

┌─────────────────────────────────────────────────────────────────────────┐
│                        传统密钥管理问题                                  │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    代码中的硬编码密钥                             │   │
│   │                                                                 │   │
│   │   # 不安全的做法                                                 │   │
│   │   DATABASE_PASSWORD = "my-secret-password"  ❌                  │   │
│   │   API_KEY = "sk-1234567890abcdef"          ❌                  │   │
│   │                                                                 │   │
│   │   问题:                                                        │   │
│   │   - 密钥提交到Git仓库                                           │   │
│   │   - 密钥暴露在日志和监控中                                       │   │
│   │   - 无法轮换和审计                                               │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    Secret Manager解决方案                        │   │
│   │                                                                 │   │
│   │   DATABASE_PASSWORD → Secret Manager → 应用运行时注入            │   │
│   │   API_KEY          → Secret Manager → 环境变量/挂载卷            │   │
│   │                                                                 │   │
│   │   优势:                                                         │   │
│   │   ✅ 密钥集中管理                                               │   │
│   │   ✅ 细粒度IAM控制                                              │   │
│   │   ✅ 自动密钥轮换支持                                           │   │
│   │   ✅ 完整审计日志                                               │   │
│   │   ✅ 与GCP服务原生集成                                          │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Secret Manager核心概念

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Secret Manager核心概念                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Secret (密钥)                                                         │
│   ├── 逻辑容器，存储一个类型的机密信息                                   │
│   ├── 例如: 数据库密码、API密钥、TLS证书                               │
│   └── 包含多个版本(Version)                                           │
│                                                                         │
│   Version (版本)                                                        │
│   ├── 特定时间点的密钥值                                                │
│   ├── 不可变，但可以禁用/销毁                                           │
│   ├── 支持版本轮换(rotation)                                           │
│   └── 格式: secret-name/versions/1, secret-name/versions/latest        │
│                                                                         │
│   Replication (复制策略)                                                │
│   ├── Automatic: GCP自动在多区域复制                                    │
│   └── Manual: 用户指定特定区域                                          │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Secret Manager与其他GCP服务对比

```
┌─────────────────────────────────────────────────────────────────────────┐
│              GCP安全服务对比                                             │
├─────────────────┬───────────────────┬───────────────────┬───────────────┤
│     属性        │  Secret Manager   │  Cloud KMS        │  HashiCorp   │
│                 │                   │                   │  Vault        │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   主要用途      │  存储敏感配置      │  加密密钥管理     │  通用机密管理 │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   数据类型      │  字符串/字节       │  加密密钥         │  任意机密     │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   IAM集成       │  原生支持          │  原生支持         │  需要配置     │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   GKE集成       │  CSI Driver       │  需要额外配置     │  CSI Driver  │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   审计日志      │  Cloud Logging    │  Cloud Logging    │  需配置       │
├─────────────────┼───────────────────┼───────────────────┼───────────────┤
│   成本          │  按密钥存储量计费  │  按密钥操作计费   │  自托管成本   │
└─────────────────┴───────────────────┴───────────────────┴───────────────┘
```

---

## 2. Secret Manager命令行操作

### 2.1 密钥基本操作

```bash
# ============================================================
# 密钥创建
# ============================================================

# 创建简单密钥
gcloud secrets create my-api-key --data-file=./api-key.txt

# 从标准输入创建密钥
echo -n "my-secret-value" | gcloud secrets create my-secret --data-file=-

# 创建带标签的密钥
gcloud secrets create db-password `
    --data-file=./password.txt `
    --labels=env=prod,team=database

# 创建手动复制策略的密钥(指定区域)
gcloud secrets create regional-secret `
    --data-file=./secret.txt `
    --replication-policy=manual `
    --locations=us-central1

# 创建多区域密钥
gcloud secrets create multi-region-secret `
    --data-file=./secret.txt `
    --replication-policy=manual `
    --locations=us-central1,europe-west1,asia-east1

# ============================================================
# 密钥查询
# ============================================================

# 列出所有密钥
gcloud secrets list

# 按项目筛选
gcloud secrets list --project=PROJECT_ID

# 查看密钥详情
gcloud secrets describe my-secret

# 查看密钥元数据(标签、创建时间等)
gcloud secrets describe my-secret --format="yaml"

# 列出密钥的所有版本
gcloud secrets versions list my-secret

# 查看特定版本详情
gcloud secrets versions describe 1 --secret=my-secret

# ============================================================
# 密钥访问
# ============================================================

# 访问最新版本
gcloud secrets versions access latest --secret=my-secret

# 访问特定版本
gcloud secrets versions access 1 --secret=my-secret

# 访问并保存到文件
gcloud secrets versions access latest --secret=my-secret --out-file=./retrieved.txt

# ============================================================
# 密钥更新
# ============================================================

# 添加新版本
gcloud secrets versions add my-secret --data-file=./new-value.txt

# 更新标签
gcloud secrets update my-secret --update-labels=env=staging

# 移除标签
gcloud secrets update my-secret --remove-labels=team

# ============================================================
# 密钥删除
# ============================================================

# 删除密钥(会删除所有版本)
gcloud secrets delete my-secret

# 强制删除(跳过确认)
gcloud secrets delete my-secret --quiet
```

### 2.2 版本管理操作

```bash
# ============================================================
# 版本控制
# ============================================================

# 禁用版本(密钥值仍然存在,但无法访问)
gcloud secrets versions disable 1 --secret=my-secret

# 启用版本
gcloud secrets versions enable 1 --secret=my-secret

# 销毁版本(永久删除)
gcloud secrets versions destroy 1 --secret=my-secret

# 查看版本状态
gcloud secrets versions describe 1 --secret=my-secret

# 查看所有版本状态
gcloud secrets versions list my-secret --show-labels
```

### 2.3 IAM策略管理

```bash
# ============================================================
# IAM策略
# ============================================================

# 查看密钥IAM策略
gcloud secrets get-iam-policy my-secret

# 添加用户访问权限
gcloud secrets add-iam-policy-binding my-secret `
    --member=user:developer@example.com `
    --role=roles/secretmanager.secretAccessor

# 添加服务账号访问权限
gcloud secrets add-iam-policy-binding my-secret `
    --member=serviceAccount:my-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# 添加服务账号密钥访问权限(含解密)
gcloud secrets add-iam-policy-binding my-secret `
    --member=serviceAccount:my-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# 移除访问权限
gcloud secrets remove-iam-policy-binding my-secret `
    --member=user:developer@example.com `
    --role=roles/secretmanager.secretAccessor

# 查看谁有访问权限
gcloud secrets get-iam-policy my-secret --format="yaml(bindings)"
```

---

## 3. Secret Manager与GKE集成

### 3.1 GKE Secret Manager CSI Driver架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│            GKE Secret Manager CSI Driver架构                             │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      GKE Cluster                                 │   │
│   │                                                                 │   │
│   │   ┌─────────────────────────────────────────────────────────┐   │   │
│   │   │              CSI Driver (gke-gcs-driver)                │   │   │
│   │   │                                                         │   │   │
│   │   │   ┌───────────────┐    ┌───────────────┐              │   │   │
│   │   │   │ SecretProvider  │    │ SecretProvider │              │   │   │
│   │   │   │    (Pod)        │    │    (Pod)       │              │   │   │
│   │   │   └───────┬───────┘    └───────┬───────┘              │   │   │
│   │   │           │                    │                       │   │   │
│   │   └───────────┼────────────────────┼───────────────────────┘   │   │
│   │               │                    │                           │   │
│   │               ▼                    ▼                           │   │
│   │   ┌───────────────────────────────────────────────────────┐   │   │
│   │   │              Secret Manager API                       │   │   │
│   │   │                                                         │   │   │
│   │   │   my-secret    my-api-key    db-password              │   │   │
│   │   │   versions: 1,2,3   versions: 1    versions: 1        │   │   │
│   │   └───────────────────────────────────────────────────────┘   │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   Pod挂载方式:                                                          │
│   1. 文件挂载卷 (file)        2. 环境变量 (env)                         │
│   /etc/secrets/my-secret     MY_SECRET=actual-value                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 启用Secret Manager CSI Driver

```bash
# GKE集群启用Secret Manager CSI Driver (GKE 1.24+)
gcloud container clusters update my-cluster `
    --region=us-central1 `
    --enable-gcp-secret-manager

# 检查CSI Driver状态
kubectl get pods -n kube-system | grep secret

# 查看SecretProviderClass CRD
kubectl get crd | grep secretprovider
```

### 3.3 使用SecretProviderClass

```yaml
# secret-provider-class.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: my-secret-provider
spec:
  provider: gcp
  parameters:
    secrets: |
      - resourceName: "projects/PROJECT_ID/secrets/my-secret/latest"
        fileName: "my-secret"
      - resourceName: "projects/PROJECT_ID/secrets/my-api-key/latest"
        fileName: "api-key"
```

### 3.4 Pod中使用Secret Manager (文件挂载)

```yaml
# pod-with-secret-file.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-with-secrets
spec:
  containers:
    - name: my-app
      image: my-image:latest
      volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secrets
      csi:
        driver: secrets-store.gke.io
        volumeAttributes:
          secretProviderClass: "my-secret-provider"
```

```bash
# 部署Pod
kubectl apply -f pod-with-secret-file.yaml

# 验证挂载
kubectl exec my-app-with-secrets -- ls -la /etc/secrets/

# 查看密钥内容
kubectl exec my-app-with-secrets -- cat /etc/secrets/my-secret
```

### 3.5 Pod中使用Secret Manager (环境变量)

```yaml
# pod-with-secret-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app-with-env-secrets
spec:
  containers:
    - name: my-app
      image: my-image:latest
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-secret-provider
              key: db-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: my-secret-provider
              key: api-key
      volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true
  volumes:
    - name: secrets
      csi:
        driver: secrets-store.gke.io
        volumeAttributes:
          secretProviderClass: "my-secret-provider"
```

```bash
# 部署Pod
kubectl apply -f pod-with-secret-env.yaml

# 验证环境变量
kubectl exec my-app-with-env-secrets -- env | grep -E "(DB_PASSWORD|API_KEY)"
```

### 3.6 GKE Deployment完整示例

```yaml
# deployment-with-secrets.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-webapp
  labels:
    app: my-webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-webapp
  template:
    metadata:
      labels:
        app: my-webapp
    spec:
      serviceAccountName: my-webapp-sa
      containers:
        - name: webapp
          image: my-webapp:latest
          ports:
            - containerPort: 8080
          env:
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-secret-provider
                  key: db-password
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-secret-provider
                  key: redis-password
          volumeMounts:
            - name: tls-certs
              mountPath: /etc/tls
              readOnly: true
      volumes:
        - name: tls-certs
          csi:
            driver: secrets-store.gke.io
            volumeAttributes:
              secretProviderClass: "tls-cert-provider"
        - name: secrets
          csi:
            driver: secrets-store.gke.io
            volumeAttributes:
              secretProviderClass: "my-secret-provider"
```

### 3.7 GKE Workload Identity集成

```bash
# ============================================================
# 配置Workload Identity (推荐)
# ============================================================

# 创建服务账号
gcloud iam service-accounts create my-webapp-sa `
    --display-name="My WebApp Service Account"

# 授予Secret Manager访问权限
gcloud secrets add-iam-policy-binding my-secret `
    --member=serviceAccount:my-webapp-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# 绑定Kubernetes服务账号到GCP服务账号
gcloud iam service-accounts add-iam-policy-binding `
    my-webapp-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/iam.workloadIdentityUser `
    --member=serviceAccount:PROJECT_ID.svc.id.goog[default/my-webapp-sa]

# 在Kubernetes中标注服务账号
kubectl annotate serviceaccount my-webapp-sa `
    iam.gke.io/gcp-service-account=my-webapp-sa@PROJECT_ID.iam.gserviceaccount.com
```

```yaml
# deployment-with-workload-identity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-webapp
spec:
  template:
    spec:
      serviceAccountName: my-webapp-sa
      containers:
        - name: webapp
          image: my-webapp:latest
```

---

## 4. Cloud Run中使用Secret Manager

### 4.1 Cloud Run Secret Manager集成架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│            Cloud Run Secret Manager集成架构                              │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      Cloud Run Service                           │   │
│   │                                                                 │   │
│   │   my-cloudrun-service                                           │   │
│   │   ├── env:                                                     │   │
│   │   │   DB_PASSWORD: projects/xxx/secrets/db-password/latest   │   │
│   │   │   API_KEY: projects/xxx/secrets/api-key/latest           │   │
│   │   └── volumes:                                                 │   │
│   │       /etc/secrets -> my-secret                                │   │
│   │                                                                 │   │
│   └────────────────────────────┬────────────────────────────────────┘   │
│                                │                                         │
│                                ▼                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                      Secret Manager                              │   │
│   │                                                                 │   │
│   │   db-password (versions: 1,2,3)                                │   │
│   │   api-key (versions: 1,2)                                      │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│   IAM: Cloud Run Service SA 需要 roles/secretmanager.secretAccessor   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Cloud Run部署时引用Secret Manager

```bash
# ============================================================
# 部署Cloud Run服务并引用密钥
# ============================================================

# 使用环境变量引用密钥(最新版本)
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --update-env-vars DB_PASSWORD=projects/PROJECT_ID/secrets/db-password/latest

# 使用环境变量引用密钥(指定版本)
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --update-env-vars DB_PASSWORD=projects/PROJECT_ID/secrets/db-password/2

# 多个密钥
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --update-env-vars `
        DB_PASSWORD=projects/PROJECT_ID/secrets/db-password/latest,`
        API_KEY=projects/PROJECT_ID/secrets/api-key/latest

# 使用卷挂载引用密钥
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --mount-secrets /etc/secrets=my-secret:latest

# 完整示例
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated `
    --service-account=my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --update-env-vars `
        DB_HOST=localhost,`
        DB_PASSWORD=projects/PROJECT_ID/secrets/db-password/latest,`
        REDIS_PASSWORD=projects/PROJECT_ID/secrets/redis-password/latest `
    --mount-secrets /etc/tls=my-tls-cert:latest
```

### 4.3 Cloud Run IAM权限配置

```bash
# ============================================================
# 配置服务账号权限
# ============================================================

# 创建服务账号
gcloud iam service-accounts create my-service-sa `
    --display-name="My Cloud Run Service Account"

# 授予Secret Manager访问权限
gcloud secrets add-iam-policy-binding db-password `
    --member=serviceAccount:my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

gcloud secrets add-iam-policy-binding api-key `
    --member=serviceAccount:my-service-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# 验证权限
gcloud run services describe my-service --region=us-central1
```

### 4.4 Cloud Run服务配置验证

```bash
# 查看服务环境变量配置
gcloud run services describe my-service --region=us-central1 --format=yaml

# 查看服务的服务账号
gcloud run services describe my-service --region=us-central1 `
    --format="value(spec.template.spec.serviceAccountName)"

# 测试服务
curl $(gcloud run services describe my-service --region=us-central1 --format="value(status.url)")
```

---

## 5. Cloud Functions中使用Secret Manager

### 5.1 Cloud Functions Secret Manager集成

```bash
# ============================================================
# Cloud Functions v1 (第一代)
# ============================================================

# 部署Cloud Functions并引用密钥
gcloud functions deploy my-function `
    --runtime python310 `
    --trigger-http `
    --region us-central1 `
    --update-env-vars DB_PASSWORD=projects/PROJECT_ID/secrets/db-password/latest

# ============================================================
# Cloud Functions v2 (第二代) - 推荐
# ============================================================

# 使用--set-secrets标志
gcloud functions deploy my-function-v2 `
    --runtime python310 `
    --trigger-http `
    --region us-central1 `
    --entry-point main `
    --set-secrets DB_PASSWORD=db-password:latest,API_KEY=api-key:latest

# 完整示例
gcloud functions deploy my-function-v2 `
    --runtime python310 `
    --trigger-http `
    --region us-central1 `
    --service-account=my-function-sa@PROJECT_ID.iam.gserviceaccount.com `
    --set-secrets `
        DB_PASSWORD=db-password:latest,`
        REDIS_PASSWORD=redis-password:latest,`
        TLS_CERT=tls-cert:latest
```

### 5.2 Cloud Functions代码中使用密钥

```python
# main.py for Cloud Functions v2
import os

def main(request):
    # 通过环境变量访问密钥(Cloud Functions自动注入)
    db_password = os.environ.get('DB_PASSWORD')
    api_key = os.environ.get('API_KEY')

    # 使用密钥连接数据库
    # connection = connect_db(host='localhost', password=db_password)

    return f"Secret loaded: DB_PASSWORD={bool(db_password)}"
```

---

## 6. Secret Manager安全最佳实践

### 6.1 密钥访问控制

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Secret Manager安全最佳实践                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   1. 最小权限原则                                                        │
│   ├── 使用专用服务账号                                                   │
│   ├── 仅授予必要的密钥访问权限                                           │
│   └── 避免使用项目级editor/viewer角色                                   │
│                                                                         │
│   2. Workload Identity                                                  │
│   ├── GKE中使用Workload Identity代替密钥文件                            │
│   ├── 避免创建服务账号密钥文件                                           │
│   └── 定期审计绑定关系                                                   │
│                                                                         │
│   3. 密钥轮换                                                            │
│   ├── 定期轮换敏感密钥(密码、API密钥)                                    │
│   ├── 使用版本管理实现无停机轮换                                         │
│   ├── 旧版本保留一段时间后再销毁                                        │
│   └── 建立密钥轮换自动化流程                                             │
│                                                                         │
│   4. 审计和监控                                                          │
│   ├── 启用Cloud Audit Logs                                              │
│   ├── 设置密钥访问告警                                                   │
│   └── 定期审查IAM策略                                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2 IAM最佳实践

```bash
# ============================================================
# 项目级最佳实践
# ============================================================

# 创建专用服务账号(不要使用默认计算服务账号)
gcloud iam service-accounts create my-app-sa `
    --display-name="My Application Service Account"

# 分层授权
# Level 1: 项目级基础权限
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# Level 2: 特定密钥额外权限(使用条件)
gcloud secrets add-iam-policy-binding prod-api-key `
    --member=serviceAccount:my-app-sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor `
    --condition=expression=resource.name=="projects/PROJECT_ID/secrets/prod-api-key"

# ============================================================
# 审计配置
# ============================================================

# 查看Secret Manager审计配置
gcloud logging writes describe --service=secretmanager.googleapis.com

# 查询密钥访问日志
gcloud logging read "
    resource.type=secretmanager_project
    AND protoPayload.methodName=SecretManagerService.AccessSecretVersion
" --limit=50

# 查看谁在什么时间访问了密钥
gcloud logging read "
    resource.type=secretmanager_project
    AND protoPayload.methodName=SecretManagerService.AccessSecretVersion
" --format="table(timestamp,authenticationInfo.principalEmail,resource.labels.secret_id)"
```

### 6.3 密钥轮换策略

```bash
# ============================================================
# 密钥轮换流程
# ============================================================

# Step 1: 创建新版本
echo -n "new-password-v2" | gcloud secrets versions add db-password --data-file=-

# Step 2: 验证新版本可用
gcloud secrets versions access 2 --secret=db-password

# Step 3: 更新应用使用新版本
# 应用配置从 db-password/latest 改为 db-password/2

# Step 4: 确认应用正常后禁用旧版本
gcloud secrets versions disable 1 --secret=db-password

# Step 5: 一段时间后销毁旧版本(确保无回退需求)
gcloud secrets versions destroy 1 --secret=db-password

# ============================================================
# 自动化轮换脚本示例
# ============================================================

#!/bin/bash
# rotate-secret.sh

SECRET_NAME=$1
NEW_VALUE=$2

# 创建新版本
echo -n "$NEW_VALUE" | gcloud secrets versions add $SECRET_NAME --data-file=-

# 获取最新版本号
LATEST_VERSION=$(gcloud secrets versions list $SECRET_NAME --filter="state=ENABLED" --format="value(name)" | head -1)

echo "Created new version: $LATEST_VERSION"
echo "Update your applications to use: ${SECRET_NAME}/${LATEST_VERSION}"
```

---

## 7. Secret Manager集成场景

### 7.1 与Cloud Build集成

```bash
# ============================================================
# Cloud Build中使用Secret Manager
# ============================================================

# cloudbuild.yaml
steps:
  # 部署到Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - run
      - deploy
      - my-service
      --image
      - gcr.io/$PROJECT_ID/my-image:$COMMIT_SHA
      --region
      - us-central1
      --update-env-vars
      - DB_PASSWORD=projects/$PROJECT_ID/secrets/db-password/latest

# 设置服务账号权限
gcloud secrets add-iam-policy-binding db-password `
    --member=serviceAccount:cloudbuild-sa@$PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor
```

### 7.2 与Terraform集成

```hcl
# terraform.tfvars
project_id = "my-project"

# main.tf
variable "project_id" {}

data "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
}

data "google_secret_manager_secret_version" "db_password" {
  secret = data.google_secret_manager_secret.db_password.secret_id
}

resource "google_cloud_run_service" "my_service" {
  name     = "my-service"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/my-image:latest"
        env {
          name = "DB_PASSWORD"
          value = data.google_secret_manager_secret_version.db_password.secret_data
        }
      }
    }
  }
}
```

### 7.3 与Anthos Service Mesh集成

```yaml
# 在ASM环境中使用Secret Manager
apiVersion: v1
kind: Secret
metadata:
  name: my-tls-secret
  annotations:
    security.cloud.google.com/tls-cert: "projects/PROJECT_ID/secrets/my-cert/latest"
type: Opaque
```

---

## 8. 知识检测

### 选择题

1. Secret Manager CSI Driver在GKE中的驱动名称是什么?
   - A. pd.csi.storage.gke.io
   - B. secrets-store.gke.io ✓
   - C. filestore.csi.storage.gke.io
   - D. compute.gke.io

2. 在Cloud Run中引用Secret Manager密钥的正确格式是什么?
   - A. secret-name:latest
   - B. projects/PROJECT_ID/secrets/secret-name/latest ✓
   - C. secrets/secret-name@latest
   - D. gs://secret-manager/secret-name

3. GKE中使用Secret Manager的推荐认证方式是什么?
   - A. 服务账号密钥文件
   - B. Workload Identity ✓
   - C. 手动配置kubeconfig
   - D. 默认计算服务账号

4. Secret Manager支持哪些复制策略?(多选)
   - A. Automatic ✓
   - B. Manual (指定区域) ✓
   - C. Regional
   - D. Zonal

5. 密钥版本被禁用(Disabled)后会发生什么?
   - A. 版本被永久删除
   - B. 版本无法被访问,但数据仍存在 ✓
   - C. 版本自动启用
   - D. 版本被标记为最新

---

## 扩展阅读

- [Secret Manager文档](https://cloud.google.com/secret-manager/docs)
- [GKE Secret Manager CSI Driver](https://cloud.google.com/anthos/service-workflow/docs/use-secret-manager)
- [Cloud Run密钥管理](https://cloud.google.com/run/docs/configuring/secrets)
- [Workload Identity最佳实践](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Secret Manager IAM](https://cloud.google.com/secret-manager/docs/access-control)

---

## 学习进度

- [ ] 深入理解Secret Manager架构和核心概念
- [ ] 掌握Secret Manager的基本操作命令
- [ ] 掌握Secret Manager与GKE的集成方式
- [ ] 掌握在Cloud Run、Cloud Functions等服务中使用Secret Manager
- [ ] 理解密钥版本管理和IAM策略控制
- [ ] 掌握Secret Manager安全最佳实践
