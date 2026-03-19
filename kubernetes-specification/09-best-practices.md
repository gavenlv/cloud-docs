# Kubernetes最佳实践

## 9.1 资源管理最佳实践

### 9.1.1 资源请求和限制

```
资源请求和限制最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  资源请求和限制                                    │
└─────────────────────────────────────────────────────────────────┘

1. 设置资源请求

原则：
├── 为所有容器设置CPU请求
├── 为所有容器设置内存请求
├── 基于实际使用情况设置
└── 预留足够的资源

实践：
├── 使用监控工具收集数据
├── 使用性能测试工具测试
├── 使用基准测试工具验证
└── 使用容量规划工具预测

示例：
resources:
  requests:
    cpu: 100m
    memory: 128Mi

2. 设置资源限制

原则：
├── 为所有容器设置CPU限制
├── 为所有容器设置内存限制
├── 基于最大使用情况设置
└── 防止资源耗尽

实践：
├── 使用监控工具收集数据
├── 使用压力测试工具测试
├── 使用故障注入工具验证
└── 使用容量规划工具预测

示例：
resources:
  limits:
    cpu: 500m
    memory: 512Mi

3. QoS策略

Guaranteed：
├── CPU和内存都设置了Request和Limit
├── Request == Limit
├── 优先级最高
└── 资源不足时最后被杀死

示例：
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 512Mi

Burstable：
├── CPU或内存设置了Request和Limit
├── Request != Limit
├── 优先级中等
└── 资源不足时可能被杀死

示例：
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

BestEffort：
├── CPU和内存都没有设置Request和Limit
├── 优先级最低
└── 资源不足时首先被杀死

示例：
resources: {}
```

### 9.1.2 资源配额

```
资源配额最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  资源配额                                              │
└─────────────────────────────────────────────────────────────────┘

1. 配额类型

计算资源配额：
├── requests.cpu
├── requests.memory
├── limits.cpu
├── limits.memory
└── requests.nvidia.com/gpu

存储资源配额：
├── requests.storage
├── persistentvolumeclaims
├── volumes.storageclass.storage.k8s.io/requests.storage
└── volumes.storageclass.storage.k8s.io/persistentvolumeclaims

对象数量配额：
├── configmaps
├── persistentvolumeclaims
├── pods
├── replicationcontrollers
├── resourcequotas
├── secrets
├── services
├── services.loadbalancers
└── services.nodeports

2. 配额策略

按Namespace配额：
├── 为每个Namespace设置配额
├── 限制资源使用
├── 限制对象数量
└── 防止资源耗尽

按用户配额：
├── 为每个用户设置配额
├── 限制资源使用
├── 限制对象数量
└── 防止资源耗尽

按应用配额：
├── 为每个应用设置配额
├── 限制资源使用
├── 限制对象数量
└── 防止资源耗尽

3. 配额示例

计算资源配额：
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: default
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi

存储资源配额：
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-resources
  namespace: default
spec:
  hard:
    requests.storage: 100Gi
    persistentvolumeclaims: 10
    volumes.storageclass.storage.k8s.io/requests.storage: 50Gi
    volumes.storageclass.storage.k8s.io/persistentvolumeclaims: 5

对象数量配额：
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-counts
  namespace: default
spec:
  hard:
    configmaps: 10
    persistentvolumeclaims: 4
    pods: 10
    replicationcontrollers: 10
    secrets: 10
    services: 10
    services.loadbalancers: 2
    services.nodeports: 2
```

### 9.1.3 资源监控

```
资源监控最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  资源监控                                              │
└─────────────────────────────────────────────────────────────────┘

1. 监控指标

节点指标：
├── CPU使用率
├── 内存使用率
├── 磁盘使用率
├── 网络使用率
└── 节点健康状态

Pod指标：
├── CPU使用率
├── 内存使用率
├── 磁盘使用率
├── 网络使用率
└── Pod健康状态

容器指标：
├── CPU使用率
├── 内存使用率
├── 磁盘使用率
├── 网络使用率
└── 容器健康状态

2. 监控工具

Prometheus：
├── 收集指标
├── 存储指标
├── 查询指标
└── 告警指标

Grafana：
├── 可视化指标
├── 创建仪表板
├── 创建告警
└── 创建报表

Kubernetes Metrics Server：
├── 收集节点指标
├── 收集Pod指标
├── 提供API接口
└── 支持kubectl top

3. 监控实践

设置告警：
├── CPU使用率告警
├── 内存使用率告警
├── 磁盘使用率告警
├── 网络使用率告警
└── 健康状态告警

设置阈值：
├── CPU使用率 > 80%
├── 内存使用率 > 80%
├── 磁盘使用率 > 80%
├── 网络使用率 > 80%
└── 健康状态 != Ready

设置通知：
├── 邮件通知
├── 短信通知
├── 即时通讯通知
└── 电话通知
```

---

## 9.2 安全最佳实践

### 9.2.1 RBAC权限控制

```
RBAC权限控制最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  RBAC权限控制                                          │
└─────────────────────────────────────────────────────────────────┘

1. 最小权限原则

原则：
├── 只授予必要的权限
├── 只访问必要的资源
├── 只执行必要的操作
└── 只在必要时使用

实践：
├── 使用Role定义最小权限
├── 使用RoleBinding绑定最小权限
├── 使用ServiceAccount限制权限
├── 使用Namespace隔离权限

示例：
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: default
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io

2. 权限分离

原则：
├── 分离读写权限
├── 分离管理权限
├── 分离审计权限
└── 分离监控权限

实践：
├── 使用Role分离权限
├── 使用ClusterRole分离权限
├── 使用RoleBinding绑定权限
├── 使用ClusterRoleBinding绑定权限

示例：
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-read-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-write-role
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods", "configmaps"]
  verbs: ["create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-read-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-read-service-account
  namespace: default
roleRef:
  kind: Role
  name: app-read-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-write-role-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-write-service-account
  namespace: default
roleRef:
  kind: Role
  name: app-write-role
  apiGroup: rbac.authorization.k8s.io

3. 权限审计

原则：
├── 记录权限授予
├── 记录权限使用
├── 记录权限变更
└── 记录权限撤销

实践：
├── 启用审计日志
├── 使用日志分析工具
├── 使用告警机制
├── 使用合规检查

示例：
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- level: Request
  resources:
  - group: ""
    resources: ["pods", "configmaps", "secrets"]
- level: RequestResponse
  resources:
  - group: ""
    resources: ["pods/exec", "pods/portforward", "pods/proxy"]
```

### 9.2.2 网络策略

```
网络策略最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  网络策略                                              │
└─────────────────────────────────────────────────────────────────┘

1. 默认拒绝

原则：
├── 默认拒绝所有流量
├── 明确允许必要流量
├── 最小化网络暴露
└── 减少攻击面

实践：
├── 创建默认拒绝策略
├── 创建命名空间隔离策略
├── 创建应用隔离策略
└── 创建服务隔离策略

示例：
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

2. 最小化暴露

原则：
├── 只暴露必要端口
├── 只暴露必要协议
├── 只暴露必要来源
└── 只暴露必要目标

实践：
├── 创建服务网络策略
├── 创建Pod网络策略
├── 创建命名空间网络策略
└── 创建集群网络策略

示例：
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-traffic
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80

3. 网络分段

原则：
├── 按应用分段
├── 按环境分段
├── 按安全级别分段
└── 按数据敏感度分段

实践：
├── 创建应用网络分段
├── 创建环境网络分段
├── 创建安全级别网络分段
└── 创建数据敏感度网络分段

示例：
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database-traffic
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: app
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 3306
```

### 9.2.3 Pod安全策略

```
Pod安全策略最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  Pod安全策略                                          │
└─────────────────────────────────────────────────────────────────┘

1. 容器安全

原则：
├── 使用非root用户运行
├── 使用只读根文件系统
├── 限制容器能力
├── 限制特权模式

实践：
├── 设置securityContext
├── 设置podSecurityContext
├── 设置capabilities
├── 设置privileged

示例：
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:1.25.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE

2. 资源限制

原则：
├── 限制CPU使用
├── 限制内存使用
├── 限制存储使用
├── 限制网络使用

实践：
├── 设置resources.requests
├── 设置resources.limits
├── 设置ephemeral-storage
├── 设置network policies

示例：
apiVersion: v1
kind: Pod
metadata:
  name: resource-limited-pod
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

3. 镜像安全

原则：
├── 使用官方镜像
├── 使用最小化镜像
├── 使用扫描工具
├── 使用签名镜像

实践：
├── 使用alpine镜像
├── 使用distroless镜像
├── 使用Trivy扫描
├── 使用Notary签名

示例：
apiVersion: v1
kind: Pod
metadata:
  name: secure-image-pod
spec:
  containers:
  - name: app
    image: nginx:1.25.0-alpine
    securityContext:
      readOnlyRootFilesystem: true
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

---

## 9.3 监控和日志最佳实践

### 9.3.1 监控实践

```
监控实践：

┌─────────────────────────────────────────────────────────────────┐
│  监控实践                                              │
└─────────────────────────────────────────────────────────────────┘

1. 监控架构

Prometheus + Grafana：
├── Prometheus收集指标
├── Grafana可视化指标
├── Alertmanager告警
└── Pushgateway推送指标

组件：
├── Prometheus Server
├── Grafana
├── Alertmanager
├── Node Exporter
├── Kube State Metrics
├── cAdvisor
└── Pushgateway

2. 监控指标

系统指标：
├── CPU使用率
├── 内存使用率
├── 磁盘使用率
├── 网络使用率
└── 系统负载

应用指标：
├── 请求量
├── 响应时间
├── 错误率
├── 饱和度
└── 可用性

业务指标：
├── 用户数
├── 订单数
├── 交易额
├── 转化率
└── 留存率

3. 告警规则

系统告警：
├── CPU使用率 > 80%
├── 内存使用率 > 80%
├── 磁盘使用率 > 80%
├── 网络使用率 > 80%
└── 系统负载 > 5

应用告警：
├── 错误率 > 1%
├── 响应时间 > 1s
├── 可用性 < 99.9%
├── 饱和度 > 80%
└── 请求量 < 100

业务告警：
├── 用户数 < 1000
├── 订单数 < 100
├── 交易额 < 10000
├── 转化率 < 5%
└── 留存率 < 50%
```

### 9.3.2 日志实践

```
日志实践：

┌─────────────────────────────────────────────────────────────────┐
│  日志实践                                              │
└─────────────────────────────────────────────────────────────────┘

1. 日志架构

ELK Stack：
├── Elasticsearch存储日志
├── Logstash处理日志
├── Kibana可视化日志
└── Filebeat收集日志

EFK Stack：
├── Elasticsearch存储日志
├── Fluentd处理日志
├── Kibana可视化日志
└── Fluentd收集日志

PLG Stack：
├── Loki存储日志
├── Promtail处理日志
├── Grafana可视化日志
└── Promtail收集日志

2. 日志收集

容器日志：
├── 标准输出
├── 标准错误
├── 应用日志
└── 系统日志

节点日志：
├── 系统日志
├── 内核日志
├── Docker日志
├── Kubelet日志
└── Kube-proxy日志

应用日志：
├── 访问日志
├── 错误日志
├── 应用日志
└── 审计日志

3. 日志分析

日志查询：
├── 按时间查询
├── 按级别查询
├── 按关键词查询
└── 按字段查询

日志聚合：
├── 按应用聚合
├── 按节点聚合
├── 按命名空间聚合
└── 按标签聚合

日志告警：
├── 错误日志告警
├── 异常日志告警
├── 关键词告警
└── 频率告警
```

---

## 9.4 CI/CD集成最佳实践

### 9.4.1 CI/CD流程

```
CI/CD流程：

┌─────────────────────────────────────────────────────────────────┐
│  CI/CD流程                                             │
└─────────────────────────────────────────────────────────────────┘

1. 持续集成（CI）

代码提交：
├── 提交代码到Git
├── 触发CI流水线
├── 代码检查
├── 单元测试
├── 集成测试
└── 构建镜像

镜像构建：
├── 拉取基础镜像
├── 复制应用代码
├── 安装依赖
├── 编译应用
├── 运行测试
└── 推送镜像

2. 持续部署（CD）

部署到开发环境：
├── 部署到开发环境
├── 运行冒烟测试
├── 运行集成测试
├── 运行端到端测试
└── 验证部署

部署到测试环境：
├── 部署到测试环境
├── 运行性能测试
├── 运行安全测试
├── 运行压力测试
└── 验证部署

部署到生产环境：
├── 部署到生产环境
├── 运行监控检查
├── 运行健康检查
├── 运行回滚检查
└── 验证部署

3. GitOps实践

GitOps流程：
├── 声明式配置
├── 配置存储在Git
├── 自动同步配置
├── 自动部署应用
└── 自动监控状态

GitOps工具：
├── ArgoCD
├── Flux
├── Jenkins X
└── 其他工具
```

### 9.4.2 CI/CD工具

```
CI/CD工具：

┌─────────────────────────────────────────────────────────────────┐
│  CI/CD工具                                             │
└─────────────────────────────────────────────────────────────────┘

1. CI工具

Jenkins：
├── 开源免费
├── 插件丰富
├── 社区活跃
└── 功能强大

GitLab CI：
├── 集成GitLab
├── 配置简单
├── 使用方便
└── 功能完善

GitHub Actions：
├── 集成GitHub
├── 配置简单
├── 使用方便
└── 功能完善

2. CD工具

ArgoCD：
├── GitOps原生
├── 声明式配置
├── 自动同步
└── 可视化界面

Flux：
├── GitOps原生
├── 声明式配置
├── 自动同步
└── 功能完善

Jenkins X：
├── GitOps原生
├── 声明式配置
├── 自动同步
└── 功能完善

3. 镜像仓库

Docker Hub：
├── 官方仓库
├── 免费使用
├── 公开镜像
└── 私有镜像

Harbor：
├── 开源免费
├── 功能完善
├── 安全可靠
└── 企业级

GitLab Registry：
├── 集成GitLab
├── 使用方便
├── 功能完善
└── 企业级
```

---

## 本章小结

- 资源管理最佳实践包括设置资源请求和限制、配置资源配额、监控资源使用
- 资源请求和限制应该基于实际使用情况设置，预留足够的资源
- QoS策略包括Guaranteed、Burstable、BestEffort，优先级依次降低
- 资源配额可以限制计算资源、存储资源、对象数量
- 资源监控包括节点指标、Pod指标、容器指标
- 安全最佳实践包括RBAC权限控制、网络策略、Pod安全策略
- RBAC权限控制应该遵循最小权限原则，分离权限，审计权限
- 网络策略应该默认拒绝所有流量，最小化网络暴露，网络分段
- Pod安全策略应该使用非root用户运行，使用只读根文件系统，限制容器能力
- 监控和日志最佳实践包括监控架构、监控指标、告警规则、日志架构、日志收集、日志分析
- CI/CD集成最佳实践包括CI/CD流程、GitOps实践、CI/CD工具、镜像仓库

---

**下一章：Kubernetes常见错误处理**
