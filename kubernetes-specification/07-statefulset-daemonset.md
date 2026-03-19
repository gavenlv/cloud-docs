# StatefulSet和DaemonSet深度解析

## 7.1 StatefulSet原理

### 7.1.1 StatefulSet的核心概念

```
StatefulSet的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  StatefulSet是什么？                                 │
└─────────────────────────────────────────────────────────────────┘

StatefulSet是Kubernetes中用于管理有状态应用的控制器：

1. 有状态应用管理
   ├── 稳定的网络标识
   ├── 稳定的存储
   ├── 有序的部署和扩缩容
   └── 有序的滚动更新

2. 稳定的网络标识
   ├── 每个Pod有唯一的DNS名称
   ├── Pod名称包含序号
   ├── Pod重新调度后名称不变
   └── 支持Headless Service

3. 稳定的存储
   ├── 每个Pod有独立的PVC
   ├── Pod重新调度后存储不变
   ├── PVC名称包含序号
   └── 支持存储类

4. 有序的部署和扩缩容
   ├── 按序号顺序部署
   ├── 按序号顺序删除
   ├── 按序号顺序扩容
   └── 按序号顺序缩容

StatefulSet的优势：

1. 稳定性
   ├── 稳定的网络标识
   ├── 稳定的存储
   ├── 稳定的身份
   └── 稳定的配置

2. 有序性
   ├── 有序的部署
   ├── 有序的删除
   ├── 有序的扩缩容
   └── 有序的更新

3. 可预测性
   ├── 可预测的Pod名称
   ├── 可预测的PVC名称
   ├── 可预测的网络标识
   └── 可预测的存储

4. 适用性
   ├── 数据库
   ├── 消息队列
   ├── 分布式存储
   └── 其他有状态应用
```

### 7.1.2 StatefulSet与Deployment的区别

```
StatefulSet与Deployment的区别：

┌─────────────────────────────────────────────────────────────────┐
│  StatefulSet vs Deployment                          │
└─────────────────────────────────────────────────────────────────┘

1. 网络标识

StatefulSet：
├── 稳定的网络标识
├── 每个Pod有唯一的DNS名称
├── Pod名称包含序号
├── 支持Headless Service
└── 示例：web-0, web-1, web-2

Deployment：
├── 不稳定的网络标识
├── Pod名称随机
├── Pod重新调度后名称变化
├── 支持普通Service
└── 示例：web-7d8c7b4b6c-abc12

2. 存储

StatefulSet：
├── 稳定的存储
├── 每个Pod有独立的PVC
├── Pod重新调度后存储不变
├── PVC名称包含序号
└── 示例：data-web-0, data-web-1, data-web-2

Deployment：
├── 不稳定的存储
├── 所有Pod共享PVC
├── Pod重新调度后存储可能变化
├── PVC名称固定
└── 示例：data-web

3. 部署和扩缩容

StatefulSet：
├── 按序号顺序部署
├── 按序号顺序删除
├── 按序号顺序扩容
├── 按序号顺序缩容
└── 前一个Pod就绪后才创建下一个

Deployment：
├── 并发部署
├── 并发删除
├── 并发扩容
├── 并发缩容
└── 不保证顺序

4. 更新策略

StatefulSet：
├── 按序号顺序更新
├── 前一个Pod就绪后才更新下一个
├── 支持自动删除PVC
├── 支持分区更新
└── 支持OnDelete策略

Deployment：
├── 并发更新
├── 支持滚动更新
├── 支持金丝雀发布
├── 支持蓝绿部署
└── 支持Recreate策略
```

### 7.1.3 StatefulSet网络标识

```
StatefulSet网络标识：

┌─────────────────────────────────────────────────────────────────┐
│  StatefulSet网络标识                              │
└─────────────────────────────────────────────────────────────────┘

1. Headless Service

特点：
├── 不分配ClusterIP
├── 返回所有Pod的IP
├── 支持DNS记录
├── 支持服务发现
└── 示例：web.default.svc.cluster.local

DNS记录：
├── A记录：返回所有Pod的IP
├── SRV记录：返回所有Pod的端口
├── 每个Pod有独立的DNS记录
└── 示例：web-0.web.default.svc.cluster.local

2. Pod网络标识

命名规则：
├── StatefulSet名称-序号
├── 序号从0开始
├── 序号连续递增
└── 示例：web-0, web-1, web-2

DNS名称：
├── Pod名称.Service名称.Namespace.svc.cluster.local
├── 示例：web-0.web.default.svc.cluster.local
├── 示例：web-1.web.default.svc.cluster.local
└── 示例：web-2.web.default.svc.cluster.local

3. 稳定性

特点：
├── Pod重新调度后名称不变
├── Pod重新调度后DNS不变
├── Pod重新调度后身份不变
└── Pod重新调度后配置不变

优势：
├── 应用可以依赖稳定的网络标识
├── 应用可以依赖稳定的DNS名称
├── 应用可以依赖稳定的身份
└── 应用可以依赖稳定的配置
```

### 7.1.4 StatefulSet存储

```
StatefulSet存储：

┌─────────────────────────────────────────────────────────────────┐
│  StatefulSet存储                                      │
└─────────────────────────────────────────────────────────────────┘

1. PVC模板

特点：
├── 在StatefulSet中定义PVC模板
├── 每个Pod自动创建独立的PVC
├── PVC名称包含序号
└── 示例：data-web-0, data-web-1, data-web-2

命名规则：
├── PVC模板名称-StatefulSet名称-序号
├── 序号从0开始
├── 序号连续递增
└── 示例：data-web-0, data-web-1, data-web-2

2. 稳定性

特点：
├── Pod重新调度后PVC不变
├── Pod重新调度后存储不变
├── Pod重新调度后数据不变
└── Pod重新调度后挂载不变

优势：
├── 应用可以依赖稳定的存储
├── 应用可以依赖稳定的数据
├── 应用可以依赖稳定的挂载
└── 应用可以依赖稳定的配置

3. 删除策略

OnDelete：
├── 删除StatefulSet不删除PVC
├── 删除Pod不删除PVC
├── 需要手动删除PVC
└── 默认策略

自动删除：
├── 删除StatefulSet自动删除PVC
├── 删除Pod自动删除PVC
├── 需要配置volumeClaimTemplates
└── 需要配置persistentVolumeClaimRetentionPolicy
```

---

## 7.2 DaemonSet原理

### 7.2.1 DaemonSet的核心概念

```
DaemonSet的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  DaemonSet是什么？                                   │
└─────────────────────────────────────────────────────────────────┘

DaemonSet是Kubernetes中用于在每个节点上运行Pod副本的控制器：

1. 节点守护进程
   ├── 在每个节点上运行一个Pod
   ├── 新节点自动创建Pod
   ├── 节点删除自动删除Pod
   └── 支持节点选择器

2. 系统级服务
   ├── 日志收集
   ├── 监控代理
   ├── 网络插件
   └── 存储插件

3. 资源限制
   ├── 支持资源请求和限制
   ├── 支持优先级和抢占
   ├── 支持污点和容忍度
   └── 支持节点亲和性

4. 滚动更新
   ├── 支持滚动更新
   ├── 支持OnDelete策略
   ├── 支持分区更新
   └── 支持回滚

DaemonSet的优势：

1. 自动化
   ├── 自动在节点上创建Pod
   ├── 自动在节点上删除Pod
   ├── 自动处理节点变化
   └── 自动处理Pod故障

2. 一致性
   ├── 所有节点运行相同的Pod
   ├── 所有节点运行相同的配置
   ├── 所有节点运行相同的版本
   └── 所有节点运行相同的资源

3. 灵活性
   ├── 支持节点选择器
   ├── 支持污点和容忍度
   ├── 支持节点亲和性
   └── 支持反亲和性

4. 可靠性
   ├── 自动故障恢复
   ├── 自动重新调度
   ├── 自动健康检查
   └── 自动日志收集
```

### 7.2.2 DaemonSet与Deployment的区别

```
DaemonSet与Deployment的区别：

┌─────────────────────────────────────────────────────────────────┐
│  DaemonSet vs Deployment                             │
└─────────────────────────────────────────────────────────────────┘

1. Pod数量

DaemonSet：
├── 每个节点运行一个Pod
├── Pod数量等于节点数量
├── 新节点自动创建Pod
└── 节点删除自动删除Pod

Deployment：
├── 运行指定数量的Pod
├── Pod数量等于replicas
├── 不依赖节点数量
└── 不自动创建或删除Pod

2. 调度策略

DaemonSet：
├── 自动调度到所有节点
├── 支持节点选择器
├── 支持污点和容忍度
└── 支持节点亲和性

Deployment：
├── 由Scheduler调度
├── 支持节点选择器
├── 支持污点和容忍度
├── 支持节点亲和性
└── 支持Pod亲和性

3. 使用场景

DaemonSet：
├── 日志收集
├── 监控代理
├── 网络插件
├── 存储插件
└── 其他系统级服务

Deployment：
├── 无状态应用
├── Web应用
├── API服务
├── 微服务
└── 其他应用级服务

4. 更新策略

DaemonSet：
├── 支持滚动更新
├── 支持OnDelete策略
├── 支持分区更新
└── 支持回滚

Deployment：
├── 支持滚动更新
├── 支持Recreate策略
├── 支持金丝雀发布
├── 支持蓝绿部署
└── 支持回滚
```

### 7.2.3 DaemonSet调度策略

```
DaemonSet调度策略：

┌─────────────────────────────────────────────────────────────────┐
│  DaemonSet调度策略                                │
└─────────────────────────────────────────────────────────────────┘

1. 节点选择器

特点：
├── 只在匹配的节点上创建Pod
├── 支持标签选择器
├── 支持字段选择器
└── 支持组合选择器

示例：
├── disktype=ssd
├── zone=us-west-1a
├── node-role.kubernetes.io/master
└── 组合选择器

2. 污点和容忍度

特点：
├── 只在容忍的节点上创建Pod
├── 支持污点容忍
├── 支持污点时间限制
└── 支持污点效果

示例：
├── node-role.kubernetes.io/master:NoSchedule
├── node.kubernetes.io/not-ready:NoExecute
├── dedicated=database:NoSchedule
└── 自定义污点

3. 节点亲和性

特点：
├── 只在亲和的节点上创建Pod
├── 支持必需亲和性
├── 支持首选亲和性
└── 支持拓扑分布约束

示例：
├── 必需亲和性：zone=us-west-1a
├── 首选亲和性：disktype=ssd
├── 拓扑分布：zone
└── 组合亲和性

4. 反亲和性

特点：
├── 不在反亲和的节点上创建Pod
├── 支持必需反亲和性
├── 支持首选反亲和性
└── 支持拓扑分布约束

示例：
├── 必需反亲和性：node-role.kubernetes.io/master
├── 首选反亲和性：node-type=low-performance
├── 拓扑分布：zone
└── 组合反亲和性
```

---

## 7.3 StatefulSet配置

### 7.3.1 StatefulSet基本配置

```yaml
# statefulset-basic.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: default
  labels:
    app: web
    environment: production
  annotations:
    description: "Web application statefulset"
spec:
  serviceName: web
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        environment: production
    spec:
      containers:
      - name: web
        image: nginx:1.25.0
        ports:
        - containerPort: 80
          name: web
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: data
          mountPath: /data
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
  volumeClaimTemplates:
  - metadata:
      name: data
      labels:
        app: web
        environment: production
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: standard
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  podManagementPolicy: OrderedReady
  revisionHistoryLimit: 10
```

### 7.3.2 StatefulSet Headless Service配置

```yaml
# service-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: default
  labels:
    app: web
    environment: production
  annotations:
    description: "Web application headless service"
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - name: web
    port: 80
    targetPort: 80
    protocol: TCP
  sessionAffinity: None
```

### 7.3.3 StatefulSet分区更新配置

```yaml
# statefulset-partition.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: default
  labels:
    app: web
    environment: production
spec:
  serviceName: web
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        environment: production
    spec:
      containers:
      - name: web
        image: nginx:1.26.0
        ports:
        - containerPort: 80
          name: web
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: standard
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2
  podManagementPolicy: OrderedReady
```

---

## 7.4 DaemonSet配置

### 7.4.1 DaemonSet基本配置

```yaml
# daemonset-basic.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: default
  labels:
    app: fluentd
    environment: production
  annotations:
    description: "Fluentd log collector daemonset"
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
        environment: production
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.16-1
        ports:
        - containerPort: 24224
          name: forward
          protocol: TCP
        - containerPort: 24231
          name: http
          protocol: TCP
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc/fluent.conf
          subPath: fluent.conf
        env:
        - name: FLUENTD_CONF
          value: fluent.conf
        - name: FLUENTD_OPT
          value: --no-supervisor
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluentd-config
        configMap:
          name: fluentd-config
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirstWithHostNet
      hostNetwork: false
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  revisionHistoryLimit: 10
```

### 7.4.2 DaemonSet节点选择器配置

```yaml
# daemonset-node-selector.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: default
  labels:
    app: fluentd
    environment: production
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
        environment: production
    spec:
      nodeSelector:
        disktype: ssd
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.16-1
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

### 7.4.3 DaemonSet污点和容忍度配置

```yaml
# daemonset-taint-toleration.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: default
  labels:
    app: fluentd
    environment: production
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
        environment: production
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 300
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.16-1
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

---

## 7.5 StatefulSet和DaemonSet实战

### 7.5.1 创建StatefulSet

```bash
# 创建Headless Service
kubectl apply -f service-headless.yaml

# 输出：
# service/web created

# 查看Service
kubectl get services

# 输出：
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# web          ClusterIP   None         <none>        80/TCP    10s
# kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m

# 创建StatefulSet
kubectl apply -f statefulset-basic.yaml

# 输出：
# statefulset.apps/web created

# 查看StatefulSet
kubectl get statefulsets

# 输出：
# NAME   READY   AGE
# web    3/3     10s

# 查看Pod
kubectl get pods -l app=web

# 输出：
# NAME    READY   STATUS    RESTARTS   AGE
# web-0   1/1     Running   0          10s
# web-1   1/1     Running   0          5s
# web-2   1/1     Running   0          0s

# 查看PVC
kubectl get pvc -l app=web

# 输出：
# NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-web-0  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            standard      10s
# data-web-1  Bound    pvc-12345678-9abc-def0-1234-56789abcdef0   10Gi       RWO            standard      5s
# data-web-2  Bound    pvc-23456789-abcd-ef01-2345-67890abcdef1   10Gi       RWO            standard      0s

# 测试DNS解析
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- nslookup web-0.web.default.svc.cluster.local

# 输出：
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# 
# Name:      web-0.web.default.svc.cluster.local
# Address 1: 10.244.0.5 web-0.web.default.svc.cluster.local
```

### 7.5.2 扩容StatefulSet

```bash
# 扩容StatefulSet
kubectl scale statefulset/web --replicas=5

# 输出：
# statefulset.apps/web scaled

# 查看StatefulSet
kubectl get statefulsets

# 输出：
# NAME   READY   AGE
# web    5/5     1m

# 查看Pod
kubectl get pods -l app=web

# 输出：
# NAME    READY   STATUS    RESTARTS   AGE
# web-0   1/1     Running   0          1m
# web-1   1/1     Running   0          1m
# web-2   1/1     Running   0          1m
# web-3   1/1     Running   0          10s
# web-4   1/1     Running   0          5s

# 查看PVC
kubectl get pvc -l app=web

# 输出：
# NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-web-0  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            standard      1m
# data-web-1  Bound    pvc-12345678-9abc-def0-1234-56789abcdef0   10Gi       RWO            standard      1m
# data-web-2  Bound    pvc-23456789-abcd-ef01-2345-67890abcdef1   10Gi       RWO            standard      1m
# data-web-3  Bound    pvc-345678901-bcde-f012-3456-789012345678   10Gi       RWO            standard      10s
# data-web-4  Bound    pvc-45678912-cdef-0123-4567-8901234567890   10Gi       RWO            standard      5s
```

### 7.5.3 更新StatefulSet

```bash
# 更新StatefulSet镜像
kubectl set image statefulset/web web=nginx:1.26.0

# 输出：
# statefulset.apps/web image updated

# 查看更新状态
kubectl rollout status statefulset/web

# 输出：
# Waiting for 3 pods to be ready...
# Waiting for statefulset rolling update to complete 1 pod at a time...
# Waiting for pod web-0 to be ready...
# Waiting for pod web-1 to be ready...
# Waiting for pod web-2 to be ready...
# statefulset rolling update complete 3 pods at a time

# 查看StatefulSet
kubectl get statefulsets

# 输出：
# NAME   READY   AGE
# web    5/5     2m

# 查看Pod
kubectl get pods -l app=web

# 输出：
# NAME    READY   STATUS    RESTARTS   AGE
# web-0   1/1     Running   0          2m
# web-1   1/1     Running   0          2m
# web-2   1/1     Running   0          2m
# web-3   1/1     Running   0          1m
# web-4   1/1     Running   0          1m
```

### 7.5.4 创建DaemonSet

```bash
# 创建DaemonSet
kubectl apply -f daemonset-basic.yaml

# 输出：
# daemonset.apps/fluentd created

# 查看DaemonSet
kubectl get daemonsets

# 输出：
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
# fluentd   3         3         3       3            3           <none>          10s

# 查看Pod
kubectl get pods -l app=fluentd

# 输出：
# NAME            READY   STATUS    RESTARTS   AGE
# fluentd-abc12   1/1     Running   0          10s
# fluentd-def34   1/1     Running   0          10s
# fluentd-ghi56   1/1     Running   0          10s

# 查看Pod所在的节点
kubectl get pods -l app=fluentd -o wide

# 输出：
# NAME            READY   STATUS    RESTARTS   AGE   IP            NODE
# fluentd-abc12   1/1     Running   0          10s   10.244.0.5    node1
# fluentd-def34   1/1     Running   0          10s   10.244.0.6    node2
# fluentd-ghi56   1/1     Running   0          10s   10.244.0.7    node3
```

### 7.5.5 更新DaemonSet

```bash
# 更新DaemonSet镜像
kubectl set image daemonset/fluentd fluentd=fluent/fluentd:v1.16-2

# 输出：
# daemonset.apps/fluentd image updated

# 查看更新状态
kubectl rollout status daemonset/fluentd

# 输出：
# Waiting for daemon set "fluentd" rollout to finish: 0 out of 3 new pods have been updated...
# Waiting for daemon set "fluentd" rollout to finish: 1 out of 3 new pods have been updated...
# Waiting for daemon set "fluentd" rollout to finish: 2 out of 3 new pods have been updated...
# Waiting for daemon set "fluentd" rollout to finish: 3 out of 3 new pods have been updated...
# daemon set "fluentd" successfully rolled out

# 查看DaemonSet
kubectl get daemonsets

# 输出：
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
# fluentd   3         3         3       3            3           <none>          1m

# 查看Pod
kubectl get pods -l app=fluentd

# 输出：
# NAME            READY   STATUS    RESTARTS   AGE
# fluentd-jkl78   1/1     Running   0          10s
# fluentd-mno90   1/1     Running   0          10s
# fluentd-pqr12   1/1     Running   0          10s
```

---

## 本章小结

- StatefulSet是Kubernetes中用于管理有状态应用的控制器
- StatefulSet提供稳定的网络标识、稳定的存储、有序的部署和扩缩容
- StatefulSet使用Headless Service实现稳定的网络标识
- StatefulSet使用PVC模板实现稳定的存储
- StatefulSet支持分区更新，可以控制更新范围
- StatefulSet与Deployment的区别在于稳定性、有序性、可预测性
- DaemonSet是Kubernetes中用于在每个节点上运行Pod副本的控制器
- DaemonSet自动在节点上创建和删除Pod
- DaemonSet支持节点选择器、污点和容忍度、节点亲和性等调度策略
- DaemonSet与Deployment的区别在于Pod数量、调度策略、使用场景
- 可以使用kubectl创建、查看、扩缩容、更新StatefulSet和DaemonSet
- 可以使用kubectl rollout status查看更新状态

---

**下一章：Helm包管理**
