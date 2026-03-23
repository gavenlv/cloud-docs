# Doris存算分离 - GKE + GCS云端部署

## 概述

本文档介绍如何在Google Kubernetes Engine (GKE) 上部署Apache Doris存算分离架构，使用Google Cloud Storage (GCS) 作为共享存储。

## 前置要求

### 工具安装

```bash
# 安装gcloud CLI
curl https://sdk.cloud.google.com | bash
gcloud init

# 安装kubectl
gcloud components install kubectl

# 安装helm
curl -fsSL https://get.helm.sh | bash
```

### GCP项目配置

```bash
# 设置项目
gcloud config set project YOUR_PROJECT_ID

# 启用必要API
gcloud services enable container.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com

# 设置区域
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## 创建GKE集群

### 1. 创建集群

```bash
# 创建Standard集群
gcloud container clusters create doris-cluster \
    --region us-central1 \
    --node-pool-name default-pool \
    --num-nodes 3 \
    --machine-type n2-standard-4 \
    --enable-autoscaling \
    --min-nodes 1 \
    --max-nodes 5

# 获取集群凭证
gcloud container clusters get-credentials doris-cluster --region us-central1
```

### 2. 创建命名空间

```bash
kubectl create namespace doris
```

## 配置GCS存储

### 1. 创建存储桶

```bash
# 创建GCS bucket
gsutil mb -l us-central1 gs://doris-data-bucket/

# 设置生命周期（可选，30天后转为冷存储）
gsutil lifecycle set lifecycle-config.json gs://doris-data-bucket/
```

### 2. 创建服务账号

```bash
# 创建服务账号
gcloud iam service-accounts create doris-storage-sa \
    --display-name="Doris Storage Service Account"

# 获取账号邮箱
SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:Doris Storage Service Account" \
    --format='value(email)')

# 授予存储桶权限
gsutil iam ch serviceAccount:${SA_EMAIL}:roles/storage.objectAdmin \
    gs://doris-data-bucket/
```

### 3. 创建密钥Secret

```bash
# 创建密钥文件
kubectl create secret generic gcs-credentials \
    --namespace doris \
    --from-file=credentials.json=/path/to/credentials.json
```

## 部署Doris

### 1. 添加Helm仓库

```bash
helm repo add apache-doris https://apache-doris.github.io/helm-charts
helm repo update
```

### 2. 配置values文件

```yaml
# gke-values.yaml
namespace: doris

imageRegistry: apache/doris

# FE配置
fe:
  replicas: 3
  image:
    repository: doris
    tag: 2.1.0
    pullPolicy: IfNotPresent
  resources:
    requests:
      cpu: 2
      memory: 4Gi
    limits:
      cpu: 4
      memory: 8Gi
  service:
    type: ClusterIP
    port: 9030
  config:
    FE_CONFIG: |
      log_verbose_modules = *
      max_connections_per_user = 100

# 计算节点配置 (存算分离)
compute:
  replicas: 3
  image:
    repository: doris
    tag: 2.1.0
    pullPolicy: IfNotPresent
  resources:
    requests:
      cpu: 4
      memory: 8Gi
    limits:
      cpu: 8
      memory: 16Gi
  config:
    BE_CONFIG: |
      be_port = 9050
      webserver_port = 8040
      heartbeat_service_port = 9050
      brpc_port = 9060
      storage_root_path = /mnt/disk1/doris_cloud_cache
      # GCS配置
      object_storage_endpoint = storage.googleapis.com
      object_storage_region = us-central1
      object_storage_bucket = doris-data-bucket
      object_storage_access_key = $ACCESS_KEY
      object_storage_secret_key = $SECRET_KEY
      object_storage_use_https = true
      # 缓存配置
      cache_file_size = 20
      cache_ttl_seconds = 86400
  persistentVolumeClaim:
    metadata:
      name: doris-cloud-cache
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 100Gi
      storageClassName: standard-rwo
  env:
    - name: CLOUD_UNIQUE_ID
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
  serviceAccount:
    create: true
    annotations:
      iam.gke.io/gcp-service-account: doris-storage-sa

# 存储配置
storage:
  # 使用GCS
  useGCS: true
  gcs:
    bucket: doris-data-bucket
    projectId: YOUR_PROJECT_ID
```

### 3. 安装Doris

```bash
helm install doris apache-doris/doris \
    -n doris \
    -f gke-values.yaml

# 检查部署状态
kubectl get pods -n doris

# 查看FE日志
kubectl logs -n doris -l app.kubernetes.io/component=fe

# 查看计算节点日志
kubectl logs -n doris -l app.kubernetes.io/component=compute
```

## 访问Doris

### 1. 获取FE服务地址

```bash
# 查看FE服务
kubectl get svc -n doris

# 端口转发进行本地访问
kubectl port-forward -n doris svc/doris-fe 9030:9030

# 或者使用LoadBalancer
kubectl patch svc doris-fe -n doris -p \
    '{"spec":{"type":"LoadBalancer"}}'
```

### 2. 连接Doris

```bash
# 使用MySQL客户端连接
mysql -h <FE_EXTERNAL_IP> -P 9030 -uroot -p''

# 验证集群状态
SHOW FRONTENDS;
SHOW BACKENDS;
SHOW COMPUTE NODES;
```

## 验证部署

### 1. 创建测试数据库

```sql
CREATE DATABASE test_separation;
USE test_separation;

-- 创建表
CREATE TABLE test_table (
    user_id BIGINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age INT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) DUPLICATE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;
```

### 2. 插入测试数据

```sql
-- 插入数据
INSERT INTO test_table VALUES
(1, 'user1', 'user1@example.com', 25, NOW()),
(2, 'user2', 'user2@example.com', 30, NOW()),
(3, 'user3', 'user3@example.com', 28, NOW());

-- 查询数据
SELECT * FROM test_table;

-- 验证数据分布
SHOW DATA;
```

### 3. 验证对象存储

```bash
# 查看GCS中的数据
gsutil ls -r gs://doris-data-bucket/
```

## 扩缩容

### 扩容计算节点

```bash
# 通过helm升级
helm upgrade doris apache-doris/doris \
    -n doris \
    --set compute.replicas=5

# 或直接修改副本数
kubectl scale statefulset doris-compute -n doris --replicas=5
```

### 缩容计算节点

```bash
# 先下线节点（安全缩容）
mysql -h <FE_IP> -P 9030 -uroot -p -e \
    "ALTER SYSTEM DECOMMISSION BACKEND '<backend_ip>:9050';"

# 等待数据迁移完成后缩容
kubectl scale statefulset doris-compute -n doris --replicas=2
```

## 监控配置

### 1. 安装Prometheus

```bash
# 添加Prometheus仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 安装Prometheus
helm install prometheus prometheus-community/prometheus \
    -n doris \
    --set alertmanager.enabled=false \
    --set server.persistentVolume.enabled=true \
    --set server.persistentVolume.size=50Gi
```

### 2. 安装Grafana

```bash
helm install grafana grafana/grafana \
    -n doris \
    --set adminPassword='Doris2024!' \
    --set persistence.enabled=true \
    --set persistence.size=10Gi
```

### 3. 导入Doris Dashboard

```bash
# 获取Grafana admin密码
kubectl get secret --namespace doris grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# 端口转发
kubectl port-forward -n doris svc/grafana 3000:80

# 在Grafana中导入Dashboard JSON文件
```

## 清理资源

```bash
# 删除Doris集群
helm uninstall doris -n doris

# 删除GCS bucket
gsutil rm -r gs://doris-data-bucket/

# 删除GKE集群
gcloud container clusters delete doris-cluster --region us-central1
```

## 常见问题

### Q: 计算节点无法连接对象存储？

A: 检查以下几点：
1. 服务账号权限是否正确配置
2. GCS bucket名称是否正确
3. 网络策略是否允许访问外网

### Q: 缓存未命中率高？

A: 可以通过以下方式优化：
1. 增加本地缓存大小
2. 调整缓存TTL
3. 预热热点数据

### Q: 如何切换存储类型？

A: Doris支持在创建表时指定存储介质：
```sql
CREATE TABLE t (...) PROPERTIES ("storage_medium" = "SSD");
```
