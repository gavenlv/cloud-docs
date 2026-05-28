# Pinot 云平台部署

## 概述

本文档介绍如何在主流云平台上部署 Apache Pinot，包括 GCP、AWS 和 Azure。

---

## 1. GCP 部署

### 1.1 GKE 部署

```bash
# 创建 GKE 集群
gcloud container clusters create pinot-cluster \
  --zone us-central1-a \
  --num-nodes 5 \
  --machine-type n2-standard-8 \
  --disk-type pd-ssd \
  --disk-size 500GB \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10

# 获取集群凭证
gcloud container clusters get-credentials pinot-cluster --zone us-central1-a

# 创建 StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pinot-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  fstype: ext4
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

# 部署 Pinot（使用 Helm）
helm repo add pinot https://raw.githubusercontent.com/apache/pinot/master/kubernetes/helm
helm install pinot pinot/pinot \
  --namespace pinot \
  --create-namespace \
  --set server.persistence.storageClass=pinot-ssd \
  --set server.persistence.size=500Gi
```

### 1.2 GCP 托管服务集成

```yaml
# 使用 Cloud Storage 作为 Deep Storage
apiVersion: v1
kind: Secret
metadata:
  name: gcp-credentials
  namespace: pinot
type: Opaque
stringData:
  key.json: |
    {
      "type": "service_account",
      "project_id": "my-project",
      "private_key_id": "...",
      "private_key": "...",
      "client_email": "pinot@my-project.iam.gserviceaccount.com",
      "client_id": "...",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token"
    }

---
# pinot-gcs-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pinot-gcs-config
  namespace: pinot
data:
  pinot-controller.conf: |
    controller.data.dir=gs://my-pinot-bucket/controller
    controller.local.temp.dir=/tmp/pinot-controller
    pinot.controller.storage.factory.class=org.apache.pinot.plugin.filesystem.GcsPinotFS
    pinot.controller.storage.factory.gcs.projectId=my-project
    pinot.controller.storage.factory.gcs.gcpKey=/etc/gcp/key.json
  pinot-server.conf: |
    pinot.server.instance.dataDir=/var/pinot/server
    pinot.server.instance.segmentTarDir=/var/pinot/server/tar
```

### 1.3 使用 Pub/Sub 作为流数据源

```json
{
  "tableName": "events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "3"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP"
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "pubsub",
        "stream.pubsub.project.id": "my-project",
        "stream.pubsub.topic.name": "events-topic",
        "stream.pubsub.sub.name": "events-subscription",
        "stream.pubsub.creds.file": "/etc/gcp/key.json",
        "stream.pubsub.decoder.class.name": "org.apache.pinot.plugin.inputformat.json.JSONMessageDecoder"
      }
    ]
  }
}
```

---

## 2. AWS 部署

### 2.1 EKS 部署

```bash
# 创建 EKS 集群
eksctl create cluster \
  --name pinot-cluster \
  --region us-west-2 \
  --node-type m5.2xlarge \
  --nodes 5 \
  --nodes-min 3 \
  --nodes-max 10 \
  --managed \
  --node-volume-type gp3 \
  --node-volume-size 500

# 配置 kubectl
aws eks update-kubeconfig --region us-west-2 --name pinot-cluster

# 创建 StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pinot-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  encrypted: "true"
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### 2.2 S3 集成

```yaml
# 使用 S3 作为 Deep Storage
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: pinot
type: Opaque
stringData:
  access-key: AKIA...
  secret-key: ...

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pinot-s3-config
  namespace: pinot
data:
  pinot-controller.conf: |
    controller.data.dir=s3://my-pinot-bucket/controller
    pinot.controller.storage.factory.class=org.apache.pinot.plugin.filesystem.S3PinotFS
    pinot.controller.storage.factory.s3.region=us-west-2
    pinot.controller.storage.factory.s3.accessKey=${AWS_ACCESS_KEY_ID}
    pinot.controller.storage.factory.s3.secretKey=${AWS_SECRET_ACCESS_KEY}
```

### 2.3 Kinesis 集成

```json
{
  "tableName": "events",
  "tableType": "REALTIME",
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "kinesis",
        "stream.kinesis.topic.name": "events-stream",
        "stream.kinesis.decoder.class.name": "org.apache.pinot.plugin.inputformat.json.JSONMessageDecoder",
        "stream.kinesis.consumer.factory.class.name": "org.apache.pinot.plugin.stream.kinesis.KinesisConsumerFactory",
        "stream.kinesis.aws.region": "us-west-2",
        "stream.kinesis.aws.accessKey": "${AWS_ACCESS_KEY_ID}",
        "stream.kinesis.aws.secretKey": "${AWS_SECRET_ACCESS_KEY}"
      }
    ]
  }
}
```

---

## 3. Azure 部署

### 3.1 AKS 部署

```bash
# 创建 AKS 集群
az aks create \
  --resource-group myResourceGroup \
  --name pinot-cluster \
  --node-count 5 \
  --node-vm-size Standard_D8s_v3 \
  --node-osdisk-type Premium_LRS \
  --node-osdisk-size 500 \
  --enable-cluster-autoscaler \
  --min-count 3 \
  --max-count 10

# 获取集群凭证
az aks get-credentials --resource-group myResourceGroup --name pinot-cluster

# 创建 StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pinot-ssd
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

### 3.2 Azure Blob 集成

```yaml
# 使用 Azure Blob 作为 Deep Storage
apiVersion: v1
kind: Secret
metadata:
  name: azure-credentials
  namespace: pinot
type: Opaque
stringData:
  account-name: mystorageaccount
  account-key: ...

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pinot-azure-config
  namespace: pinot
data:
  pinot-controller.conf: |
    controller.data.dir=abfs://pinot@mystorageaccount.dfs.core.windows.net/
    pinot.controller.storage.factory.class=org.apache.pinot.plugin.filesystem.AzurePinotFS
    pinot.controller.storage.factory.azure.account.name=mystorageaccount
    pinot.controller.storage.factory.azure.account.key=${AZURE_STORAGE_KEY}
```

---

## 4. 多云通用配置

### 4.1 外部访问配置

```yaml
# Ingress 配置（通用）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pinot-ingress
  namespace: pinot
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - pinot.example.com
    secretName: pinot-tls
  rules:
  - host: pinot.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pinot-broker
            port:
              number: 8099
```

### 4.2 监控集成

```yaml
# 通用监控配置
apiVersion: v1
kind: ConfigMap
metadata:
  name: pinot-monitoring
  namespace: pinot
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'pinot-controller'
      static_configs:
      - targets: ['pinot-controller:9000']
      metrics_path: /metrics
    - job_name: 'pinot-broker'
      static_configs:
      - targets: ['pinot-broker:8099']
      metrics_path: /metrics
    - job_name: 'pinot-server'
      static_configs:
      - targets: ['pinot-server:8097']
      metrics_path: /metrics
```

---

## 参考链接

- [Pinot Cloud Deployment](https://docs.pinot.apache.org/basics/getting-started/cloud-setup)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
