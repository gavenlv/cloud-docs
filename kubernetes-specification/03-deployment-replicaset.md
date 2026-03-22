# Deployment和ReplicaSet深度解析

## 3.1 Deployment原理

### 3.1.1 Deployment的核心概念

```
Deployment的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Deployment是什么？                                   │
└─────────────────────────────────────────────────────────────────┘

Deployment是用于管理无状态应用的控制器：

1. 管理ReplicaSet
   ├── 创建和管理ReplicaSet
   ├── 确保Pod副本数
   ├── 自动扩缩容
   └── 自动故障恢复

2. 滚动更新
   ├── 逐步更新Pod
   ├── 零停机更新
   ├── 支持回滚
   └── 支持暂停和恢复

3. 版本管理
   ├── 保留历史版本
   ├── 支持回滚到任意版本
   ├── 支持查看历史
   └── 支持清理历史

4. 声明式管理
   ├── 声明期望状态
   ├── 自动达到期望状态
   ├── 支持Apply操作
   └── 支持Diff操作

Deployment的优势：

1. 自动化运维
   ├── 自动创建Pod
   ├── 自动删除Pod
   ├── 自动更新Pod
   └── 自动恢复Pod

2. 高可用性
   ├── 确保Pod副本数
   ├── 自动故障恢复
   ├── 自动重新调度
   └── 自动负载均衡

3. 灵活扩展
   ├── 支持水平扩展
   ├── 支持垂直扩展
   ├── 支持自动扩缩容
   └── 支持手动扩缩容

4. 版本控制
   ├── 支持滚动更新
   ├── 支持金丝雀发布
   ├── 支持蓝绿部署
   └── 支持回滚
```

### 3.1.2 ReplicaSet原理

```
ReplicaSet原理：

┌─────────────────────────────────────────────────────────────────┐
│  ReplicaSet是什么？                                 │
└─────────────────────────────────────────────────────────────────┘

ReplicaSet是用于确保Pod副本数的控制器：

1. 确保Pod副本数
   ├── 确保指定数量的Pod运行
   ├── 自动创建缺失的Pod
   ├── 自动删除多余的Pod
   └── 自动恢复失败的Pod

2. 选择器匹配
   ├── 通过标签选择Pod
   ├── 匹配指定标签的Pod
   ├── 管理匹配的Pod
   └── 忽略不匹配的Pod

3. 模板管理
   ├── 定义Pod模板
   ├── 根据模板创建Pod
   ├── 支持模板更新
   └── 支持模板回滚

ReplicaSet与Deployment的关系：

1. Deployment管理ReplicaSet
   ├── Deployment创建ReplicaSet
   ├── Deployment更新ReplicaSet
   ├── Deployment删除ReplicaSet
   └── Deployment回滚ReplicaSet

2. ReplicaSet管理Pod
   ├── ReplicaSet创建Pod
   ├── ReplicaSet删除Pod
   ├── ReplicaSet更新Pod
   └── ReplicaSet恢复Pod

3. 推荐使用Deployment
   ├── Deployment提供更多功能
   ├── Deployment支持滚动更新
   ├── Deployment支持版本管理
   └── Deployment支持回滚
```

### 3.1.3 滚动更新原理

```
滚动更新原理：

┌─────────────────────────────────────────────────────────────────┐
│  滚动更新工作原理                                        │
└─────────────────────────────────────────────────────────────────┘

滚动更新流程：

1. 创建新ReplicaSet
   ├── 基于新Pod模板
   ├── 初始副本数为0
   ├── 等待新Pod就绪
   └── 逐步增加副本数

2. 逐步替换Pod
   ├── 减少旧ReplicaSet副本数
   ├── 增加新ReplicaSet副本数
   ├── 确保Pod总数稳定
   └── 确保服务可用性

3. 完成更新
   ├── 旧ReplicaSet副本数为0
   ├── 新ReplicaSet副本数达到目标
   ├── 删除旧ReplicaSet
   └── 保留历史版本

滚动更新策略：

1. RollingUpdate（滚动更新）
   ├── 逐步替换Pod
   ├── 零停机更新
   ├── 默认策略
   └── 适合无状态应用

2. Recreate（重建）
   ├── 先删除所有Pod
   ├── 再创建新Pod
   ├── 有停机时间
   └── 适合有状态应用

滚动更新参数：

1. maxUnavailable
   ├── 更新期间最多不可用的Pod数量
   ├── 可以是绝对值或百分比
   ├── 默认值：25%
   └── 影响更新速度

2. maxSurge
   ├── 更新期间最多额外的Pod数量
   ├── 可以是绝对值或百分比
   ├── 默认值：25%
   └── 影响资源使用
```

### 3.1.4 回滚原理

```
回滚原理：

┌─────────────────────────────────────────────────────────────────┐
│  回滚工作原理                                            │
└─────────────────────────────────────────────────────────────────┘

回滚流程：

1. 查看历史版本
   ├── 列出所有历史版本
   ├── 显示版本信息
   ├── 显示变更内容
   └── 显示版本时间

2. 选择回滚版本
   ├── 选择要回滚的版本
   ├── 可以指定版本号
   ├── 可以指定版本数量
   └── 可以指定版本时间

3. 执行回滚
   ├── 创建旧ReplicaSet
   ├── 逐步替换Pod
   ├── 完成回滚
   └── 保留新版本历史

回滚策略：

1. 保留历史版本
   ├── 默认保留10个版本
   ├── 可以配置保留数量
   ├── 可以配置保留时间
   └── 可以手动清理历史

2. 回滚到指定版本
   ├── 可以回滚到任意版本
   ├── 可以回滚到上一个版本
   ├── 可以回滚到指定版本号
   └── 可以回滚到指定时间点

3. 回滚后继续更新
   ├── 回滚后可以继续更新
   ├── 回滚后可以再次回滚
   ├── 回滚后可以删除历史
   └── 回滚后可以清理资源
```

---

## 3.2 Deployment配置

### 3.2.1 Deployment基本配置

```yaml
# deployment-basic.yaml

# Kubernetes API 版本 - 应用API组
# 可选值: apps/v1, apps/v1beta1, apps/v1beta2, apps/v2alpha1
apiVersion: apps/v1

# 资源类型 - 无状态工作负载
# 可选值:
#   - Deployment: 无状态应用 (常用)
#   - StatefulSet: 有状态应用
#   - DaemonSet: 每节点一个Pod
#   - ReplicaSet: Deployment的底层副本控制器
kind: Deployment

# 元数据
metadata:
  # Deployment名称 - 在namespace内必须唯一
  name: nginx-deployment

  # 所属namespace
  namespace: default

  # 标签 - 用于分组和选择
  labels:
    # 应用标签
    app: nginx
    # 环境标签
    environment: production

  # 注解 - 非标识信息
  annotations:
    description: "Nginx web server deployment"

# 规格说明
spec:
  # 副本数 - 期望运行的Pod数量
  # 可选值: 正整数
  replicas: 3

  # 选择器 - 识别属于此Deployment的Pod
  # 必须匹配template.metadata.labels
  selector:
    matchLabels:
      # 标签键值对
      app: nginx

  # Pod模板
  template:
    metadata:
      labels:
        # Pod标签 - 会被selector匹配
        app: nginx
        environment: production

    spec:
      # 容器列表
      containers:
        - # 容器名称
          name: nginx

          # 容器镜像
          # 格式: 镜像:标签
          # 可选值:
          #   - nginx:1.25.0 (指定版本)
          #   - nginx:latest (最新)
          #   - nginx:alpine (轻量)
          image: nginx:1.25.0

          # 端口配置
          ports:
            - # 容器端口
              containerPort: 80
              # 协议
              protocol: TCP

          # 资源限制
          resources:
            requests:
              # CPU请求
              # 可选值: 100m, 500m, 1
              cpu: 100m
              # 内存请求
              # 可选值: 128Mi, 256Mi, 512Mi
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi

          # 环境变量
          env:
            - name: ENVIRONMENT
              value: "production"
            - name: LOG_LEVEL
              value: "info"

          # 存活探针
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            successThreshold: 1
            failureThreshold: 3

          # 就绪探针
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 3
            successThreshold: 1
            failureThreshold: 3

      # 重启策略
      # 可选值: Always, OnFailure, Never
      restartPolicy: Always

      # 优雅终止期限
      terminationGracePeriodSeconds: 30

      # DNS策略
      # 可选值: ClusterFirst, Default, ClusterFirstWithHostNet, None
      dnsPolicy: ClusterFirst

  # 更新策略 - 定义如何更新Pod
  strategy:
    # 更新类型
    # 可选值:
    #   - RollingUpdate: 滚动更新 (默认)
    #   - Recreate: 重建更新 - 停止所有旧Pod后再启动新的
    type: RollingUpdate

    # 滚动更新参数
    rollingUpdate:
      # 最大不可用Pod数 - 可以是绝对值或百分比
      # 可选值: 数字, 百分比如25%
      # 示例: 1 或 "25%"
      maxUnavailable: 25%

      # 最大多余Pod数 - 超出期望的Pod数
      # 可选值: 数字, 百分比如25%
      maxSurge: 25%

  # 历史版本保留数 - 用于回滚
  # 可选值: 正整数, 通常设为3-10
  revisionHistoryLimit: 10

  # 进度超时时间 - Deployment完成的最大等待时间
  # 超过后会被标记为失败
  # 可选值: 秒数
  progressDeadlineSeconds: 600
```

### 3.2.2 Deployment滚动更新配置

```yaml
# deployment-rolling-update.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
  labels:
    app: nginx
    environment: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        environment: production
    spec:
      containers:
      - name: nginx
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
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
```

### 3.2.3 Deployment金丝雀发布配置

```yaml
# deployment-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
  labels:
    app: nginx
    environment: production
spec:
  replicas: 4
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
        environment: production
        version: v1
    spec:
      containers:
      - name: nginx
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-canary
  namespace: default
  labels:
    app: nginx
    environment: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
      version: canary
  template:
    metadata:
      labels:
        app: nginx
        environment: production
        version: canary
    spec:
      containers:
      - name: nginx
        image: nginx:1.26.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### 3.2.4 Deployment蓝绿部署配置

```yaml
# deployment-blue-green.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-blue
  namespace: default
  labels:
    app: nginx
    environment: production
    color: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
      color: blue
  template:
    metadata:
      labels:
        app: nginx
        environment: production
        color: blue
    spec:
      containers:
      - name: nginx
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
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-green
  namespace: default
  labels:
    app: nginx
    environment: production
    color: green
spec:
  replicas: 0
  selector:
    matchLabels:
      app: nginx
      color: green
  template:
    metadata:
      labels:
        app: nginx
        environment: production
        color: green
    spec:
      containers:
      - name: nginx
        image: nginx:1.26.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
  labels:
    app: nginx
    environment: production
spec:
  selector:
    app: nginx
    color: blue
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

---

## 3.3 Deployment实战

### 3.3.1 创建Deployment

```bash
# 创建Deployment
kubectl apply -f deployment-basic.yaml

# 输出：
# deployment.apps/nginx-deployment created

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           10s

# 查看Deployment详细信息
kubectl describe deployment nginx-deployment

# 输出：
# Name:                   nginx-deployment
# Namespace:              default
# CreationTimestamp:      Mon, 15 Jan 2024 10:00:00 +0000
# Labels:                 app=nginx
#                         environment=production
# Annotations:            description: Nginx web server deployment
# Selector:               app=nginx
# Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
# StrategyType:           RollingUpdate
# RollingUpdateStrategy:  25% max unavailable, 25% max surge
# Pod Template:
#   Labels:  app=nginx
#            environment=production
#   Containers:
#    nginx:
#     Image:      nginx:1.25.0
#     Port:       80/TCP
#     Host Port:  0/TCP
#     Limits:
#       cpu:     500m
#       memory:  512Mi
#     Requests:
#       cpu:        100m
#       memory:     128Mi
#     Environment:
#       ENVIRONMENT:  production
#       LOG_LEVEL:    info
#     Liveness:     http-get http://:80/ delay=30s timeout=5s period=10s #success=1 #failure=3
#     Readiness:    http-get http://:80/ delay=10s timeout=3s period=5s #success=1 #failure=3
#     Environment Variables from:
#       (none)
#     Mounts:        <none>
#   Volumes:         <none>
# Conditions:
#   Type           Status  Reason
#   ----           ------  ------
#   Available      True    MinimumReplicasAvailable
#   Progressing    True    NewReplicaSetAvailable
# OldReplicaSets:  <none>
# NewReplicaSet:   nginx-deployment-7d8c7b4b6c (3/3 replicas created)
# Events:
#   Type    Reason             Age   From                   Message
#   ----    ------             ----  ----                   -------
#   Normal  ScalingReplicaSet  10s   deployment-controller  Scaled up replica set nginx-deployment-7d8c7b4b6c to 3

# 查看ReplicaSet
kubectl get replicasets

# 输出：
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   3         3         3       10s

# 查看Pod
kubectl get pods -l app=nginx

# 输出：
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-7d8c7b4b6c-abc12   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-def34   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-ghi56   1/1     Running   0          10s
```

### 3.3.2 更新Deployment

```bash
# 更新Deployment镜像
kubectl set image deployment/nginx-deployment nginx=nginx:1.26.0

# 输出：
# deployment.apps/nginx-deployment image updated

# 查看更新状态
kubectl rollout status deployment/nginx-deployment

# 输出：
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# deployment "nginx-deployment" successfully rolled out

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           1m

# 查看ReplicaSet
kubectl get replicasets

# 输出：
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   0         0         0       1m
# nginx-deployment-8e9d8c5d7d   3         3         3       30s

# 查看Pod
kubectl get pods -l app=nginx

# 输出：
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-8e9d8c5d7d-jkl78   1/1     Running   0          30s
# nginx-deployment-8e9d8c5d7d-mno90   1/1     Running   0          30s
# nginx-deployment-8e9d8c5d7d-pqr12   1/1     Running   0          30s
```

### 3.3.3 回滚Deployment

```bash
# 查看Deployment历史
kubectl rollout history deployment/nginx-deployment

# 输出：
# deployment.apps/nginx-deployment
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>

# 查看指定版本详情
kubectl rollout history deployment/nginx-deployment --revision=1

# 输出：
# deployment.apps/nginx-deployment with revision #1
# Pod Template:
#   Labels:       app=nginx
#                 environment=production
#                 pod-template-hash=7d8c7b4b6c
#   Containers:
#    nginx:
#     Image:      nginx:1.25.0
#     Port:       80/TCP
#     Host Port:  0/TCP
#     Limits:
#       cpu:     500m
#       memory:  512Mi
#     Requests:
#       cpu:        100m
#       memory:     128Mi
#     Environment:
#       ENVIRONMENT:  production
#       LOG_LEVEL:    info

# 回滚到上一个版本
kubectl rollout undo deployment/nginx-deployment

# 输出：
# deployment.apps/nginx-deployment rolled back

# 查看回滚状态
kubectl rollout status deployment/nginx-deployment

# 输出：
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# deployment "nginx-deployment" successfully rolled out

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           2m

# 查看ReplicaSet
kubectl get replicasets

# 输出：
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   3         3         3       2m
# nginx-deployment-8e9d8c5d7d   0         0         0       1m

# 回滚到指定版本
kubectl rollout undo deployment/nginx-deployment --to-revision=2

# 输出：
# deployment.apps/nginx-deployment rolled back
```

### 3.3.4 扩缩容Deployment

```bash
# 扩容Deployment
kubectl scale deployment/nginx-deployment --replicas=5

# 输出：
# deployment.apps/nginx-deployment scaled

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   5/5     5            5           3m

# 查看Pod
kubectl get pods -l app=nginx

# 输出：
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-7d8c7b4b6c-abc12   1/1     Running   0          3m
# nginx-deployment-7d8c7b4b6c-def34   1/1     Running   0          3m
# nginx-deployment-7d8c7b4b6c-ghi56   1/1     Running   0          3m
# nginx-deployment-7d8c7b4b6c-jkl78   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-mno90   1/1     Running   0          10s

# 缩容Deployment
kubectl scale deployment/nginx-deployment --replicas=3

# 输出：
# deployment.apps/nginx-deployment scaled

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           4m

# 查看Pod
kubectl get pods -l app=nginx

# 输出：
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-7d8c7b4b6c-abc12   1/1     Running   0          4m
# nginx-deployment-7d8c7b4b6c-def34   1/1     Running   0          4m
# nginx-deployment-7d8c7b4b6c-ghi56   1/1     Running   0          4m
```

### 3.3.5 暂停和恢复Deployment

```bash
# 暂停Deployment
kubectl rollout pause deployment/nginx-deployment

# 输出：
# deployment.apps/nginx-deployment paused

# 更新Deployment镜像（不会触发滚动更新）
kubectl set image deployment/nginx-deployment nginx=nginx:1.26.0

# 输出：
# deployment.apps/nginx-deployment image updated

# 查看Deployment
kubectl get deployments

# 输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     0            3           5m

# 恢复Deployment
kubectl rollout resume deployment/nginx-deployment

# 输出：
# deployment.apps/nginx-deployment resumed

# 查看更新状态
kubectl rollout status deployment/nginx-deployment

# 输出：
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
# deployment "nginx-deployment" successfully rolled out
```

---

## 本章小结

- Deployment是用于管理无状态应用的控制器
- Deployment管理ReplicaSet，ReplicaSet管理Pod
- Deployment支持滚动更新，实现零停机更新
- Deployment支持回滚，可以回滚到任意历史版本
- Deployment支持扩缩容，可以手动或自动扩缩容
- Deployment支持暂停和恢复，可以控制更新时机
- Deployment支持金丝雀发布，可以逐步发布新版本
- Deployment支持蓝绿部署，可以快速切换版本
- 可以使用kubectl创建、更新、回滚、扩缩容Deployment
- 可以使用kubectl rollout status查看更新状态
- 可以使用kubectl rollout history查看历史版本

---

**下一章：Service和Ingress**
