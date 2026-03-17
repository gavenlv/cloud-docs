# Kubernetes核心概念

## 本章概述

Kubernetes是容器编排的事实标准。本章将系统学习Kubernetes核心概念和操作实践。

## 学习目标

- 理解Kubernetes架构原理
- 掌握Pod生命周期管理
- 理解Controller工作机制
- 掌握Service与Ingress
- 学会ConfigMap与Secret管理
- 理解持久化存储机制

---

## 1. Kubernetes架构

### 1.1 整体架构

```
Kubernetes集群架构

┌─────────────────────────────────────────────────────────────────────────┐
│                           Control Plane                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ API Server  │  │    etcd     │  │ Scheduler   │  │Controller   │   │
│  │             │  │             │  │             │  │  Manager    │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│      Node 1       │     │      Node 2       │     │      Node 3       │
│  ┌─────────────┐  │     │  ┌─────────────┐  │     │  ┌─────────────┐  │
│  │   kubelet   │  │     │  │   kubelet   │  │     │  │   kubelet   │  │
│  ├─────────────┤  │     │  ├─────────────┤  │     │  ├─────────────┤  │
│  │kube-proxy   │  │     │  │kube-proxy   │  │     │  │kube-proxy   │  │
│  ├─────────────┤  │     │  ├─────────────┤  │     │  ├─────────────┤  │
│  │  Container  │  │     │  │  Container  │  │     │  │  Container  │  │
│  │   Runtime   │  │     │  │   Runtime   │  │     │  │   Runtime   │  │
│  └─────────────┘  │     │  └─────────────┘  │     │  └─────────────┘  │
│  ┌─────┐ ┌─────┐  │     │  ┌─────┐ ┌─────┐  │     │  ┌─────┐ ┌─────┐  │
│  │ Pod │ │ Pod │  │     │  │ Pod │ │ Pod │  │     │  │ Pod │ │ Pod │  │
│  └─────┘ └─────┘  │     │  └─────┘ └─────┘  │     │  └─────┘ └─────┘  │
└───────────────────┘     └───────────────────┘     └───────────────────┘
```

### 1.2 控制平面组件

| 组件 | 功能 |
|-----|------|
| API Server | 集群统一入口，RESTful API |
| etcd | 分布式键值存储，保存集群状态 |
| Scheduler | 负责Pod调度到Node |
| Controller Manager | 维护集群状态，执行控制循环 |
| Cloud Controller Manager | 云服务商特定控制器 |

### 1.3 节点组件

| 组件 | 功能 |
|-----|------|
| kubelet | 节点代理，管理Pod生命周期 |
| kube-proxy | 网络代理，实现Service |
| Container Runtime | 容器运行时（containerd、CRI-O） |

---

## 2. Pod生命周期

### 2.1 Pod结构

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
    version: v1
  annotations:
    description: "My application pod"
spec:
  containers:
  - name: app
    image: my-app:1.0
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m"
    env:
    - name: ENV
      value: "production"
    volumeMounts:
    - name: data
      mountPath: /data
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
  - name: sidecar
    image: log-collector:1.0
    volumeMounts:
    - name: logs
      mountPath: /var/log
  volumes:
  - name: data
    emptyDir: {}
  - name: logs
    emptyDir: {}
  initContainers:
  - name: init
    image: busybox
    command: ['sh', '-c', 'echo "Initializing..."']
```

### 2.2 Pod生命周期阶段

```
Pod生命周期

┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Pending │────►│ Running │────►│Succeeded│     │ Failed  │
└─────────┘     └────┬────┘     └─────────┘     └─────────┘
                     │
                     │
                ┌────┴────┐
                │ Unknown │
                └─────────┘

Pending:    Pod已创建，等待调度
Running:    Pod已调度，至少一个容器运行
Succeeded:  所有容器成功终止
Failed:     所有容器终止，至少一个失败
Unknown:    无法获取Pod状态
```

### 2.3 容器生命周期

```yaml
spec:
  containers:
  - name: app
    image: my-app:1.0
    
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo 'Post start'"]
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 10"]
```

```
容器启动流程

1. 执行postStart钩子（异步）
2. 启动主进程
3. 执行livenessProbe/readinessProbe
4. 运行中...

容器终止流程

1. 发送SIGTERM信号
2. 执行preStop钩子
3. 等待优雅终止（默认30秒）
4. 发送SIGKILL强制终止
```

### 2.4 探针配置

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
    httpHeaders:
    - name: Custom-Header
      value: value
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30
```

---

## 3. Controller控制器

### 3.1 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

```
Deployment滚动更新

初始状态：
┌─────┐ ┌─────┐ ┌─────┐
│ v1  │ │ v1  │ │ v1  │
└─────┘ └─────┘ └─────┘

更新中（maxSurge=1, maxUnavailable=0）：
┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
│ v1  │ │ v1  │ │ v1  │ │ v2  │
└─────┘ └─────┘ └─────┘ └─────┘

继续更新：
┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐
│ v1  │ │ v1  │ │ v2  │ │ v2  │
└─────┘ └─────┘ └─────┘ └─────┘

完成：
┌─────┐ ┌─────┐ ┌─────┐
│ v2  │ │ v2  │ │ v2  │
└─────┘ └─────┘ └─────┘
```

### 3.2 StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

```
StatefulSet特点

有序部署：
mysql-0 → mysql-1 → mysql-2

稳定网络标识：
mysql-0.mysql-headless.default.svc.cluster.local
mysql-1.mysql-headless.default.svc.cluster.local
mysql-2.mysql-headless.default.svc.cluster.local

持久存储：
PVC与Pod绑定，不会因Pod重建而丢失

有序缩容：
mysql-2 → mysql-1 → mysql-0
```

### 3.3 DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluentd:v1.16
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: dockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### 3.4 Job与CronJob

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  completions: 1
  parallelism: 1
  backoffLimit: 3
  activeDeadlineSeconds: 600
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: migration
        image: migration-tool:1.0
        command: ["python", "migrate.py"]
```

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 2 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: backup-tool:1.0
            command: ["./backup.sh"]
```

---

## 4. Service与Ingress

### 4.1 Service类型

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

```
Service类型对比

ClusterIP (默认)
├── 集群内部访问
└── 适合内部服务

NodePort
├── 通过节点端口暴露
├── 范围：30000-32767
└── 适合测试环境

LoadBalancer
├── 云厂商负载均衡器
├── 自动分配外部IP
└── 适合生产环境

ExternalName
├── 映射外部服务
└── DNS CNAME记录
```

### 4.2 Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-v1
            port:
              number: 80
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: api-v2
            port:
              number: 80
```

---

## 5. ConfigMap与Secret

### 5.1 ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "mysql.default.svc.cluster.local"
  database_port: "3306"
  cache_host: "redis.default.svc.cluster.local"
  config.yaml: |
    server:
      port: 8080
      host: 0.0.0.0
    database:
      host: mysql
      port: 3306
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: my-app:1.0
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    envFrom:
    - configMapRef:
        name: app-config
    volumeMounts:
    - name: config
      mountPath: /etc/config
      readOnly: true
  volumes:
  - name: config
    configMap:
      name: app-config
```

### 5.2 Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  username: admin
  password: supersecret
  connection_string: "mysql://admin:supersecret@mysql:3306/db"
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: my-app:1.0
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    volumeMounts:
    - name: secret
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: db-secret
```

---

## 6. 持久化存储

### 6.1 PV与PVC

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: my-app:1.0
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
```

### 6.2 StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

---

## 7. 实操项目

### 项目：部署完整应用栈

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: myapp
stringData:
  password: mypassword
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: myapp
data:
  DB_HOST: "mysql"
  REDIS_HOST: "redis"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config
---
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: myapp
spec:
  selector:
    app: web
  ports:
  - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: myapp
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

---

## 8. 知识检测

### 选择题

1. Kubernetes默认的Service类型是什么？
   - A. NodePort
   - B. LoadBalancer
   - C. ClusterIP
   - D. ExternalName

2. 哪种Controller适合部署有状态应用？
   - A. Deployment
   - B. StatefulSet
   - C. DaemonSet
   - D. ReplicaSet

3. Pod中哪个探针用于判断容器是否准备好接收流量？
   - A. livenessProbe
   - B. readinessProbe
   - C. startupProbe
   - D. healthProbe

---

## 9. 扩展阅读

- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [Kubernetes概念详解](https://kubernetes.io/docs/concepts/)
- [Kubernetes最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)

---

## 学习进度

- [ ] 理解Kubernetes架构
- [ ] 掌握Pod生命周期
- [ ] 理解Controller机制
- [ ] 掌握Service与Ingress
- [ ] 学会ConfigMap与Secret
- [ ] 理解持久化存储
- [ ] 完成实操项目
