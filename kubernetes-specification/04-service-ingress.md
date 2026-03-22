# Service和Ingress深度解析

## 4.1 Service原理

### 4.1.1 Service的核心概念

```
Service的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Service是什么？                                        │
└─────────────────────────────────────────────────────────────────┘

Service是Kubernetes中用于暴露应用的抽象：

1. 服务发现
   ├── 为Pod提供稳定的网络标识
   ├── 通过Pod标签选择Pod
   ├── 自动更新Pod列表
   └── 实现负载均衡

2. 负载均衡
   ├── 在多个Pod间分发流量
   ├── 支持多种负载均衡算法
   ├── 自动处理Pod变化
   └── 提供高可用性

3. 网络代理
   ├── 通过kube-proxy实现
   ├── 支持多种代理模式
   ├── 自动维护网络规则
   └── 提供高性能转发

4. 服务类型
   ├── ClusterIP：集群内部访问
   ├── NodePort：节点端口访问
   ├── LoadBalancer：外部负载均衡器
   └── ExternalName：外部服务别名

Service的优势：

1. 稳定的访问地址
   ├── Pod IP会变化
   ├── Service IP稳定
   ├── 通过DNS访问
   └── 简化应用配置

2. 自动负载均衡
   ├── 自动分发流量
   ├── 自动处理Pod变化
   ├── 自动故障转移
   └── 提供高可用性

3. 灵活的服务类型
   ├── 支持多种访问方式
   ├── 支持外部访问
   ├── 支持跨集群访问
   └── 支持自定义配置

4. 集成DNS
   ├── 自动DNS注册
   ├── 自动DNS解析
   ├── 支持服务发现
   └── 简化服务调用
```

### 4.1.2 Service类型详解

```
Service类型详解：

┌─────────────────────────────────────────────────────────────────┐
│  Service类型                                        │
└─────────────────────────────────────────────────────────────────┘

1. ClusterIP（集群IP）

特点：
├── 默认服务类型
├── 仅在集群内部可访问
├── 分配集群内部IP
├── 通过kube-proxy实现
└── 适合内部服务

使用场景：
├── 应用间通信
├── 数据库访问
├── 缓存访问
└── 内部API调用

工作原理：
├── kube-proxy创建iptables规则
├── 将流量转发到后端Pod
├── 支持会话保持
└── 支持健康检查

2. NodePort（节点端口）

特点：
├── 在每个节点上开放端口
├── 通过节点IP:端口访问
├── 端口范围：30000-32767
├── 自动创建ClusterIP
└── 适合外部访问

使用场景：
├── 开发测试环境
├── 临时外部访问
├── 简单的外部服务
└── 低流量应用

工作原理：
├── 在每个节点上监听端口
├── 将流量转发到Service
├── Service再转发到Pod
└── 支持外部负载均衡

3. LoadBalancer（负载均衡器）

特点：
├── 使用云厂商的负载均衡器
├── 分配外部IP
├── 自动创建NodePort
├── 自动创建ClusterIP
└── 适合生产环境

使用场景：
├── 生产环境
├── 高流量应用
├── 需要外部IP
└── 需要负载均衡

工作原理：
├── 云厂商创建负载均衡器
├── 负载均衡器转发到节点
├── 节点转发到Service
└── Service转发到Pod

4. ExternalName（外部名称）

特点：
├── 不创建ClusterIP
├── 返回CNAME记录
├── 指向外部服务
├── 仅支持DNS
└── 适合外部服务

使用场景：
├── 访问外部数据库
├── 访问外部API
├── 服务迁移
└── 混合云部署

工作原理：
├── DNS返回CNAME记录
├── 客户端直接访问外部服务
├── 不经过Kubernetes
└── 不提供负载均衡
```

### 4.1.3 Service负载均衡

```
Service负载均衡：

┌─────────────────────────────────────────────────────────────────┐
│  Service负载均衡算法                                  │
└─────────────────────────────────────────────────────────────────┘

1. 随机选择（Random）

特点：
├── iptables模式默认
├── 随机选择Pod
├── 简单高效
└── 适合无状态应用

工作原理：
├── kube-proxy创建iptables规则
├── 规则使用随机匹配
├── 每个连接随机选择Pod
└── 不考虑连接数

2. 轮询（Round Robin）

特点：
├── IPVS模式默认
├── 依次选择Pod
├── 负载均衡
└── 适合无状态应用

工作原理：
├── kube-proxy创建IPVS规则
├── 规则使用轮询算法
├── 每个连接依次选择Pod
└── 考虑连接数

3. 最少连接（Least Connection）

特点：
├── IPVS模式支持
├── 选择连接数最少的Pod
├── 动态负载均衡
└── 适合长连接应用

工作原理：
├── kube-proxy创建IPVS规则
├── 规则使用最少连接算法
├── 每个连接选择连接数最少的Pod
└── 考虑连接数

4. 源地址哈希（Source Hashing）

特点：
├── IPVS模式支持
├── 根据源地址选择Pod
├── 会话保持
└── 适合有状态应用

工作原理：
├── kube-proxy创建IPVS规则
├── 规则使用源地址哈希
├── 相同源地址选择相同Pod
└── 保持会话
```

### 4.1.4 kube-proxy工作模式

```
kube-proxy工作模式：

┌─────────────────────────────────────────────────────────────────┐
│  kube-proxy工作模式                                    │
└─────────────────────────────────────────────────────────────────┘

1. iptables模式

特点：
├── 默认模式
├── 使用iptables规则
├── 随机选择Pod
├── 性能一般
└── 适合小规模集群

工作原理：
├── 监听Service和Endpoints变化
├── 创建iptables规则
├── 规则使用随机匹配
├── 流量通过iptables转发
└── 不支持高级负载均衡

优点：
├── 简单可靠
├── 内核原生支持
├── 无需额外组件
└── 兼容性好

缺点：
├── 规则数量多
├── 性能一般
├── 不支持高级负载均衡
└── 调试困难

2. ipvs模式

特点：
├── 高性能模式
├── 使用IPVS规则
├── 支持多种负载均衡算法
├── 性能较好
└── 适合大规模集群

工作原理：
├── 监听Service和Endpoints变化
├── 创建IPVS虚拟服务器
├── 创建IPVS真实服务器
├── 流量通过IPVS转发
└── 支持高级负载均衡

优点：
├── 性能高
├── 规则数量少
├── 支持多种负载均衡算法
└── 支持会话保持

缺点：
├── 需要加载IPVS模块
├── 配置复杂
├── 调试困难
└── 兼容性问题

3. nftables模式

特点：
├── 新一代模式
├── 使用nftables规则
├── 支持复杂规则
├── 性能较好
└── 适合复杂网络场景

工作原理：
├── 监听Service和Endpoints变化
├── 创建nftables规则
├── 规则支持复杂匹配
├── 流量通过nftables转发
└── 支持高级网络功能

优点：
├── 性能高
├── 规则灵活
├── 支持复杂匹配
└── 易于扩展

缺点：
├── 需要新内核
├── 配置复杂
├── 调试困难
└── 兼容性问题
```

---

## 4.2 Ingress原理

### 4.2.1 Ingress的核心概念

```
Ingress的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Ingress是什么？                                         │
└─────────────────────────────────────────────────────────────────┘

Ingress是Kubernetes中用于HTTP/HTTPS路由的规则：

1. HTTP/HTTPS路由
   ├── 基于主机名路由
   ├── 基于路径路由
   ├── 支持TLS终止
   └── 支持SSL卸载

2. 反向代理
   ├── 作为集群入口
   ├── 转发流量到Service
   ├── 支持负载均衡
   └── 支持健康检查

3. 高级功能
   ├── URL重写
   ├── 重定向
   ├── 认证和授权
   └── 限流和熔断

4. Ingress Controller
   ├── 实现Ingress规则
   ├── 监听Ingress资源
   ├── 配置反向代理
   └── 提供高可用性

Ingress的优势：

1. 统一入口
   ├── 单一入口点
   ├── 统一管理
   ├── 统一配置
   └── 统一监控

2. 灵活路由
   ├── 基于主机名
   ├── 基于路径
   ├── 支持正则表达式
   └── 支持自定义规则

3. 高级功能
   ├── TLS终止
   ├── URL重写
   ├── 认证授权
   └── 限流熔断

4. 性能优化
   ├── 负载均衡
   ├── 连接复用
   ├── 缓存加速
   └── 压缩传输
```

### 4.2.2 Ingress Controller

```
Ingress Controller：

┌─────────────────────────────────────────────────────────────────┐
│  Ingress Controller                                     │
└─────────────────────────────────────────────────────────────────┘

常见的Ingress Controller：

1. NGINX Ingress Controller

特点：
├── 最流行的Ingress Controller
├── 基于NGINX
├── 功能丰富
├── 性能优秀
└── 社区活跃

功能：
├── HTTP/HTTPS路由
├── TLS终止
├── URL重写
├── 负载均衡
├── 会话保持
├── 认证授权
├── 限流熔断
└── 监控日志

2. Traefik Ingress Controller

特点：
├── 现代化的Ingress Controller
├── 自动发现服务
├── 配置简单
├── 性能优秀
└── 支持多种后端

功能：
├── 自动服务发现
├── HTTP/HTTPS路由
├── TLS终止
├── 负载均衡
├── 中间件支持
├── 监控指标
├── Web UI
└── 动态配置

3. HAProxy Ingress Controller

特点：
├── 基于HAProxy
├── 性能优秀
├── 功能丰富
├── 稳定可靠
└── 企业级支持

功能：
├── HTTP/HTTPS路由
├── TLS终止
├── 负载均衡
├── 会话保持
├── 健康检查
├── 监控统计
├── 限流熔断
└── 动态配置

4. Envoy Ingress Controller

特点：
├── 基于Envoy
├── 现代化架构
├── 功能强大
├── 性能优秀
└── 云原生

功能：
├── HTTP/HTTPS路由
├── gRPC代理
├── 负载均衡
├── 服务网格
├── 可观测性
├── 动态配置
├── 高级路由
└── 安全功能
```

### 4.2.3 Ingress规则

```
Ingress规则：

┌─────────────────────────────────────────────────────────────────┐
│  Ingress规则                                            │
└─────────────────────────────────────────────────────────────────┘

1. 基于主机名的路由

规则：
├── 根据Host头路由
├── 支持通配符
├── 支持多主机
└── 支持默认主机

示例：
├── app1.example.com → Service1
├── app2.example.com → Service2
├── *.example.com → DefaultService
└── / → DefaultService

2. 基于路径的路由

规则：
├── 根据路径路由
├── 支持精确匹配
├── 支持前缀匹配
├── 支持正则表达式
└── 支持路径重写

示例：
├── /api → ApiService
├── /web → WebService
├── /static → StaticService
└── / → DefaultService

3. TLS配置

规则：
├── 支持TLS终止
├── 支持多证书
├── 支持自动证书
└── 支持证书更新

示例：
├── app1.example.com → cert1
├── app2.example.com → cert2
├── *.example.com → wildcard-cert
└── 自动证书管理

4. 高级功能

规则：
├── URL重写
├── 重定向
├── 认证授权
├── 限流熔断
├── 自定义头
├── 超时配置
└── 健康检查
```

---

## 4.3 Service配置

### 4.3.1 ClusterIP Service配置

```yaml
# service-clusterip.yaml

# Kubernetes API 版本 - 核心API组
# 可选值: v1
apiVersion: v1

# 资源类型 - 服务
# 用于将Pod暴露为网络服务
kind: Service

# 元数据
metadata:
  # Service名称 - 在namespace内必须唯一
  name: nginx-service

  # 所属namespace
  namespace: default

  # 标签
  labels:
    app: nginx
    environment: production

  # 注解
  annotations:
    description: "Nginx web server service"

# 规格说明
spec:
  # Service类型 - 定义服务暴露方式
  # 可选值:
  #   - ClusterIP: 集群内部访问 (默认)
  #   - NodePort: 通过节点端口访问
  #   - LoadBalancer: 通过云厂商负载均衡器
  #   - ExternalName: 映射到外部域名
  type: ClusterIP

  # 集群IP - Service的虚拟IP地址
  # 如果不指定，系统会自动分配
  # 可选值: 有效的IPv4地址, 或留空自动分配
  clusterIP: 10.96.0.100

  # 选择器 - 指定哪些Pod归此Service管理
  # Service会根据selector负载均衡到匹配的Pod
  selector:
    # 标签键值对
    app: nginx

  # 端口定义列表
  ports:
    # 端口1: HTTP
    - # 端口名称 - 用于标识端口
      name: http

      # Service端口 - ClusterIP监听的端口
      # 客户端访问此端口
      port: 80

      # 目标端口 - 转发到的容器端口
      # 可选值: 端口号(1-65535) 或 端口名称
      targetPort: 80

      # 协议
      # 可选值: TCP, UDP, SCTP
      protocol: TCP

    # 端口2: HTTPS
    - name: https
      port: 443
      targetPort: 443
      protocol: TCP

  # 会话亲和性 - 是否保持客户端会话
  # 可选值:
  #   - None: 无亲和性 (默认)
  #   - ClientIP: 基于客户端IP的亲和性
  sessionAffinity: None

  # 会话亲和性配置
  sessionAffinityConfig:
    # ClientIP配置
    clientIP:
      # 超时时间 - 亲和性保持时长
      # 可选值: 秒数 (通常设为10800=3小时)
      timeoutSeconds: 10800
```

### 4.3.2 NodePort Service配置

```yaml
# service-nodeport.yaml

# Kubernetes API 版本
apiVersion: v1

# 资源类型
kind: Service

# 元数据
metadata:
  name: nginx-service
  namespace: default
  labels:
    app: nginx
    environment: production
  annotations:
    description: "Nginx web server service"

# 规格说明
spec:
  # Service类型
  # NodePort: 通过<NodeIP>:<NodePort>访问
  type: NodePort

  # 选择器
  selector:
    app: nginx

  # 端口定义
  ports:
    # HTTP端口
    - name: http

      # Service端口
      port: 80

      # 目标端口
      targetPort: 80

      # NodePort - 节点上暴露的端口
      # 可选值: 30000-32767
      # 如果不指定，Kubernetes自动分配
      nodePort: 30080

      protocol: TCP

    # HTTPS端口
    - name: https
      port: 443
      targetPort: 443
      nodePort: 30443
      protocol: TCP

  # 会话亲和性
  sessionAffinity: None

  # 外部流量策略
  # 可选值:
  #   - Cluster: 流量分布到所有节点 (默认)
  #   - Local: 流量只到有对应Pod的节点
  externalTrafficPolicy: Cluster
```

### 4.3.3 LoadBalancer Service配置

```yaml
# service-loadbalancer.yaml

# Kubernetes API 版本
apiVersion: v1

# 资源类型
kind: Service

# 元数据
metadata:
  name: nginx-service
  namespace: default
  labels:
    app: nginx
    environment: production

  # 注解 - 云厂商特定配置
  annotations:
    description: "Nginx web server service"

    # AWS云负载均衡器类型
    # 可选值: "nlb" (网络负载均衡器), "elb" (经典负载均衡器)
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

    # 跨区域负载均衡 - 是否允许流量分发到其他可用区
    # 可选值: "true", "false"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

# 规格说明
spec:
  # Service类型
  # LoadBalancer: 通过云厂商负载均衡器暴露
  type: LoadBalancer

  # 选择器
  selector:
    app: nginx

  # 端口定义
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP

    - name: https
      port: 443
      targetPort: 443
      protocol: TCP

  # 会话亲和性
  sessionAffinity: None
  externalTrafficPolicy: Cluster
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
```

### 4.3.4 ExternalName Service配置

```yaml
# service-externalname.yaml

# Kubernetes API 版本
apiVersion: v1

# 资源类型
kind: Service

# 元数据
metadata:
  # Service名称
  name: external-database

  # 所属namespace
  namespace: default

  # 标签
  labels:
    app: database
    environment: production

  # 注解
  annotations:
    description: "External database service"

# 规格说明
spec:
  # Service类型
  # ExternalName: 映射到外部域名 (CNAME记录)
  type: ExternalName

  # 外部域名 - 要映射到的目标域名
  # 客户端访问此Service时会被解析到此域名
  externalName: database.example.com

  # 会话亲和性
  sessionAffinity: None
```

---

## 4.4 Ingress配置

### 4.4.1 基于主机名的Ingress配置

```yaml
# ingress-hostname.yaml

# Kubernetes API 版本 - 网络API组
# 可选值: networking.k8s.io/v1, networking.k8s.io/v1beta1
apiVersion: networking.k8s.io/v1

# 资源类型 - HTTP/HTTPS路由
kind: Ingress

# 元数据
metadata:
  # Ingress名称
  name: nginx-ingress

  # 所属namespace
  namespace: default

  # 标签
  labels:
    app: nginx
    environment: production

  # 注解 - Ingress控制器特定配置
  annotations:
    # 路径重写目标
    # 可选值: 字符串，如 "/", "/$2"
    nginx.ingress.kubernetes.io/rewrite-target: /

    # SSL重定向
    # 可选值: "true", "false"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"

    # 证书管理器 - 用于自动签发SSL证书
    # 可选值: "letsencrypt-prod", "letsencrypt-staging"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"

# 规格说明
spec:
  # Ingress类名 - 指定使用的Ingress控制器
  # 可选值: nginx, traefik, envoy, 或其他已安装的IngressClass
  ingressClassName: nginx

  # TLS配置列表 - HTTPS证书
  tls:
    # TLS配置1
    - # 需要TLS的主机名列表
      hosts:
        # 示例: app1.example.com
        - app1.example.com

      # 证书密钥名称 - 引用Secret
      secretName: app1-tls

    # TLS配置2
    - hosts:
        - app2.example.com
      secretName: app2-tls

  # 规则列表 - 定义路由规则
  rules:
    # 规则1: app1.example.com
    - # 主机名 - 匹配请求的Host头
      # 可选值: 域名, 或空 (匹配所有)
      host: app1.example.com

      # HTTP规则
      http:
        # 路径列表
        paths:
          # 路径配置
          - # 路径前缀
            # 可选值: 任何路径字符串
            path: /

            # 路径类型
            # 可选值:
            #   - Prefix: 前缀匹配 (最常用)
            #   - Exact: 精确匹配
            #   - ImplementationSpecific: 由IngressClass决定
            pathType: Prefix

            # 后端服务
            backend:
              service:
                # 服务名称
                name: app1-service

                # 服务端口
                port:
                  # 端口号
                  number: 80

    # 规则2: app2.example.com
    - host: app2.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app2-service
                port:
                  number: 80
```

### 4.4.2 基于路径的Ingress配置

```yaml
# ingress-path.yaml

# Kubernetes API 版本
apiVersion: networking.k8s.io/v1

# 资源类型
kind: Ingress

# 元数据
metadata:
  name: nginx-ingress
  namespace: default
  labels:
    app: nginx
    environment: production

  # 注解
  annotations:
    # 路径重写 - 将匹配到的路径部分重写到目标
    # $2 表示第二个捕获组
    # 可选值: 字符串，如 "/$2"
    nginx.ingress.kubernetes.io/rewrite-target: /$2

    # SSL重定向
    nginx.ingress.kubernetes.io/ssl-redirect: "true"

    # 证书颁发者
    cert-manager.io/cluster-issuer: "letsencrypt-prod"

# 规格说明
spec:
  # Ingress类名
  ingressClassName: nginx

  # TLS配置
  tls:
    - hosts:
        # 示例: app.example.com
        - app.example.com
      secretName: app-tls

  # 规则列表
  rules:
    - host: app.example.com
      http:
        paths:
          # API路径 - 使用正则匹配
          - # 路径模式
            # (/|$)(.*) 匹配 /api/* 或 /api
            path: /api(/|$)(.*)

            # 路径类型
            # ImplementationSpecific: 由IngressClass决定如何处理
            pathType: ImplementationSpecific

            # 后端服务
            backend:
              service:
                name: api-service
                port:
                  number: 80

          # Web路径
          - path: /web(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: web-service
                port:
                  number: 80
        pathType: ImplementationSpecific
        backend:
          service:
            name: web-service
            port:
              number: 80
      - path: /static(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: static-service
            port:
              number: 80
      - path: /
        pathType: Prefix
        backend:
          service:
            name: default-service
            port:
              number: 80
```

### 4.4.3 带认证的Ingress配置

```yaml
# ingress-auth.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: default
  labels:
    app: nginx
    environment: production
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
---
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth
  namespace: default
type: Opaque
data:
  auth: YWRtaW46JGFwcjEkNU1yTzZqZGwkNkZ6TjZzZ2ZkN2Z6TjZzZ2ZkN2Z6TjZzZ2ZkNw==
```

### 4.4.4 带限流的Ingress配置

```yaml
# ingress-rate-limit.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: default
  labels:
    app: nginx
    environment: production
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-burst: "20"
    nginx.ingress.kubernetes.io/limit-connections: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

---

## 4.5 Service和Ingress实战

### 4.5.1 创建Service

```bash
# 创建Service
kubectl apply -f service-clusterip.yaml

# 输出：
# service/nginx-service created

# 查看Service
kubectl get services

# 输出：
# NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# nginx-service   ClusterIP   10.96.0.100    <none>        80/TCP,443/TCP   10s
# kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP          5m

# 查看Service详细信息
kubectl describe service nginx-service

# 输出：
# Name:              nginx-service
# Namespace:         default
# Labels:            app=nginx
#                    environment=production
# Annotations:       description: Nginx web server service
# Selector:          app=nginx
# Type:              ClusterIP
# IP Family Policy:  SingleStack
# IP Families:       IPv4
# IP:                10.96.0.100
# Port:              http  80/TCP
# TargetPort:        80/TCP
# Endpoints:         10.244.0.5:80,10.244.0.6:80,10.244.0.7:80
# Port:              https  443/TCP
# TargetPort:        443/TCP
# Endpoints:         10.244.0.5:443,10.244.0.6:443,10.244.0.7:443
# Session Affinity:  None
# Events:            <none>

# 测试Service
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- wget -O- http://nginx-service

# 输出：
# Connecting to nginx-service (10.96.0.100:80)
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# ...
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# ...
# </body>
# </html>
```

### 4.5.2 创建Ingress

```bash
# 创建Ingress
kubectl apply -f ingress-hostname.yaml

# 输出：
# ingress.networking.k8s.io/nginx-ingress created

# 查看Ingress
kubectl get ingress

# 输出：
# NAME            CLASS   HOSTS                      ADDRESS         PORTS     AGE
# nginx-ingress   nginx   app1.example.com,          192.168.1.100   80, 443   10s
#                         app2.example.com

# 查看Ingress详细信息
kubectl describe ingress nginx-ingress

# 输出：
# Name:             nginx-ingress
# Namespace:        default
# Labels:           app=nginx
#                   environment=production
# Annotations:      cert-manager.io/cluster-issuer: letsencrypt-prod
#                   nginx.ingress.kubernetes.io/rewrite-target: /
#                   nginx.ingress.kubernetes.io/ssl-redirect: true
# Ingress Class:    nginx
# Default backend:  <default>
# TLS:
#   app1-tls terminates app1.example.com
#   app2-tls terminates app2.example.com
# Rules:
#   Host                Path  Backends
#   ----                ----  --------
#   app1.example.com
#                       /   app1-service:80 (10.244.0.5:80,10.244.0.6:80,10.244.0.7:80)
#   app2.example.com
#                       /   app2-service:80 (10.244.0.8:80,10.244.0.9:80,10.244.0.10:80)
# Events:
#   Type    Reason  Age                From                      Message
#   ----    ------  ----               ----                      -------
#   Normal  Sync    10s (x2 over 10s)  nginx-ingress-controller  Scheduled for sync

# 测试Ingress
curl -H "Host: app1.example.com" http://192.168.1.100

# 输出：
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# ...
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# ...
# </body>
# </html>
```

### 4.5.3 删除Service和Ingress

```bash
# 删除Service
kubectl delete service nginx-service

# 输出：
# service "nginx-service" deleted

# 查看Service
kubectl get services

# 输出：
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5m

# 删除Ingress
kubectl delete ingress nginx-ingress

# 输出：
# ingress.networking.k8s.io "nginx-ingress" deleted

# 查看Ingress
kubectl get ingress

# 输出：
# No resources found in default namespace.
```

---

## 本章小结

- Service是Kubernetes中用于暴露应用的抽象
- Service提供稳定的服务发现和负载均衡
- Service类型包括ClusterIP、NodePort、LoadBalancer、ExternalName
- ClusterIP是默认类型，仅在集群内部可访问
- NodePort在每个节点上开放端口，支持外部访问
- LoadBalancer使用云厂商的负载均衡器，适合生产环境
- ExternalName返回CNAME记录，指向外部服务
- kube-proxy工作模式包括iptables、ipvs、nftables
- Ingress是用于HTTP/HTTPS路由的规则
- Ingress Controller实现Ingress规则，常见的有NGINX、Traefik、HAProxy、Envoy
- Ingress支持基于主机名和路径的路由
- Ingress支持TLS终止、URL重写、认证授权、限流熔断等高级功能
- 可以使用kubectl创建、查看、删除Service和Ingress
- 可以使用kubectl describe查看Service和Ingress详细信息

---

**下一章：ConfigMap和Secret**
