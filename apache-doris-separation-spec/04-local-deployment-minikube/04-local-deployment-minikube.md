# Doris存算分离 - Minikube本地集群部署

## 概述

本文档介绍如何在Minikube本地Kubernetes集群上部署Apache Doris存算分离架构，使用MinIO模拟S3兼容的对象存储。

## 前置要求

### 安装工具

```bash
# 安装Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 安装kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# 安装Helm
curl -fsSL https://get.helm.sh | bash
```

### 启动Minikube

```bash
# 启动Minikube集群（分配足够资源）
minikube start \
    --driver=docker \
    --cpus=8 \
    --memory=16g \
    --disk-size=100g \
    --addons=storage-provisioner \
    --kubernetes-version=v1.28.0

# 验证集群状态
kubectl get nodes
kubectl get pod -A
```

## 部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Minikube Kubernetes                       │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │    FE-1   │  │    FE-2   │  │    FE-3   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Compute-1 │  │ Compute-2 │  │ Compute-3 │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐                                           │
│  │   MinIO     │                                           │
│  └─────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

## 部署步骤

### 1. 创建命名空间

```bash
kubectl create namespace doris
```

### 2. 部署MinIO

```bash
# 创建MinIO部署
kubectl apply -f minio-deployment.yaml -n doris

# 创建MinIO服务
kubectl apply -f minio-service.yaml -n doris

# 检查MinIO状态
kubectl get pods -n doris -l app=minio
kubectl get svc -n doris minio
```

### 3. 配置MinIO存储桶

```bash
# 获取MinIO Pod
MINIO_POD=$(kubectl get pods -n doris -l app=minio -o jsonpath='{.items[0].metadata.name}')

# 创建存储桶
kubectl exec -n doris $MINIO_POD -- mc alias set local http://localhost:9000 minioadmin minioadmin
kubectl exec -n doris $MINIO_POD -- mc mb local/doris-data --ignore-existing
kubectl exec -n doris $MINIO_POD -- mc anonymous set download local/doris-data
```

### 4. 配置StorageClass

```bash
# 创建StorageClass
kubectl apply -f storage-class.yaml -n doris

# 验证
kubectl get storageclass
```

### 5. 部署FE

```bash
# 部署FE
kubectl apply -f fe-deployment.yaml -n doris

# 检查FE状态
kubectl get pods -n doris -l app=doris,component=fe
kubectl logs -n doris -l app=doris,component=fe --tail=100
```

### 6. 部署计算节点

```bash
# 部署计算节点
kubectl apply -f compute-deployment.yaml -n doris

# 检查计算节点状态
kubectl get pods -n doris -l app=doris,component=compute
kubectl logs -n doris -l app=doris,component=compute --tail=100
```

### 7. 注册计算节点

```bash
# 端口转发FE
kubectl port-forward -n doris svc/doris-fe 9030:9030 &

# 连接Doris
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 注册计算节点
ALTER SYSTEM ADD BACKEND 'doris-compute-0.doris-compute.doris.svc.cluster.local:9050';
ALTER SYSTEM ADD BACKEND 'doris-compute-1.doris-compute.doris.svc.cluster.local:9050';
ALTER SYSTEM ADD BACKEND 'doris-compute-2.doris-compute.doris.svc.cluster.local:9050';

# 查看节点状态
SHOW BACKENDS\G
```

## 配置文件

### MinIO Deployment

```yaml
# minio-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: doris
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ROOT_USER
          value: minioadmin
        - name: MINIO_ROOT_PASSWORD
          value: minioadmin
        ports:
        - containerPort: 9000
          name: api
        - containerPort: 9001
          name: console
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        hostPath:
          path: /mnt/data/minio
          type: DirectoryOrCreate
```

### MinIO Service

```yaml
# minio-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: doris
spec:
  type: ClusterIP
  ports:
  - port: 9000
    targetPort: 9000
    name: api
  - port: 9001
    targetPort: 9001
    name: console
  selector:
    app: minio
```

### StorageClass

```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: doris-local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

### FE Deployment

```yaml
# fe-deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: doris-fe
  namespace: doris
spec:
  serviceName: doris-fe
  replicas: 3
  selector:
    matchLabels:
      app: doris
      component: fe
  template:
    metadata:
      labels:
        app: doris
        component: fe
    spec:
      containers:
      - name: fe
        image: apache/doris:2.1.0
        ports:
        - containerPort: 9030
          name: query
        - containerPort: 8030
          name: http
        - containerPort: 9010
          name: thrift
        env:
        - name: FE_SERVERS
          value: "doris-fe-0.doris-fe.doris.svc.cluster.local:9010,doris-fe-1.doris-fe.doris.svc.cluster.local:9010,doris-fe-2.doris-fe.doris.svc.cluster.local:9010"
        - name: FE_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: PRIORITY_NETWORKS
          value: "172.20.0.0/16"
        volumeMounts:
        - name: fe-meta
          mountPath: /opt/apache-doris/fe/meta
        - name: fe-log
          mountPath: /opt/apache-doris/fe/log
      volumes:
      - name: fe-meta
        emptyDir: {}
      - name: fe-log
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: doris-fe
  namespace: doris
spec:
  type: ClusterIP
  ports:
  - port: 9030
    targetPort: 9030
    name: query
  - port: 8030
    targetPort: 8030
    name: http
  selector:
    app: doris
    component: fe
```

### Compute Deployment

```yaml
# compute-deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: doris-compute
  namespace: doris
spec:
  serviceName: doris-compute
  replicas: 3
  selector:
    matchLabels:
      app: doris
      component: compute
  template:
    metadata:
      labels:
        app: doris
        component: compute
    spec:
      containers:
      - name: compute
        image: apache/doris:2.1.0
        ports:
        - containerPort: 8040
          name: webserver
        - containerPort: 9050
          name: be
        - containerPort: 9060
          name: brpc
        env:
        - name: FE_SERVERS
          value: "doris-fe-0.doris-fe.doris.svc.cluster.local:9010,doris-fe-1.doris-fe.doris.svc.cluster.local:9010,doris-fe-2.doris-fe.doris.svc.cluster.local:9010"
        - name: BE_ADDRS
          value: "doris-compute-0.doris-compute.doris.svc.cluster.local:9050,doris-compute-1.doris-compute.doris.svc.cluster.local:9050,doris-compute-2.doris-compute.doris.svc.cluster.local:9050"
        - name: PRIORITY_NETWORKS
          value: "172.20.0.0/16"
        - name: OBJECT_STORAGE_ENDPOINT
          value: "minio.doris.svc.cluster.local:9000"
        - name: OBJECT_STORAGE_REGION
          value: "us-east-1"
        - name: OBJECT_STORAGE_BUCKET
          value: "doris-data"
        - name: OBJECT_STORAGE_ACCESS_KEY
          value: "minioadmin"
        - name: OBJECT_STORAGE_SECRET_KEY
          value: "minioadmin"
        - name: OBJECT_STORAGE_USE_HTTPS
          value: "false"
        - name: STORAGE_ROOT_PATH
          value: "/mnt/disk1/doris_cloud_cache"
        - name: CACHE_FILE_SIZE
          value: "20"
        - name: CACHE_TTL_SECONDS
          value: "86400"
        volumeMounts:
        - name: cache
          mountPath: /mnt/disk1/doris_cloud_cache
        - name: be-log
          mountPath: /opt/apache-doris/be/log
      volumes:
      - name: cache
        emptyDir:
          sizeLimit: 50Gi
      - name: be-log
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: doris-compute
  namespace: doris
spec:
  clusterIP: None
  selector:
    app: doris
    component: compute
```

## 验证部署

### 1. 检查Pod状态

```bash
kubectl get pods -n doris -o wide
```

### 2. 查看日志

```bash
# FE日志
kubectl logs -n doris doris-fe-0 --tail=50

# 计算节点日志
kubectl logs -n doris doris-compute-0 --tail=50
```

### 3. 测试连接

```bash
# 端口转发
kubectl port-forward -n doris svc/doris-fe 9030:9030

# 另一个终端中连接
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 验证状态
SHOW FRONTENDS;
SHOW BACKENDS;
```

### 4. 功能测试

```sql
-- 创建数据库
CREATE DATABASE test_sep;

-- 使用数据库
USE test_sep;

-- 创建表
CREATE TABLE test_table (
    id BIGINT NOT NULL,
    name VARCHAR(100),
    value DOUBLE
) DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 3;

-- 插入数据
INSERT INTO test_table VALUES (1, 'test1', 100.5);
INSERT INTO test_table VALUES (2, 'test2', 200.5);
INSERT INTO test_table VALUES (3, 'test3', 300.5);

-- 查询数据
SELECT * FROM test_table;
```

## 访问MinIO Console

```bash
# 端口转发MinIO Console
kubectl port-forward -n doris svc/minio 9001:9001
```

然后在浏览器中访问 http://localhost:9001
- 用户名: minioadmin
- 密码: minioadmin

## 清理资源

```bash
# 删除所有资源
kubectl delete -f compute-deployment.yaml -n doris
kubectl delete -f fe-deployment.yaml -n doris
kubectl delete -f minio-service.yaml -n doris
kubectl delete -f minio-deployment.yaml -n doris
kubectl delete -f storage-class.yaml -n doris

# 删除命名空间
kubectl delete namespace doris

# 停止Minikube
minikube stop
```

## 常见问题

### Q: Pod一直处于Pending状态？

A: 检查资源是否足够：
```bash
kubectl describe pod <pod-name> -n doris
```

### Q: 计算节点无法连接MinIO？

A: 检查服务发现：
```bash
kubectl exec -it doris-compute-0 -n doris -- nslookup minio
```

### Q: 存储卷挂载失败？

A: 检查StorageClass配置：
```bash
kubectl get storageclass
kubectl describe storageclass doris-local-storage
```
