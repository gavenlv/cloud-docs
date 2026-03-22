# Pod管理深度解析

## 2.1 Pod原理

### 2.1.1 Pod的核心概念

```
Pod的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Pod是什么？                                             │
└─────────────────────────────────────────────────────────────────┘

Pod是Kubernetes中最小的可部署单元：

1. Pod包含一个或多个容器
   ├── 共享网络命名空间
   ├── 共享存储卷
   ├── 共享进程命名空间
   └── 共享IPC命名空间

2. Pod是短暂的
   ├── 可以被创建和删除
   ├── 可以被重新调度
   ├── IP地址会变化
   └── 不保证持久性

3. Pod是调度的基本单位
   ├── Scheduler调度Pod到节点
   ├── 考虑Pod的资源需求
   ├── 考虑Pod的约束条件
   └── 考虑Pod的亲和性

Pod的设计理念：

1. 单容器Pod
   ├── 最常见的使用场景
   ├── 一个容器运行一个应用
   ├── 简单直接
   └── 易于管理

2. 多容器Pod
   ├── 容器间紧密协作
   ├── 共享网络和存储
   ├── 生命周期同步
   └── 需要精心设计

多容器Pod的使用场景：

1. Sidecar容器
   ├── 主容器：应用容器
   ├── Sidecar容器：辅助容器
   ├── 例如：日志收集、监控代理
   └── 例如：配置管理、证书管理

2. Ambassador容器
   ├── 主容器：应用容器
   ├── Ambassador容器：代理容器
   ├── 例如：数据库代理、缓存代理
   └── 例如：API网关、负载均衡

3. Adapter容器
   ├── 主容器：应用容器
   ├── Adapter容器：适配器容器
   ├── 例如：日志格式转换
   └── 例如：监控指标转换
```

### 2.1.2 Pod生命周期

```
Pod生命周期：

┌─────────────────────────────────────────────────────────────────┐
│  Pod生命周期状态机                                        │
└─────────────────────────────────────────────────────────────────┘

Pod状态机：

┌──────────────┐
│   Pending    │  ← Pod已创建，但容器还未启动
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Running    │  ← Pod中至少有一个容器正在运行
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  Succeeded   │  ← Pod中所有容器都成功终止
└──────────────┘

┌──────────────┐
│    Failed    │  ← Pod中至少有一个容器失败终止
└──────────────┘

┌──────────────┐
│  Unknown     │  ← 无法获取Pod状态（网络问题等）
└──────────────┘

Pod生命周期阶段：

1. Pending（挂起）
   ├── Pod已创建
   ├── 容器镜像正在拉取
   ├── 容器正在创建
   └── 容器还未启动

2. Running（运行中）
   ├── Pod已绑定到节点
   ├── 所有容器都已创建
   ├── 至少有一个容器正在运行
   └── 可能正在重启

3. Succeeded（成功）
   ├── Pod中所有容器都已成功终止
   ├── 不会重启
   └── 通常用于一次性任务

4. Failed（失败）
   ├── Pod中至少有一个容器失败终止
   ├── 所有容器都已终止
   └── 至少有一个容器退出码非0

5. Unknown（未知）
   ├── 无法获取Pod状态
   ├── 通常是网络问题
   ├── 节点可能失联
   └── 需要人工介入

容器状态：

1. Waiting（等待）
   ├── 容器正在启动
   ├── 镜像正在拉取
   ├── 正在执行启动命令
   └── 等待条件满足

2. Running（运行中）
   ├── 容器正在运行
   ├── 没有遇到问题
   ├── 可以处理请求
   └── 正常运行状态

3. Terminated（已终止）
   ├── 容器已停止
   ├── 可能是正常终止
   ├── 可能是异常终止
   └── 退出码指示原因

Pod重启策略：

1. Always（总是重启）
   ├── 容器退出后总是重启
   ├── 适用于长期运行的服务
   ├── 例如：Web服务器
   └── 默认策略

2. OnFailure（失败时重启）
   ├── 容器异常退出时重启
   ├── 正常退出不重启
   ├── 适用于任务型应用
   └── 例如：批处理任务

3. Never（从不重启）
   ├── 容器退出后不重启
   ├── 适用于一次性任务
   ├── 例如：初始化任务
   └── 例如：清理任务
```

### 2.1.3 Pod资源管理

```
Pod资源管理：

┌─────────────────────────────────────────────────────────────────┐
│  Pod资源请求和限制                                        │
└─────────────────────────────────────────────────────────────────┘

资源请求（Request）：

1. CPU请求
   ├── Pod请求的最小CPU资源
   ├── Scheduler调度时考虑
   ├── 保证Pod能获得至少这么多CPU
   └── 单位：m（毫核，1000m = 1核）

2. 内存请求
   ├── Pod请求的最小内存资源
   ├── Scheduler调度时考虑
   ├── 保证Pod能获得至少这么多内存
   └── 单位：Mi、Gi等

资源限制（Limit）：

1. CPU限制
   ├── Pod允许使用的最大CPU资源
   ├── 超过限制会被限制
   ├── 不会杀死Pod
   └── 单位：m（毫核，1000m = 1核）

2. 内存限制
   ├── Pod允许使用的最大内存资源
   ├── 超过限制会被OOM杀死
   ├── Pod会被重启
   └── 单位：Mi、Gi等

QoS（服务质量）：

1. Guaranteed（保证）
   ├── CPU和内存都设置了Request和Limit
   ├── Request == Limit
   ├── 优先级最高
   └── 资源不足时最后被杀死

2. Burstable（突发）
   ├── CPU或内存设置了Request和Limit
   ├── Request != Limit
   ├── 优先级中等
   └── 资源不足时可能被杀死

3. BestEffort（尽力而为）
   ├── CPU和内存都没有设置Request和Limit
   ├── 优先级最低
   ├── 资源不足时首先被杀死
   └── 不保证资源
```

---

## 2.2 Pod配置

### 2.2.1 Pod基本配置

```yaml
# pod-basic.yaml

# Kubernetes API 版本 - 核心API组
# 可选值: v1
apiVersion: v1

# 资源类型 - Pod是最基本的调度单位
# 可选值: Pod, Service, Deployment, etc.
kind: Pod

# 元数据 - 用于标识和组织资源
metadata:
  # Pod名称 - 在namespace内必须唯一
  # 命名规范: 小写字母、数字、连字符(-)
  name: nginx-pod

  # 所属namespace - 用于资源隔离
  # 可选值: default, kube-system, 或自定义namespace
  namespace: default

  # 标签 - 用于资源选择和分组
  # 格式: key:value, key可包含字母、数字、-、_、.
  labels:
    # 应用标签
    # 示例: app: nginx, web, frontend
    app: nginx

    # 环境标签
    # 可选值: dev, test, staging, production
    environment: production

  # 注解 - 存储非标识信息
  # 与labels的区别: 注解不能用于选择资源
  annotations:
    # 描述信息 - 自由格式文本
    description: "Nginx web server"

# 规格说明 - 定义Pod的具体配置
spec:
  # 容器列表 - Pod可以包含一个或多个容器
  # 通常只放一个主容器(边车模式可以有多个)
  containers:
    # 第一个容器配置
    - # 容器名称 - 在Pod内必须唯一
      # 命名规范: 小写字母、数字、连字符
      name: nginx

      # 容器镜像
      # 格式: 镜像:标签 或 镜像@sha256:摘要
      # 可选值:
      #   - nginx:1.25.0 (指定版本)
      #   - nginx:latest (最新版本)
      #   - nginx:alpine (轻量版本)
      image: nginx:1.25.0

      # 端口配置
      ports:
        # 端口列表
        - # 容器端口 - Pod内部监听的端口
          # 可选值: 1-65535
          containerPort: 80

          # 协议类型
          # 可选值: TCP, UDP, SCTP
          protocol: TCP

      # 资源限制 - CPU和内存的请求/限制
      resources:
        # 请求 - 调度时需要的最小资源
        requests:
          # CPU请求 - Kubernetes调度器使用
          # 格式: 核心数 或 毫核(m)
          # 可选值:
          #   - 100m = 0.1核
          #   - 500m = 0.5核
          #   - 1 = 1核
          cpu: 100m

          # 内存请求
          # 格式: Gi, Mi, Ki
          # 可选值:
          #   - 128Mi = 128兆字节
          #   - 256Mi = 256兆字节
          #   - 512Mi = 512兆字节
          memory: 128Mi

        # 限制 - 容器可以使用的最大资源
        limits:
          # CPU限制 - 超过可能被限制
          cpu: 500m

          # 内存限制 - 超过会被OOM Kill
          memory: 512Mi

      # 环境变量 - 传递给容器的键值对
      env:
        # 环境变量列表
        - # 变量名称
          name: ENVIRONMENT

          # 变量值
          value: "production"

        - name: LOG_LEVEL
          value: "info"

      # 卷挂载 - 将存储挂载到容器
      volumeMounts:
        # 挂载配置
        - # 卷名称 - 引用spec.volumes中定义的卷
          name: nginx-config

          # 挂载路径 - 容器内的目标路径
          mountPath: /etc/nginx/nginx.conf

          # 子路径 - 只挂载卷中的特定文件
          subPath: nginx.conf

        - name: nginx-logs
          mountPath: /var/log/nginx

      # 存活探针 - 检测容器是否存活
      # 失败会重启容器
      livenessProbe:
        # HTTP GET探测
        httpGet:
          # 探测路径
          path: /
          # 探测端口 (端口号或端口名称)
          port: 80

        # 初始化延迟 - 容器启动后多久开始探测
        initialDelaySeconds: 30

        # 探测间隔 - 每次探测的间隔
        periodSeconds: 10

        # 超时时间
        timeoutSeconds: 5

        # 成功阈值 - 连续成功次数才算成功
        successThreshold: 1

        # 失败阈值 - 连续失败次数后重启
        failureThreshold: 3

      # 就绪探针 - 检测是否可以接收流量
      # 失败会从Service中移除
      readinessProbe:
        httpGet:
          path: /
          port: 80

        initialDelaySeconds: 10
        periodSeconds: 5
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 3

      # 启动探针 - 容器启动期间的探测
      # 成功后才开始存活和就绪探针
      startupProbe:
        httpGet:
          path: /
          port: 80

        initialDelaySeconds: 0
        periodSeconds: 10
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 30

  # 重启策略 - 容器终止后的行为
  # 可选值:
  #   - Always: 总是重启 (默认)
  #   - OnFailure: 仅在失败时重启
  #   - Never: 从不重启
  restartPolicy: Always

  # 优雅终止期限 - 发送SIGTERM后的等待时间
  # 到达后发送SIGKILL
  terminationGracePeriodSeconds: 30

  # DNS策略
  # 可选值:
  #   - ClusterFirst: 使用集群DNS (默认)
  #   - Default: 使用节点DNS
  #   - ClusterFirstWithHostNet: 使用集群DNS但使用宿主机网络
  #   - None: 允许自定义DNS配置
  dnsPolicy: ClusterFirst

  # 是否使用宿主机网络
  # 可选值: true, false
  # true时Pod不使用网络命名空间
  hostNetwork: false

  # 卷定义 - 供volumeMounts引用
  volumes:
    # 卷1: ConfigMap卷
    - # 卷名称
      name: nginx-config

      # ConfigMap卷类型
      configMap:
        # ConfigMap名称 - 必须已存在
        name: nginx-config

    # 卷2: 空目录卷 - 临时存储
    - name: nginx-logs

      # 空目录类型 - 临时存储
      emptyDir: {}
```

### 2.2.2 多容器Pod配置

```yaml
# pod-multi-container.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
  namespace: default
  labels:
    app: web-app
    environment: production
spec:
  containers:
  - name: web-app
    image: nginx:1.25.0
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/nginx
  - name: log-collector
    image: fluent/fluentd:v1.16-1
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 256Mi
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/nginx
      readOnly: true
    - name: fluentd-config
      mountPath: /fluentd/etc/fluent.conf
      subPath: fluent.conf
  - name: metrics-exporter
    image: prom/node-exporter:v1.6.0
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 256Mi
    ports:
    - containerPort: 9100
      protocol: TCP
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
  volumes:
  - name: app-logs
    emptyDir: {}
  - name: fluentd-config
    configMap:
      name: fluentd-config
```

### 2.2.3 Pod资源限制配置

```yaml
# pod-resources.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limited-pod
  namespace: default
  labels:
    app: resource-limited
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
        ephemeral-storage: 1Gi
      limits:
        cpu: 500m
        memory: 512Mi
        ephemeral-storage: 2Gi
  - name: sidecar
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
        ephemeral-storage: 512Mi
      limits:
        cpu: 200m
        memory: 256Mi
        ephemeral-storage: 1Gi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
```

### 2.2.4 Pod健康检查配置

```yaml
# pod-health-checks.yaml
apiVersion: v1
kind: Pod
metadata:
  name: health-check-pod
  namespace: default
  labels:
    app: health-check
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /health
        port: 80
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      successThreshold: 1
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
    startupProbe:
      httpGet:
        path: /startup
        port: 80
      initialDelaySeconds: 0
      periodSeconds: 10
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 30
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
```

---

## 2.3 Pod调度

### 2.3.1 节点选择器

```yaml
# pod-node-selector.yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-selector-pod
  namespace: default
  labels:
    app: node-selector
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
  nodeSelector:
    disktype: ssd
    zone: us-west-1a
```

### 2.3.2 节点亲和性

```yaml
# pod-node-affinity.yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-affinity-pod
  namespace: default
  labels:
    app: node-affinity
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
          - key: zone
            operator: In
            values:
            - us-west-1a
            - us-west-1b
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: node-type
            operator: In
            values:
            - high-performance
      - weight: 50
        preference:
          matchExpressions:
          - key: gpu
            operator: Exists
```

### 2.3.3 Pod亲和性和反亲和性

```yaml
# pod-pod-affinity.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-affinity-pod
  namespace: default
  labels:
    app: pod-affinity
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - web-app
        topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - cache
          topologyKey: zone
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - database
        topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - web-app
          topologyKey: zone
```

### 2.3.4 污点和容忍度

```yaml
# pod-taint-toleration.yaml
apiVersion: v1
kind: Pod
metadata:
  name: taint-toleration-pod
  namespace: default
  labels:
    app: taint-toleration
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  terminationGracePeriodSeconds: 30
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
  - key: "gpu"
    operator: "Exists"
    effect: "NoExecute"
    tolerationSeconds: 300
  - key: "special-node"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
```

---

## 2.4 Pod实战

### 2.4.1 创建Pod

```bash
# 创建Pod
kubectl apply -f pod-basic.yaml

# 输出：
# pod/nginx-pod created

# 查看Pod
kubectl get pods

# 输出：
# NAME        READY   STATUS    RESTARTS   AGE
# nginx-pod   1/1     Running   0          10s

# 查看Pod详细信息
kubectl describe pod nginx-pod

# 输出：
# Name:         nginx-pod
# Namespace:    default
# Priority:     0
# Node:         minikube/192.168.49.2
# Start Time:   Mon, 15 Jan 2024 10:00:00 +0000
# Labels:       app=nginx
#               environment=production
# Annotations:  description: Nginx web server
# Status:       Running
# IP:           10.244.0.5
# IPs:
#   IP:  10.244.0.5
# Containers:
#   nginx:
#     Container ID:   docker://abc123def456
#     Image:          nginx:1.25.0
#     Image ID:       docker-pullable://nginx@sha256:01234567890abcdef
#     Port:           80/TCP
#     Host Port:      0/TCP
#     State:          Running
#       Started:      Mon, 15 Jan 2024 10:00:05 +0000
#     Ready:          True
#     Restart Count:  0
#     Limits:
#       cpu:     500m
#       memory:  512Mi
#     Requests:
#       cpu:        100m
#       memory:     128Mi
#     Environment:
#       ENVIRONMENT:  production
#       LOG_LEVEL:    info
#     Mounts:
#       /etc/nginx/nginx.conf from nginx-config (rw,path="nginx.conf")
#       /var/log/nginx from nginx-logs (rw)
# Conditions:
#   Type              Status
#   Initialized       True
#   Ready             True
#   ContainersReady   True
#   PodScheduled      True
# Volumes:
#   nginx-config:
#     Type:      ConfigMap (a volume populated by a ConfigMap)
#     Name:      nginx-config
#   nginx-logs:
#     Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
#     Medium:     Memory
#     SizeLimit:  <unset>
# QoS Class:       Burstable
# Node-Selectors:  <none>
# Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
#                  node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
# Events:
#   Type    Reason     Age   From               Message
#   ----    ------     ----  ----               -------
#   Normal  Scheduled  10s   default-scheduler  Successfully assigned default/nginx-pod to minikube
#   Normal  Pulling    8s    kubelet            Pulling image "nginx:1.25.0"
#   Normal  Pulled     5s    kubelet            Successfully pulled image "nginx:1.25.0" in 3.001234s
#   Normal  Created    5s    kubelet            Created container nginx
#   Normal  Started    5s    kubelet            Started container nginx

# 查看Pod日志
kubectl logs nginx-pod

# 输出：
# 2024/01/15 10:00:05 [notice] 1#1: using the "epoll" event method
# 2024/01/15 10:00:05 [notice] 1#1: nginx/1.25.0
# 2024/01/15 10:00:05 [notice] 1#1: OS: Linux 5.15.0-72-generic
# 2024/01/15 10:00:05 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
# 2024/01/15 10:00:05 [notice] 1#1: start worker processes
# 2024/01/15 10:00:05 [notice] 1#1: start worker process 1
```

### 2.4.2 进入Pod

```bash
# 进入Pod
kubectl exec -it nginx-pod -- /bin/bash

# 输出：
# root@nginx-pod:/#

# 在Pod中执行命令
kubectl exec nginx-pod -- ls -la /var/log/nginx

# 输出：
# total 8
# drwxrwxrwx 2 root root 4096 Jan 15 10:00 .
# drwxr-xr-x 1 root root 4096 Jan 15 10:00 ..
# -rw-r--r-- 1 root root    0 Jan 15 10:00 access.log
# -rw-r--r-- 1 root root    0 Jan 15 10:00 error.log

# 查看Pod资源使用情况
kubectl top pod nginx-pod

# 输出：
# NAME        CPU(cores)   MEMORY(bytes)
# nginx-pod   10m          32Mi
```

### 2.4.3 删除Pod

```bash
# 删除Pod
kubectl delete pod nginx-pod

# 输出：
# pod "nginx-pod" deleted

# 查看Pod
kubectl get pods

# 输出：
# NAME        READY   STATUS        RESTARTS   AGE
# nginx-pod   0/1     Terminating   0          1m

# 等待Pod删除完成
kubectl get pods

# 输出：
# No resources found in default namespace.
```

### 2.4.4 Pod故障排查

```bash
# 查看Pod状态
kubectl get pods

# 输出：
# NAME        READY   STATUS             RESTARTS   AGE
# nginx-pod   0/1     CrashLoopBackOff   5          5m

# 查看Pod详细信息
kubectl describe pod nginx-pod

# 输出：
# Name:         nginx-pod
# Namespace:    default
# Priority:     0
# Node:         minikube/192.168.49.2
# Start Time:   Mon, 15 Jan 2024 10:00:00 +0000
# Labels:       app=nginx
#               environment=production
# Annotations:  description: Nginx web server
# Status:       Running
# IP:           10.244.0.5
# IPs:
#   IP:  10.244.0.5
# Containers:
#   nginx:
#     Container ID:   docker://abc123def456
#     Image:          nginx:1.25.0
#     Image ID:       docker-pullable://nginx@sha256:01234567890abcdef
#     Port:           80/TCP
#     Host Port:      0/TCP
#     State:          Waiting
#       Reason:       CrashLoopBackOff
#     Last State:     Terminated
#       Reason:       Error
#       Exit Code:    1
#       Started:      Mon, 15 Jan 2024 10:05:00 +0000
#       Finished:     Mon, 15 Jan 2024 10:05:05 +0000
#     Ready:          False
#     Restart Count:  5
#     Limits:
#       cpu:     500m
#       memory:  512Mi
#     Requests:
#       cpu:        100m
#       memory:     128Mi
#     Environment:
#       ENVIRONMENT:  production
#       LOG_LEVEL:    info
#     Mounts:
#       /etc/nginx/nginx.conf from nginx-config (rw,path="nginx.conf")
#       /var/log/nginx from nginx-logs (rw)
# Conditions:
#   Type              Status
#   Initialized       True
#   Ready             False
#   ContainersReady   False
#   PodScheduled      True
# Volumes:
#   nginx-config:
#     Type:      ConfigMap (a volume populated by a ConfigMap)
#     Name:      nginx-config
#   nginx-logs:
#     Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
#     Medium:     Memory
#     SizeLimit:  <unset>
# QoS Class:       Burstable
# Node-Selectors:  <none>
# Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
#                  node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
# Events:
#   Type     Reason     Age                From               Message
#   ----     ------     ----               ----               -------
#   Normal   Scheduled  5m                 default-scheduler  Successfully assigned default/nginx-pod to minikube
#   Normal   Pulling    4m                 kubelet            Pulling image "nginx:1.25.0"
#   Normal   Pulled     3m                 kubelet            Successfully pulled image "nginx:1.25.0" in 30.123456s
#   Normal   Created    3m                 kubelet            Created container nginx
#   Normal   Started    3m                 kubelet            Started container nginx
#   Warning  Unhealthy  2m                 kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
#   Normal   Killing    2m                 kubelet            Container nginx failed liveness probe, will be restarted
#   Warning  Unhealthy  1m                 kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
#   Normal   Killing    1m                 kubelet            Container nginx failed liveness probe, will be restarted
#   Warning  Unhealthy  30s                kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
#   Normal   Killing    30s                kubelet            Container nginx failed liveness probe, will be restarted

# 查看Pod日志
kubectl logs nginx-pod --previous

# 输出：
# 2024/01/15 10:00:05 [error] 1#1: *1 directory index of "/var/www/html/" is forbidden
# 2024/01/15 10:00:05 [error] 1#1: *1 directory index of "/var/www/html/" is forbidden
```

---

## 本章小结

- Pod是Kubernetes中最小的可部署单元
- Pod包含一个或多个容器，共享网络和存储
- Pod是短暂的，可以被创建和删除
- Pod生命周期包括Pending、Running、Succeeded、Failed、Unknown状态
- Pod重启策略包括Always、OnFailure、Never
- Pod资源管理包括Request和Limit
- QoS包括Guaranteed、Burstable、BestEffort
- Pod调度包括节点选择器、节点亲和性、Pod亲和性和反亲和性、污点和容忍度
- Pod健康检查包括Liveness Probe、Readiness Probe、Startup Probe
- 可以使用kubectl创建、查看、进入、删除Pod
- 可以使用kubectl describe和kubectl logs进行故障排查

---

**下一章：Deployment和ReplicaSet**
