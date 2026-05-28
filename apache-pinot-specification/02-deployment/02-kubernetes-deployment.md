# Pinot Kubernetes 生产部署

## 概述

本文档介绍如何在 Kubernetes 上生产级部署 Apache Pinot，包括高可用配置、资源规划、监控和运维。

---

## 1. 架构设计

### 1.1 K8s 部署架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot K8s 生产架构                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Ingress                                   │   │
│  │                                                                  │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │   │
│  │  │   Pinot     │    │   Pinot     │    │   Pinot     │        │   │
│  │  │   Broker    │    │   Broker    │    │   Broker    │        │   │
│  │  │   Service   │    │   Service   │    │   Service   │        │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘        │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                          │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Pinot Namespace                           │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Controller StatefulSet (2-3 replicas)                   │    │   │
│  │  │  - 管理集群元数据                                         │    │   │
│  │  │  - Leader 选举                                            │    │   │
│  │  │  - REST API 服务                                          │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Broker Deployment (2+ replicas)                         │    │   │
│  │  │  - 查询路由                                               │    │   │
│  │  │  - 结果聚合                                               │    │   │
│  │  │  - 无状态，可水平扩展                                     │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Server StatefulSet (3+ replicas)                        │    │   │
│  │  │  - 数据存储                                               │    │   │
│  │  │  - 查询执行                                               │    │   │
│  │  │  - 有状态，使用 PVC                                       │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Minion Deployment (1+ replicas)                         │    │   │
│  │  │  - 后台任务                                               │    │   │
│  │  │  - Segment 合并/压缩                                      │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  ZooKeeper StatefulSet (3-5 replicas)                    │    │   │
│  │  │  - 集群协调                                               │    │   │
│  │  │  - 配置管理                                               │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        存储层                                    │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Deep Storage (S3/GCS/Azure Blob)                        │    │   │
│  │  │  - Segment 备份                                           │    │   │
│  │  │  - 跨可用区恢复                                           │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 资源规划

### 2.1 节点配置建议

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot K8s 资源规划                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  小型集群（开发/测试）                                                   │
│  ─────────────────────────────                                          │
│  ├── Controller：1 副本，1 CPU，2 GB 内存                                │
│  ├── Broker：1 副本，2 CPU，4 GB 内存                                    │
│  ├── Server：2 副本，4 CPU，8 GB 内存，100 GB 存储                       │
│  └── ZooKeeper：1 副本，0.5 CPU，1 GB 内存                               │
│                                                                          │
│  中型集群（生产）                                                        │
│  ─────────────────────────────                                          │
│  ├── Controller：2 副本，2 CPU，4 GB 内存                                │
│  ├── Broker：2 副本，4 CPU，8 GB 内存                                    │
│  ├── Server：3 副本，8 CPU，16 GB 内存，500 GB 存储                      │
│  ├── Minion：1 副本，2 CPU，4 GB 内存                                    │
│  └── ZooKeeper：3 副本，1 CPU，2 GB 内存                                 │
│                                                                          │
│  大型集群（大规模生产）                                                  │
│  ─────────────────────────────                                          │
│  ├── Controller：3 副本，4 CPU，8 GB 内存                                │
│  ├── Broker：3+ 副本，8 CPU，16 GB 内存                                  │
│  ├── Server：5+ 副本，16 CPU，64 GB 内存，2 TB 存储                      │
│  ├── Minion：2 副本，4 CPU，8 GB 内存                                    │
│  └── ZooKeeper：5 副本，2 CPU，4 GB 内存                                 │
│                                                                          │
│  关键建议：                                                              │
│  ─────────────────                                                      │
│  ├── Server 使用 NVMe SSD 存储类                                         │
│  ├── 预留 20% 资源用于峰值                                               │
│  ├── 跨可用区部署                                                        │
│  └── 使用节点亲和性隔离关键组件                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 StorageClass 配置

```yaml
# pinot-ssd-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pinot-ssd
provisioner: kubernetes.io/gce-pd  # GCP
# provisioner: kubernetes.io/aws-ebs  # AWS
# provisioner: kubernetes.io/azure-disk  # Azure
parameters:
  type: pd-ssd  # GCP SSD
  # type: gp3  # AWS
  # storageaccounttype: Premium_LRS  # Azure
  fstype: ext4
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

---

## 3. 部署配置

### 3.1 命名空间和基础资源

```yaml
# 00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: pinot
  labels:
    name: pinot

---
# 01-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pinot-config
  namespace: pinot
data:
  pinot-controller.conf: |
    controller.host=pinot-controller
    controller.port=9000
    controller.data.dir=/var/pinot/controller
    controller.zk.str=zookeeper:2181
  pinot-broker.conf: |
    pinot.broker.client.queryPort=8099
    pinot.broker.routing.table.builder.class=random
  pinot-server.conf: |
    pinot.server.netty.port=8098
    pinot.server.admin.api.port=8097
    pinot.server.instance.dataDir=/var/pinot/server
```

### 3.2 ZooKeeper 部署

```yaml
# 02-zookeeper.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zookeeper
  namespace: pinot
spec:
  serviceName: zookeeper
  replicas: 3
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      containers:
      - name: zookeeper
        image: zookeeper:3.9
        ports:
        - containerPort: 2181
          name: client
        - containerPort: 2888
          name: server
        - containerPort: 3888
          name: election
        env:
        - name: ZOO_MY_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: ZOO_SERVERS
          value: "server.1=zookeeper-0.zookeeper:2888:3888;2181 server.2=zookeeper-1.zookeeper:2888:3888;2181 server.3=zookeeper-2.zookeeper:2888:3888;2181"
        - name: ZOO_TICK_TIME
          value: "2000"
        - name: ZOO_INIT_LIMIT
          value: "5"
        - name: ZOO_SYNC_LIMIT
          value: "2"
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: pinot-ssd
      resources:
        requests:
          storage: 10Gi

---
apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: pinot
spec:
  selector:
    app: zookeeper
  ports:
  - port: 2181
    targetPort: 2181
    name: client
  clusterIP: None
```

### 3.3 Controller 部署

```yaml
# 03-controller.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pinot-controller
  namespace: pinot
spec:
  serviceName: pinot-controller
  replicas: 2
  selector:
    matchLabels:
      app: pinot-controller
  template:
    metadata:
      labels:
        app: pinot-controller
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - pinot-controller
              topologyKey: kubernetes.io/hostname
      containers:
      - name: pinot-controller
        image: apachepinot/pinot:1.0.0
        command: ["StartController"]
        env:
        - name: JAVA_OPTS
          value: "-Xms2G -Xmx2G -XX:+UseG1GC"
        - name: PINOT_ZK_SERVER
          value: "zookeeper:2181"
        - name: PINOT_CONTROLLER_HOST
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        ports:
        - containerPort: 9000
          name: http
        livenessProbe:
          httpGet:
            path: /health
            port: 9000
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 9000
          initialDelaySeconds: 30
          periodSeconds: 5
        volumeMounts:
        - name: data
          mountPath: /var/pinot/controller
        - name: config
          mountPath: /opt/pinot/conf
        resources:
          requests:
            cpu: 2000m
            memory: 4Gi
          limits:
            cpu: 4000m
            memory: 8Gi
      volumes:
      - name: config
        configMap:
          name: pinot-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: pinot-ssd
      resources:
        requests:
          storage: 50Gi

---
apiVersion: v1
kind: Service
metadata:
  name: pinot-controller
  namespace: pinot
spec:
  selector:
    app: pinot-controller
  ports:
  - port: 9000
    targetPort: 9000
    name: http
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pinot-controller
  namespace: pinot
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: pinot-controller.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: pinot-controller
            port:
              number: 9000
```

### 3.4 Broker 部署

```yaml
# 04-broker.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pinot-broker
  namespace: pinot
spec:
  replicas: 2
  selector:
    matchLabels:
      app: pinot-broker
  template:
    metadata:
      labels:
        app: pinot-broker
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - pinot-broker
              topologyKey: kubernetes.io/hostname
      containers:
      - name: pinot-broker
        image: apachepinot/pinot:1.0.0
        command: ["StartBroker"]
        env:
        - name: JAVA_OPTS
          value: "-Xms4G -Xmx4G -XX:+UseG1GC"
        - name: PINOT_ZK_SERVER
          value: "zookeeper:2181"
        ports:
        - containerPort: 8099
          name: query
        livenessProbe:
          httpGet:
            path: /health
            port: 8099
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8099
          initialDelaySeconds: 30
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /opt/pinot/conf
        resources:
          requests:
            cpu: 4000m
            memory: 8Gi
          limits:
            cpu: 8000m
            memory: 16Gi
      volumes:
      - name: config
        configMap:
          name: pinot-config

---
apiVersion: v1
kind: Service
metadata:
  name: pinot-broker
  namespace: pinot
spec:
  selector:
    app: pinot-broker
  ports:
  - port: 8099
    targetPort: 8099
    name: query
  type: ClusterIP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pinot-broker-hpa
  namespace: pinot
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pinot-broker
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 3.5 Server 部署

```yaml
# 05-server.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pinot-server
  namespace: pinot
spec:
  serviceName: pinot-server
  replicas: 3
  selector:
    matchLabels:
      app: pinot-server
  template:
    metadata:
      labels:
        app: pinot-server
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - pinot-server
            topologyKey: kubernetes.io/hostname
      containers:
      - name: pinot-server
        image: apachepinot/pinot:1.0.0
        command: ["StartServer"]
        env:
        - name: JAVA_OPTS
          value: "-Xms8G -Xmx8G -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
        - name: PINOT_ZK_SERVER
          value: "zookeeper:2181"
        ports:
        - containerPort: 8098
          name: netty
        - containerPort: 8097
          name: admin
        livenessProbe:
          httpGet:
            path: /health
            port: 8097
          initialDelaySeconds: 120
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8097
          initialDelaySeconds: 60
          periodSeconds: 5
        volumeMounts:
        - name: data
          mountPath: /var/pinot/server
        - name: config
          mountPath: /opt/pinot/conf
        resources:
          requests:
            cpu: 8000m
            memory: 16Gi
          limits:
            cpu: 16000m
            memory: 32Gi
      volumes:
      - name: config
        configMap:
          name: pinot-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: pinot-ssd
      resources:
        requests:
          storage: 500Gi

---
apiVersion: v1
kind: Service
metadata:
  name: pinot-server
  namespace: pinot
spec:
  selector:
    app: pinot-server
  ports:
  - port: 8098
    targetPort: 8098
    name: netty
  - port: 8097
    targetPort: 8097
    name: admin
  clusterIP: None
```

---

## 4. 生产配置

### 4.1 安全配置

```yaml
# 06-security.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pinot
  namespace: pinot

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pinot
  namespace: pinot
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pinot
  namespace: pinot
subjects:
- kind: ServiceAccount
  name: pinot
  namespace: pinot
roleRef:
  kind: Role
  name: pinot
  apiGroup: rbac.authorization.k8s.io

---
# NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pinot-network-policy
  namespace: pinot
spec:
  podSelector:
    matchLabels:
      app: pinot-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: pinot-broker
    ports:
    - protocol: TCP
      port: 8098
  - from:
    - podSelector:
        matchLabels:
          app: pinot-controller
    ports:
    - protocol: TCP
      port: 8097
```

### 4.2 监控配置

```yaml
# 07-monitoring.yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: pinot-metrics
  namespace: pinot
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: pinot-controller
  endpoints:
  - port: http
    path: /metrics
    interval: 30s

---
# PrometheusRule
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
        description: "P99 查询延迟超过 5 秒"

    - alert: PinotServerDown
      expr: up{job="pinot-server"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pinot Server 宕机"
        description: "Server {{ $labels.instance }} 已宕机"

    - alert: PinotHighMemoryUsage
      expr: (pinot_server_heap_used_bytes / pinot_server_heap_max_bytes) > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pinot Server 内存使用率高"
        description: "内存使用率超过 90%"
```

---

## 5. 运维操作

### 5.1 滚动升级

```bash
# 1. 更新镜像版本
kubectl set image statefulset/pinot-controller \
  pinot-controller=apachepinot/pinot:1.1.0 \
  -n pinot

# 2. 等待滚动升级完成
kubectl rollout status statefulset/pinot-controller -n pinot

# 3. 升级 Broker
kubectl set image deployment/pinot-broker \
  pinot-broker=apachepinot/pinot:1.1.0 \
  -n pinot

# 4. 升级 Server（逐个 Pod 进行）
kubectl set image statefulset/pinot-server \
  pinot-server=apachepinot/pinot:1.1.0 \
  -n pinot
```

### 5.2 扩容操作

```bash
# 扩容 Broker
kubectl scale deployment pinot-broker --replicas=4 -n pinot

# 扩容 Server
kubectl scale statefulset pinot-server --replicas=5 -n pinot

# 扩容存储（需要 StorageClass 支持）
kubectl patch pvc data-pinot-server-0 \
  -n pinot \
  -p '{"spec":{"resources":{"requests":{"storage":"1Ti"}}}}'
```

### 5.3 备份恢复

```bash
# 备份 Segment 元数据
kubectl exec -it pinot-controller-0 -n pinot -- \
  tar czf /tmp/pinot-backup.tar.gz /var/pinot/controller

# 复制到本地
kubectl cp pinot/pinot-controller-0:/tmp/pinot-backup.tar.gz ./pinot-backup.tar.gz

# 备份 Deep Storage 数据
# S3
aws s3 sync s3://my-pinot-bucket/ ./pinot-backup/

# GCS
gsutil -m cp -r gs://my-pinot-bucket/ ./pinot-backup/
```

---

## 6. 性能优化

### 6.1 JVM 调优

```yaml
# JVM 配置
env:
- name: JAVA_OPTS
  value: |
    -Xms16G -Xmx16G
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=200
    -XX:+ParallelRefProcEnabled
    -XX:InitiatingHeapOccupancyPercent=35
    -XX:G1HeapRegionSize=16m
    -XX:+PrintGCDetails
    -XX:+PrintGCDateStamps
    -Xloggc:/var/log/pinot/gc.log
```

### 6.2 操作系统调优

```yaml
# initContainer 进行系统调优
initContainers:
- name: sysctl
  image: busybox
  command:
  - sh
  - -c
  - |
    sysctl -w vm.swappiness=1
    sysctl -w vm.dirty_ratio=40
    sysctl -w vm.dirty_background_ratio=10
    sysctl -w net.core.somaxconn=65535
  securityContext:
    privileged: true
```

---

## 参考链接

- [Pinot Kubernetes 部署](https://docs.pinot.apache.org/basics/getting-started/kubernetes-setup)
- [Pinot Helm Chart](https://github.com/apache/pinot/tree/master/kubernetes/helm)
- [Pinot 生产部署指南](https://docs.pinot.apache.org/operators/tutorials/production-setup)
