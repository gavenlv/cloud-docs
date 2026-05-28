# Pinot 与 GCP 集成

## 概述

本文档介绍 Apache Pinot 与 Google Cloud Platform (GCP) 的集成，包括 GKE 部署、Cloud Storage、Pub/Sub 和 BigQuery 集成。

---

## 1. GKE 部署

### 1.1 创建 GKE 集群

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
  --max-nodes 10 \
  --enable-network-policy \
  --enable-shielded-nodes

# 获取集群凭证
gcloud container clusters get-credentials pinot-cluster --zone us-central1-a

# 创建命名空间
kubectl create namespace pinot
```

### 1.2 配置 Workload Identity

```bash
# 创建 Google Service Account
gcloud iam service-accounts create pinot-sa \
  --display-name="Pinot Service Account"

# 绑定权限
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:pinot-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:pinot-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/pubsub.editor"

# 配置 Workload Identity
gcloud iam service-accounts add-iam-policy-binding \
  pinot-sa@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:PROJECT_ID.svc.id.goog[pinot/pinot-sa]"

# 创建 Kubernetes Service Account
kubectl create serviceaccount pinot-sa \
  --namespace pinot \
  --annotation iam.gke.io/gcp-service-account=pinot-sa@PROJECT_ID.iam.gserviceaccount.com
```

---

## 2. Cloud Storage 集成

### 2.1 配置 Deep Storage

```yaml
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
    pinot.server.storage.factory.class=org.apache.pinot.plugin.filesystem.GcsPinotFS
    pinot.server.storage.factory.gcs.projectId=my-project
```

### 2.2 批量摄入配置

```yaml
# gcs-ingestion-job-spec.yaml
executionFrameworkSpec:
  name: 'standalone'
  segmentGenerationJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentGenerationJobRunner'
  segmentTarPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentTarPushJobRunner'

jobType: SegmentCreationAndTarPush
inputDirURI: 'gs://my-bucket/input/'
includeFileNamePattern: 'glob:**/*.parquet'
outputDirURI: 'gs://my-bucket/output/'
overwriteOutput: true

pinotFSSpecs:
  - scheme: gs
    className: org.apache.pinot.plugin.filesystem.GcsPinotFS
    configs:
      projectId: my-project
      gcpKey: /etc/gcp/service-account-key.json

recordReaderSpec:
  dataFormat: 'parquet'
  className: 'org.apache.pinot.plugin.inputformat.parquet.ParquetRecordReader'

tableSpec:
  tableName: 'events'
  schemaURI: 'http://pinot-controller:9000/schemas/events'
  tableConfigURI: 'http://pinot-controller:9000/tables/events'

pinotClusterSpecs:
  - controllerURI: 'http://pinot-controller:9000'
```

---

## 3. Pub/Sub 集成

### 3.1 配置实时摄入

```json
{
  "tableName": "events",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "3"
  },
  "ingestionConfig": {
    "streamConfigMaps": [
      {
        "streamType": "pubsub",
        "stream.pubsub.project.id": "my-project",
        "stream.pubsub.topic.name": "events-topic",
        "stream.pubsub.sub.name": "events-subscription",
        "stream.pubsub.creds.file": "/etc/gcp/service-account-key.json",
        "stream.pubsub.decoder.class.name": "org.apache.pinot.plugin.inputformat.json.JSONMessageDecoder",
        "realtime.segment.flush.threshold.rows": "5000000",
        "realtime.segment.flush.threshold.time": "1h"
      }
    ]
  }
}
```

### 3.2 创建 Pub/Sub 资源

```bash
# 创建 Topic
gcloud pubsub topics create events-topic

# 创建 Subscription
gcloud pubsub subscriptions create events-subscription \
  --topic=events-topic \
  --ack-deadline=60

# 发布测试消息
gcloud pubsub topics publish events-topic \
  --message='{"user_id": "user1", "event_type": "click", "timestamp": 1704067200000}'
```

---

## 4. BigQuery 集成

### 4.1 使用 Trino 联邦查询

```properties
# etc/catalog/bigquery.properties
connector.name=bigquery
bigquery.project-id=my-project
bigquery.credentials-file=/etc/gcp/service-account-key.json
```

```sql
-- 联邦查询：Pinot + BigQuery
SELECT 
  p.country,
  p.realtime_revenue,
  b.historical_revenue
FROM (
  SELECT 
    country,
    SUM(revenue) AS realtime_revenue
  FROM pinot.default.user_events
  WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '1' HOUR
  GROUP BY country
) p
JOIN (
  SELECT 
    country,
    SUM(revenue) AS historical_revenue
  FROM bigquery.my_dataset.daily_revenue
  WHERE dt = CURRENT_DATE - INTERVAL '1' DAY
  GROUP BY country
) b ON p.country = b.country;
```

### 4.2 数据导出到 BigQuery

```bash
# 使用 BigQuery Data Transfer Service
# 或者使用 Spark 作业导出

# Spark 导出示例
spark-submit \
  --class org.apache.pinot.tools.Backfill \
  --master yarn \
  pinot-tools-*.jar \
  -type segmentUriPush \
  -tableName user_events \
  -inputDirURI gs://my-bucket/pinot-segments/ \
  -outputDirURI gs://my-bucket/bigquery-export/ \
  -pushLocation bigquery://my-project:my_dataset.user_events
```

---

## 5. Cloud Monitoring 集成

### 5.1 配置监控

```yaml
# 创建 ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: pinot-metrics
  namespace: pinot
  labels:
    release: prometheus
spec:
  namespaceSelector:
    matchNames:
    - pinot
  selector:
    matchLabels:
      app: pinot-controller
  endpoints:
  - port: http
    path: /metrics
    interval: 15s

---
# 创建告警规则
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: pinot-alerts
  namespace: pinot
spec:
  groups:
  - name: pinot
    rules:
    - alert: PinotHighQueryLatency
      expr: pinot_broker_query_latency_p99 > 5000
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pinot 查询延迟过高"
        description: "Broker {{ $labels.instance }} P99 延迟 {{ $value }}ms"
```

### 5.2 Cloud Logging 集成

```yaml
# 配置 Fluentd 收集日志到 Cloud Logging
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: pinot
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/pinot/*.log
      pos_file /var/log/pinot/fluentd.pos
      tag pinot.*
      <parse>
        @type regexp
        expression /^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<level>\w+) (?<class>[^:]+):(?<line>\d+) - (?<message>.*)$/
      </parse>
    </source>
    
    <match pinot.**>
      @type google_cloud
      project_id my-project
      use_metadata_service true
    </match>
```

---

## 6. 网络配置

### 6.1 私有集群配置

```bash
# 创建私有 GKE 集群
gcloud container clusters create pinot-private-cluster \
  --zone us-central1-a \
  --enable-private-nodes \
  --enable-private-endpoint \
  --master-ipv4-cidr 172.16.0.32/28 \
  --create-subnetwork pinot-subnet \
  --enable-master-authorized-networks \
  --master-authorized-networks=10.0.0.0/8

# 配置 Cloud NAT（出站访问）
gcloud compute routers create pinot-router \
  --network default \
  --region us-central1

gcloud compute routers nats create pinot-nat \
  --router=pinot-router \
  --region=us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges
```

### 6.2 负载均衡配置

```yaml
# 配置 Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pinot-ingress
  namespace: pinot
  annotations:
    kubernetes.io/ingress.class: gce
    kubernetes.io/ingress.global-static-ip-name: pinot-ip
    networking.gke.io/managed-certificates: pinot-cert
spec:
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

---

## 参考链接

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
