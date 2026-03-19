# ConfigMap和Secret深度解析

## 5.1 ConfigMap原理

### 5.1.1 ConfigMap的核心概念

```
ConfigMap的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  ConfigMap是什么？                                    │
└─────────────────────────────────────────────────────────────────┘

ConfigMap是Kubernetes中用于存储配置数据的对象：

1. 配置数据存储
   ├── 存储键值对
   ├── 存储配置文件
   ├── 存储环境变量
   └── 存储命令行参数

2. 配置注入
   ├── 注入为环境变量
   ├── 注入为命令行参数
   ├── 挂载为配置文件
   └── 注入为配置目录

3. 配置管理
   ├── 版本控制
   ├── 热更新
   ├── 配置共享
   └── 配置隔离

4. 配置分离
   ├── 配置与代码分离
   ├── 配置与镜像分离
   ├── 配置与部署分离
   └── 配置与环境分离

ConfigMap的优势：

1. 配置集中管理
   ├── 统一存储配置
   ├── 统一版本控制
   ├── 统一更新配置
   └── 统一审计配置

2. 配置热更新
   ├── 无需重启Pod
   ├── 自动更新配置
   ├── 实时生效
   └── 支持回滚

3. 配置共享
   ├── 多个Pod共享配置
   ├── 多个Namespace共享配置
   ├── 多个应用共享配置
   └── 跨集群共享配置

4. 配置隔离
   ├── 按Namespace隔离
   ├── 按应用隔离
   ├── 按环境隔离
   └── 按版本隔离
```

### 5.1.2 ConfigMap数据类型

```
ConfigMap数据类型：

┌─────────────────────────────────────────────────────────────────┐
│  ConfigMap数据类型                                    │
└─────────────────────────────────────────────────────────────────┘

1. 键值对（Key-Value）

特点：
├── 最简单的数据类型
├── 存储简单的配置
├── 支持多种数据格式
└── 易于使用

使用场景：
├── 环境变量
├── 命令行参数
├── 简单配置
└── 标志位

示例：
├── database.url=jdbc:mysql://localhost:3306/mydb
├── database.username=admin
├── database.password=secret
└── cache.enabled=true

2. 配置文件（Config File）

特点：
├── 存储完整的配置文件
├── 支持多种文件格式
├── 支持多行内容
└── 支持文件权限

使用场景：
├── 应用配置文件
├── Nginx配置
├── Apache配置
└── 其他配置文件

示例：
├── nginx.conf
├── application.properties
├── application.yml
└── config.json

3. 目录（Directory）

特点：
├── 存储多个配置文件
├── 挂载为目录
├── 保持文件结构
└── 支持子目录

使用场景：
├── 配置目录
├── 静态资源目录
├── 模板目录
└── 其他目录

示例：
├── /etc/nginx/
├── /etc/app/
├── /etc/config/
└── /etc/templates/
```

### 5.1.3 ConfigMap注入方式

```
ConfigMap注入方式：

┌─────────────────────────────────────────────────────────────────┐
│  ConfigMap注入方式                                    │
└─────────────────────────────────────────────────────────────────┘

1. 环境变量注入

方式：
├── 单个环境变量
├── 所有键值对
├── 从文件创建
└── 自定义名称

优点：
├── 简单直接
├── 易于使用
├── 支持所有容器
└── 兼容性好

缺点：
├── 不适合大配置
├── 不适合多行配置
├── 不适合二进制配置
└── 不支持热更新

2. 命令行参数注入

方式：
├── 引用环境变量
├── 引用ConfigMap键
├── 引用ConfigMap值
└── 组合多个参数

优点：
├── 灵活配置
├── 支持复杂参数
├── 支持动态参数
└── 易于调试

缺点：
├── 配置复杂
├── 需要容器支持
├── 不支持热更新
└── 难以管理

3. 配置文件挂载

方式：
├── 挂载单个文件
├── 挂载多个文件
├── 挂载整个目录
└── 挂载子路径

优点：
├── 支持大配置
├── 支持多行配置
├── 支持热更新
└── 保持文件结构

缺点：
├── 需要容器支持
├── 配置复杂
├── 权限管理
└── 路径管理

4. 配置目录挂载

方式：
├── 挂载整个目录
├── 挂载子目录
├── 只读挂载
└── 读写挂载

优点：
├── 支持多文件
├── 支持子目录
├── 支持热更新
└── 保持目录结构

缺点：
├── 需要容器支持
├── 配置复杂
├── 权限管理
└── 路径管理
```

---

## 5.2 Secret原理

### 5.2.1 Secret的核心概念

```
Secret的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Secret是什么？                                         │
└─────────────────────────────────────────────────────────────────┘

Secret是Kubernetes中用于存储敏感数据的对象：

1. 敏感数据存储
   ├── 存储密码
   ├── 存储密钥
   ├── 存储证书
   └── 存储Token

2. 数据加密
   ├── Base64编码
   ├── etcd加密
   ├── 传输加密
   └── 访问控制

3. 安全管理
   ├── RBAC权限控制
   ├── Namespace隔离
   ├── 审计日志
   └── 最小权限原则

4. 自动注入
   ├── 注入为环境变量
   ├── 挂载为文件
   ├── 注入为镜像拉取凭证
   └── 注入为ServiceAccount Token

Secret的优势：

1. 数据安全
   ├── 数据加密存储
   ├── 访问权限控制
   ├── 审计日志记录
   └── 最小权限原则

2. 自动管理
   ├── 自动创建Secret
   ├── 自动更新Secret
   ├── 自动注入Secret
   └── 自动轮换Secret

3. 集成度高
   ├── 与Kubernetes集成
   ├── 与容器运行时集成
   ├── 与ServiceAccount集成
   └── 与Ingress集成

4. 灵活性强
   ├── 支持多种数据类型
   ├── 支持多种注入方式
   ├── 支持多种加密方式
   └── 支持多种管理方式
```

### 5.2.2 Secret类型

```
Secret类型：

┌─────────────────────────────────────────────────────────────────┐
│  Secret类型                                            │
└─────────────────────────────────────────────────────────────────┘

1. Opaque（通用）

特点：
├── 最常见的类型
├── 存储任意敏感数据
├── Base64编码
└── 用户自定义

使用场景：
├── 数据库密码
├── API密钥
├── 访问令牌
└── 其他敏感数据

2. kubernetes.io/service-account-token

特点：
├── ServiceAccount Token
├── 自动创建
├── 自动挂载
└── 自动更新

使用场景：
├── Pod访问API Server
├── Pod访问其他资源
├── Pod执行操作
└── 身份认证

3. kubernetes.io/dockerconfigjson

特点：
├── Docker镜像拉取凭证
├── JSON格式
├── 自动创建
└── 自动使用

使用场景：
├── 拉取私有镜像
├── 拉取第三方镜像
├── 拉取自定义镜像
└── 镜像仓库认证

4. kubernetes.io/tls

特点：
├── TLS证书
├── 包含证书和密钥
├── 用于HTTPS
└── 用于TLS

使用场景：
├── Ingress TLS
├── Service TLS
├── Pod间TLS
└── 外部TLS

5. kubernetes.io/basic-auth

特点：
├── 基本认证
├── 包含用户名和密码
├── 用于HTTP认证
└── 用于其他认证

使用场景：
├── Ingress认证
├── Service认证
├── Pod间认证
└── 外部认证

6. kubernetes.io/ssh-auth

特点：
├── SSH认证
├── 包含SSH私钥
├── 用于SSH连接
└── 用于Git操作

使用场景：
├── Git仓库访问
├── SSH连接
├── 文件传输
└── 其他SSH操作

7. kubernetes.io/secret-bootstrap-token

特点：
├── Bootstrap Token
├── 用于节点加入
├── 自动创建
└── 自动使用

使用场景：
├── 节点加入集群
├── 集群初始化
├── 节点认证
└── 集群管理
```

### 5.2.3 Secret安全最佳实践

```
Secret安全最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  Secret安全最佳实践                                 │
└─────────────────────────────────────────────────────────────────┘

1. 最小权限原则

原则：
├── 只授予必要的权限
├── 只访问必要的Secret
├── 只在必要时使用Secret
└── 只在必要时创建Secret

实践：
├── 使用RBAC控制Secret访问
├── 使用Namespace隔离Secret
├── 使用Pod Security Policy限制
└── 使用Network Policy限制

2. Secret加密

原则：
├── 加密etcd中的Secret
├── 加密传输中的Secret
├── 加密存储中的Secret
└── 加密使用中的Secret

实践：
├── 启用etcd加密
├── 使用TLS传输
├── 使用加密存储
└── 使用加密算法

3. Secret轮换

原则：
├── 定期轮换Secret
├── 自动轮换Secret
├── 安全轮换Secret
└── 审计轮换Secret

实践：
├── 使用Secret管理工具
├── 使用自动化工具
├── 使用监控工具
└── 使用审计工具

4. Secret审计

原则：
├── 记录Secret创建
├── 记录Secret访问
├── 记录Secret修改
└── 记录Secret删除

实践：
├── 启用审计日志
├── 使用日志分析
├── 使用告警机制
└── 使用合规检查
```

---

## 5.3 ConfigMap配置

### 5.3.1 ConfigMap基本配置

```yaml
# configmap-basic.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application configuration"
data:
  database.url: "jdbc:mysql://localhost:3306/mydb"
  database.username: "admin"
  database.password: "secret"
  cache.enabled: "true"
  cache.ttl: "3600"
  log.level: "info"
  log.format: "json"
```

### 5.3.2 ConfigMap文件配置

```yaml
# configmap-files.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
  labels:
    app: nginx
    environment: production
  annotations:
    description: "Nginx configuration"
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        
        log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';
        
        access_log /var/log/nginx/access.log main;
        
        sendfile on;
        tcp_nopush on;
        keepalive_timeout 65;
        
        include /etc/nginx/conf.d/*.conf;
    }
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }
```

### 5.3.3 ConfigMap从文件创建

```bash
# 从文件创建ConfigMap
kubectl create configmap app-config --from-file=config.properties

# 输出：
# configmap/app-config created

# 从目录创建ConfigMap
kubectl create configmap nginx-config --from-file=/etc/nginx/

# 输出：
# configmap/nginx-config created

# 从环境变量文件创建ConfigMap
kubectl create configmap app-env --from-env-file=env.list

# 输出：
# configmap/app-env created

# 从字面值创建ConfigMap
kubectl create configmap app-literal --from-literal=database.url=jdbc:mysql://localhost:3306/mydb --from-literal=database.username=admin

# 输出：
# configmap/app-literal created
```

---

## 5.4 Secret配置

### 5.4.1 Secret基本配置

```yaml
# secret-basic.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application secret"
type: Opaque
data:
  database.username: YWRtaW4=
  database.password: c2VjcmV0
  api.key: YXBpLWtleS0xMjM0NTY3ODkw
  api.secret: YXBpLXNlY3JldC0xMjM0NTY3ODkw
```

### 5.4.2 Secret TLS配置

```yaml
# secret-tls.yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "TLS certificate"
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...
  tls.key: LS0tLS1CRUdJTi...
```

### 5.4.3 Secret Docker配置

```yaml
# secret-dockerconfig.yaml
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry-secret
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Docker registry secret"
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6eyJyZWdpc3RyeS5leGFtcGxlLmNvbSI6eyJ1c2VybmFtZSI6ImFkbWluIiwicGFzc3dvcmQiOiJzZWNyZXQiLCJhdXRoIjoiYWRtaW46c2VjcmV0In19fQ==
```

### 5.4.4 Secret从文件创建

```bash
# 从文件创建Secret
kubectl create secret generic app-secret --from-file=username.txt --from-file=password.txt

# 输出：
# secret/app-secret created

# 从TLS证书创建Secret
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key

# 输出：
# secret/tls-secret created

# 从Docker配置创建Secret
kubectl create secret docker-registry docker-registry-secret --docker-server=registry.example.com --docker-username=admin --docker-password=secret --docker-email=admin@example.com

# 输出：
# secret/docker-registry-secret created

# 从字面值创建Secret
kubectl create secret generic app-literal --from-literal=username=admin --from-literal=password=secret

# 输出：
# secret/app-literal created
```

---

## 5.5 ConfigMap和Secret实战

### 5.5.1 使用ConfigMap注入环境变量

```yaml
# pod-configmap-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
  namespace: default
  labels:
    app: configmap-env
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.url
    - name: DATABASE_USERNAME
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.username
    - name: CACHE_ENABLED
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: cache.enabled
    - name: CACHE_TTL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: cache.ttl
    envFrom:
    - configMapRef:
        name: app-config
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
```

### 5.5.2 使用Secret注入环境变量

```yaml
# pod-secret-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
  namespace: default
  labels:
    app: secret-env
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    env:
    - name: DATABASE_USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: database.username
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: database.password
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: api.key
    envFrom:
    - secretRef:
        name: app-secret
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
```

### 5.5.3 使用ConfigMap挂载配置文件

```yaml
# pod-configmap-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
  namespace: default
  labels:
    app: configmap-volume
    environment: production
spec:
  containers:
  - name: nginx
    image: nginx:1.25.0
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    - name: nginx-config
      mountPath: /etc/nginx/conf.d/default.conf
      subPath: default.conf
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
      items:
      - key: nginx.conf
        path: nginx.conf
      - key: default.conf
        path: default.conf
```

### 5.5.4 使用Secret挂载配置文件

```yaml
# pod-secret-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
  namespace: default
  labels:
    app: secret-volume
    environment: production
spec:
  containers:
  - name: nginx
    image: nginx:1.25.0
    volumeMounts:
    - name: tls-secret
      mountPath: /etc/nginx/tls
      readOnly: true
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  volumes:
  - name: tls-secret
    secret:
      secretName: tls-secret
      defaultMode: 0600
```

---

## 本章小结

- ConfigMap是Kubernetes中用于存储配置数据的对象
- ConfigMap支持键值对、配置文件、目录等多种数据类型
- ConfigMap可以通过环境变量、命令行参数、配置文件、配置目录等方式注入
- ConfigMap支持热更新，无需重启Pod
- Secret是Kubernetes中用于存储敏感数据的对象
- Secret类型包括Opaque、ServiceAccount Token、Docker Config、TLS、Basic Auth、SSH Auth、Bootstrap Token等
- Secret使用Base64编码，支持etcd加密
- Secret支持RBAC权限控制、Namespace隔离、审计日志等安全机制
- Secret安全最佳实践包括最小权限原则、Secret加密、Secret轮换、Secret审计等
- 可以使用kubectl创建、查看、更新、删除ConfigMap和Secret
- 可以使用kubectl describe查看ConfigMap和Secret详细信息

---

**下一章：PersistentVolume和PersistentVolumeClaim**
