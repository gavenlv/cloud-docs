# kubectl配置详解

## 本章导学

**学完本章后，你将能够：**

- 从**底层原理**理解kubeconfig的配置结构和加载机制
- 从**认证机制**理解Kubernetes的各种认证方式
- 从**多集群管理**理解上下文和用户的配置方法
- 掌握kubectl的高效配置技巧和常用别名的设置
- 解决kubectl配置相关的常见问题

**学习方法：**

```
原理 → 配置结构 → 认证机制 → 实战配置 → 常见误区
```

---

# kubectl配置核心原理

## 1.1 kubectl是什么？

### 1.1.1 kubectl的定位

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubectl在Kubernetes架构中的位置                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         用户                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    kubectl CLI                          │    │
│  │  ├── 命令行解析                                        │    │
│  │  ├── 生成API请求                                       │    │
│  │  ├── 处理认证                                          │    │
│  │  └── 格式化输出                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Kubernetes API Server                 │    │
│  │  ├── RESTful API                                       │    │
│  │  ├── 认证(Authentication)                              │    │
│  │  ├── 授权(Authorization)                               │    │
│  │  └── 准入控制(Admission Control)                        │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

kubectl是Kubernetes集群的客户端工具，负责：
1. 接收用户命令
2. 生成对应的API请求
3. 处理认证信息
4. 发送请求到API Server
5. 格式化并展示响应结果
```

### 1.1.2 kubectl工作原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubectl请求处理流程                           │
└─────────────────────────────────────────────────────────────────┘

kubectl get pods -n default

Step 1: 命令解析
└── 解析命令：动作=get，资源类型=pods，命名空间=default

Step 2: 配置加载
└── 读取kubeconfig文件，找到当前上下文

Step 3: 构建请求
└── 生成GET /api/v1/namespaces/default/pods请求

Step 4: 认证处理
└── 从kubeconfig提取证书/令牌，添加到请求头

Step 5: 发送请求
└── HTTPS请求到API Server地址

Step 6: 处理响应
└── 解析JSON响应，格式化输出表格
```

---

## 1.2 kubeconfig配置原理

### 1.2.1 kubeconfig文件结构

```yaml
# kubeconfig文件是YAML格式，包含三部分：clusters、users、contexts

apiVersion: v1
kind: Config

# 集群配置 - 定义Kubernetes集群信息
clusters:
- name: kubernetes                  # 集群名称（唯一标识）
  cluster:
    certificate-authority-data: xxx # Base64编码的CA证书
    # 或者使用本地CA文件：
    # certificate-authority: /path/to/ca.crt
    server: https://192.168.1.100:6443  # API Server地址

# 用户配置 - 定义认证信息
users:
- name: kubernetes-admin           # 用户名称（唯一标识）
  user:
    # 方式1：客户端证书认证
    client-certificate-data: xxx    # Base64编码的客户端证书
    client-key-data: xxx            # Base64编码的客户端私钥
    # 或者使用本地证书文件：
    # client-certificate: /path/to/admin.crt
    # client-key: /path/to/admin.key

    # 方式2：Token认证
    # token: xxxxxxxxxxxxxxxxxxxxxxxx

    # 方式3：用户名密码（不推荐）
    # username: admin
    # password: password

# 上下文配置 - 关联集群、用户和命名空间
contexts:
- name: kubernetes-admin@kubernetes  # 上下文名称（唯一标识）
  context:
    cluster: kubernetes              # 引用的集群名称
    user: kubernetes-admin          # 引用的用户名称
    namespace: default              # 默认命名空间（可选）
```

### 1.2.2 kubeconfig加载机制

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubeconfig加载顺序（优先级从低到高）                   │
└─────────────────────────────────────────────────────────────────┘

1. /etc/kubernetes/admin.conf（集群管理员配置）
   └── 最高优先级，系统级别配置

2. $HOME/.kube/config（用户默认配置）
   └── 用户主目录下的配置，最常用

3. KUBECONFIG环境变量指定的配置文件
   └── 可以指定多个文件，用冒号分隔
   └── 例如：export KUBECONFIG=/path/to/config1:/path/to/config2

┌─────────────────────────────────────────────────────────────────┐
│                    KUBECONFIG环境变量详解                        │
└─────────────────────────────────────────────────────────────────┘

# 指定单个配置文件
export KUBECONFIG=~/.kube/config

# 指定多个配置文件（会合并）
export KUBECONFIG=~/.kube/config:/path/to/dev-config:/path/to/prod-config

# 查看当前使用的配置
kubectl config view --merged
kubectl config view --flatten  # 展平合并后的配置

# 临时指定配置
KUBECONFIG=/path/to/config kubectl get pods
```

### 1.2.3 kubeconfig字段详解

```bash
# 查看当前完整配置
kubectl config view

# 查看简写格式
kubectl config view -o yaml

# 查看原始格式（包含证书等敏感信息）
kubectl config view --raw

# 查看特定文件
kubectl config view --kubeconfig=/path/to/config

# 输出到文件
kubectl config view --flatten > ~/.kube/config
```

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubeconfig各字段说明                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  clusters[] - 集群配置                                           │
├─────────────────────────────────────────────────────────────────┤
│  cluster.certificate-authority-data                             │
│  └── Base64编码的CA证书，用于验证服务端证书                       │
│  cluster.certificate-authority                                  │
│  └── CA证书文件路径，与data互斥                                  │
│  cluster.server                                                  │
│  └── API Server的HTTPS地址，必须是完整的URL                      │
│  cluster.insecure-skip-tls-verify                                │
│  └── 跳过TLS验证（仅用于测试，不推荐）                           │
├─────────────────────────────────────────────────────────────────┤
│  users[] - 用户配置                                              │
├─────────────────────────────────────────────────────────────────┤
│  user.client-certificate-data                                    │
│  └── Base64编码的客户端证书                                      │
│  user.client-key-data                                            │
│  └── Base64编码的客户端私钥（通常加密存储）                      │
│  user.token                                                      │
│  └── Bearer Token字符串                                          │
│  user.username / user.password                                   │
│  └── 基本认证凭据（不推荐）                                      │
├─────────────────────────────────────────────────────────────────┤
│  contexts[] - 上下文配置                                          │
├─────────────────────────────────────────────────────────────────┤
│  context.cluster                                                  │
│  └── 引用的集群名称                                              │
│  context.user                                                    │
│  └── 引用的用户名称                                              │
│  context.namespace                                               │
│  └── 该上下文下的默认命名空间                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.3 kubectl配置实战

### 1.3.1 基础配置

```bash
# 1. 创建kubeconfig目录
mkdir -p ~/.kube

# 2. 使用kubectl生成集群配置
# 方式1：从集群获取配置（需要集群管理员）
kubectl config --kubeconfig=/path/to/config view

# 方式2：手动创建kubeconfig
cat > ~/.kube/config << 'EOF'
apiVersion: v1
kind: Config
clusters:
- name: my-cluster
  cluster:
    server: https://192.168.1.100:6443
    certificate-authority-data: <base64-encoded-ca>
users:
- name: my-user
  user:
    client-certificate-data: <base64-encoded-cert>
    client-key-data: <base64-encoded-key>
contexts:
- name: my-context
  context:
    cluster: my-cluster
    user: my-user
    namespace: default
current-context: my-context
EOF

# 3. 验证配置
kubectl config get-contexts
kubectl cluster-info
```

### 1.3.2 多集群配置

```bash
# 场景：管理多个Kubernetes集群

# 集群1：开发环境
clusters:
- name: dev-cluster
  cluster:
    server: https://dev.k8s.example.com:6443
    certificate-authority-data: <dev-ca>

users:
- name: dev-user
  user:
    token: <dev-token>

contexts:
- name: dev-admin@dev-cluster
  context:
    cluster: dev-cluster
    user: dev-user
    namespace: dev-namespace

# 集群2：生产环境
clusters:
- name: prod-cluster
  cluster:
    server: https://prod.k8s.example.com:6443
    certificate-authority-data: <prod-ca>

users:
- name: prod-user
  user:
    token: <prod-token>

contexts:
- name: prod-admin@prod-cluster
  context:
    cluster: prod-cluster
    user: prod-user
    namespace: production

# 切换上下文
kubectl config use-context dev-admin@dev-cluster
kubectl config use-context prod-admin@prod-cluster

# 查看所有上下文
kubectl config get-contexts
# 输出：
# CURRENT   NAME                    CLUSTER         AUTHINFO       NAMESPACE
# *         dev-admin@dev-cluster   dev-cluster     dev-user       dev-namespace
#           prod-admin@prod-cluster prod-cluster    prod-user      production
```

### 1.3.3 minikube配置

```bash
# minikube自动配置

# 启动minikube后，配置自动写入~/.kube/config
minikube start

# 查看生成的配置
kubectl config view

# 查看minikube的上下文
kubectl config get-contexts
# 输出：
# CURRENT   NAME                   CLUSTER        AUTHINFO      NAMESPACE
# *         minikube               minikube       minikube      default

# 使用minikube的kubeconfig
kubectl config use-context minikube

# 删除minikube配置
minikube delete
# 或者手动删除
kubectl config delete-context minikube
kubectl config delete-cluster minikube
kubectl config delete-user minikube
```

### 1.3.4 kind配置

```bash
# kind（Kubernetes in Docker）配置

# 创建集群
kind create cluster --name my-cluster

# 查看kind生成的配置
kubectl config view

# kind的上下文名称
kubectl config get-contexts
# 输出：
# CURRENT   NAME                   CLUSTER        AUTHINFO       NAMESPACE
# *         kind-my-cluster         kind-my-cluster kind-my-cluster default

# 多个kind集群
kind create cluster --name cluster1
kind create cluster --name cluster2

# 切换集群
kubectl config use-context kind-cluster1
kubectl config use-context kind-cluster2

# 查看所有kind集群
kind get clusters
```

---

## 1.4 kubectl认证机制

### 1.4.1 证书认证原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes证书认证流程                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    证书认证架构                                  │
└─────────────────────────────────────────────────────────────────┘

1. 证书生成
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CA (Certificate Authority)                                      │
│  ├── Kubernetes集群创建时自动生成                               │
│  ├── 位于/etc/kubernetes/pki/                                  │
│  │   ├── ca.crt / ca.key (Kubernetes API Server CA)           │
│  │   ├── apiserver.crt / apiserver.key                        │
│  │   └── etcd相关证书                                           │
│  └── 用于签发其他证书                                           │
│                                                                  │
│  Admin证书生成流程：                                             │
│  1. 创建私钥：openssl genrsa -out admin.key 2048               │
│  2. 创建CSR：openssl req -new -key admin.key -out admin.csr     │
│  3. 使用CA签发：openssl x509 -req -in admin.csr \             │
│                 -CA ca.crt -CAkey ca.key \                     │
│                 -out admin.crt -days 365                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

2. 证书验证
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  客户端请求流程：                                                 │
│                                                                  │
│  Client                                                  API Server│
│    │                                                          ││
│    │  1. 发送证书                                              ││
│    │ ─────────────────────────────────────────────────────────>││
│    │                                                          ││
│    │  2. API Server使用CA验证证书签名                          ││
│    │                                                          ││
│    │  3. 验证证书有效期                                        ││
│    │                                                          ││
│    │  4. 验证证书CN作为用户名                                  ││
│    │     CN=admin -> 用户名=admin                             ││
│    │                                                          ││
│    │  5. 验证证书O作为组                                      ││
│    │     O=system:masters -> 组=system:masters               ││
│    │                                                          ││
│    │  6. 返回认证结果                                          ││
│    │ <─────────────────────────────────────────────────────────││
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4.2 Token认证原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    ServiceAccount Token认证                       │
└─────────────────────────────────────────────────────────────────┘

1. ServiceAccount创建时自动生成Token
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  # 自动创建Secret包含Token                                      │
│  apiVersion: v1                                                 │
│  kind: ServiceAccount                                           │
│  metadata:                                                      │
│    name: my-app                                                 │
│                                                                  │
│  # 自动创建对应的Secret                                         │
│  apiVersion: v1                                                 │
│  kind: Secret                                                   │
│  metadata:                                                      │
│    name: my-app-token-xxxxx                                    │
│    annotations:                                                 │
│      kubernetes.io/service-account.name: my-app                │
│  type: kubernetes.io/service-account-token                     │
│  data:                                                          │
│    token: <JWT Token>                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

2. JWT Token结构
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  JWT = Header.Payload.Signature                                 │
│                                                                  │
│  Header:                                                        │
│  {                                                              │
│    "alg": "RS256",            // 签名算法                        │
│    "typ": "JWT"               // Token类型                       │
│  }                                                              │
│                                                                  │
│  Payload (Claims):                                               │
│  {                                                              │
│    "iss": "kubernetes/serviceaccounts",  // 签发者              │
│    "sub": "system:serviceaccounts:default:my-app",  // 主题     │
│    "aud": "https://kubernetes.default.svc",  // 受众             │
│    "exp": 1234567890,              // 过期时间                   │
│    "iat": 1234567890,              // 签发时间                   │
│    "kubernetes.io/service-account": "my-app",                  │
│    "namespace": "default"           // 命名空间                   │
│  }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

3. Token认证流程
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Pod                                    API Server               │
│    │                                      │                     │
│    │  1. 使用ServiceAccount Token         │                     │
│    │ ──────────────────────────────────────>                    │
│    │                                      │                     │
│    │  2. API Server验证JWT签名            │                     │
│    │     （使用ServiceAccount公钥）       │                     │
│    │                                      │                     │
│    │  3. 验证Claims                        │                     │
│    │     - issuer验证                     │                     │
│    │     - expiration验证                 │                     │
│    │     - audience验证                   │                     │
│    │                                      │                     │
│    │  4. 提取用户信息                      │                     │
│    │     - subject -> system:serviceaccount:namespace:name     │
│    │                                      │                     │
│    │  5. 授权检查                          │                     │
│    │     - RBAC检查权限                   │                     │
│    │                                      │                     │
│    │  6. 返回结果                          │                     │
│    │ <──────────────────────────────────────                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4.3 OIDC认证原理

```
┌─────────────────────────────────────────────────────────────────┐
│                    OIDC (OpenID Connect) 认证                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    OIDC认证流程                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  User            kubectl            IDP              API Server │
│   │                 │               │                     │      │
│   │  1. kubectl login │             │                     │      │
│   │ <────────────────               │                     │      │
│   │                 │               │                     │      │
│   │  2. 打开浏览器  │               │                     │      │
│   │ ────────────────────────────────>                    │      │
│   │                 │               │                     │      │
│   │  3. 用户登录    │               │                     │      │
│   │ <───────────────────────────────>                    │      │
│   │                 │               │                     │      │
│   │  4. 返回ID Token│               │                     │      │
│   │ <───────────────────────────────                     │      │
│   │                 │               │                     │      │
│   │  5. kubectl使用 │ ID Token      │                     │      │
│   │                 │ ──────────────────────────────────────>  │
│   │                 │               │                     │      │
│   │                 │               │  6. 验证Token       │      │
│   │                 │               │     (OIDC JWKS)    │      │
│   │                 │               │ <────────────────────>   │
│   │                 │               │                     │      │
│   │                 │               │                     │  7. 返回用户信息│
│   │                 │               │                     │ <──│
│   │                 │  8. 授权成功   │                     │      │
│   │ <──────────────────────────────────────                 │      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

配置示例：
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  # kubeconfig配置                                               │
│  users:                                                         │
│  - name: oidc-user                                              │
│    user:                                                        │
│      auth-provider:                                             │
│        name: oidc                                               │
│        config:                                                  │
│          issuer: https://idp.example.com                        │
│          client-id: kubectl                                     │
│          client-secret: xxxxxxxxxx                              │
│          refresh-token: xxxxxxxxxx                              │
│          id-token: xxxxxxxxxx                                    │
│          idp-certificate-authority: /path/to/ca.crt            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.5 kubectl高效配置

### 1.5.1 kubectl常用别名

```bash
# ~/.bashrc 或 ~/.zshrc 添加别名

# Kubernetes别名
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kc='kubectl create'
alias ke='kubectl edit'
alias kdel='kubectl delete'
alias kex='kubectl exec -it'

# 常用资源别名
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kgpv='kubectl get persistentvolumes'
alias kgpvc='kubectl get persistentvolumeclaims'

# 带命名空间的别名
alias kgpa='kubectl get pods -A'           # 所有命名空间
alias kgpn='kubectl get pods -n'           # 指定命名空间
alias kgpao='kubectl get pods -A -o wide' # 所有命名空间+详细信息

# 日志和端口转发
alias klog='kubectl logs'
alias kfol='kubectl follow logs'
alias kpf='kubectl port-forward'

# 应用相关
alias kapp='kubectl apply -f'
alias kappk='kubectl apply -k'
alias kdry='kubectl apply --dry-run=server'

# 上下文和配置
alias kctx='kubectl config use-context'
alias kcurrent='kubectl config current-context'
alias kcg='kubectl config get-contexts'

# 实用组合
alias kga='kubectl get all'
alias kgal='kubectl get all -l'            # 按标签筛选
alias kgaA='kubectl get all -A'
alias kdp='kubectl delete pod --force --grace-period=0'  # 强制删除Pod

# 格式化输出
alias kgpo='kubectl get pods -o wide'
alias kgow='kubectl get pods -o yaml'
alias kgj='kubectl get pods -o json'

# 快速编辑和查看
alias kei='kubectl explain'
alias kri='kubectl rollout restart'
```

### 1.5.2 kubectl自动补全

```bash
# 安装bash自动补全（Linux）
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)

# 永久生效
echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc

# 安装zsh自动补全
source <(kubectl completion zsh)

# 永久生效
echo "source <(kubectl completion zsh)" >> ~/.zshrc

# macOS + homebrew
brew install bash-completion
source $(brew --prefix)/etc/bash_completion
source <(kubectl completion bash)
```

### 1.5.3 kubectl配置技巧

```bash
# 1. 默认命名空间设置
kubectl config set-context --current --namespace=my-namespace

# 2. 快速切换命名空间（使用kubens）
# 安装：brew install kubectx
kubens my-namespace
kubens kube-system

# 3. 快速切换集群（使用kubectx）
kubectx dev-cluster
kubectx prod-cluster

# 4. 查看当前配置
kubectl config view --minify

# 5. 设置命名空间别名（添加到~/.bashrc）
alias kn='kubectl config set-context --current --namespace '
# 使用：kn mynamespace

# 6. kubectx和kubens安装
# Linux
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# macOS
brew install kubectx
brew install kubenames  # 或 brew install kubectx（已包含）

# 7. kubectl历史命令优化
# 使用stern进行日志追踪
brew install stern
stern my-pod

# 使用kail进行日志追踪
brew install kail
kail -n my-namespace

# 8. kubectl插件管理
# 安装krew插件管理器
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  Arch="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*/arm/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${Arch}" &&
  "${KREW}" install krew
)

# 添加到PATH
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# 安装常用插件
kubectl krew install ctx
kubectl krew install ns
kubectl krew install resource-terms
kubectl krew install node-shell
kubectl krew install debug
```

### 1.5.4 kubectl输出格式化

```bash
# 常用输出格式

# 1. 宽表格式
kubectl get pods -o wide

# 2. YAML格式
kubectl get pod my-pod -o yaml

# 3. JSON格式
kubectl get pod my-pod -o json

# 4. 自定义列
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# 5. JSONPath
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# 6. 标签选择器
kubectl get pods -l app=myapp,version=v1

# 7. 字段选择器（Beta）
kubectl get pods --field-selector status.phase=Running

# 8. 排序输出
kubectl get pods --sort-by=.metadata.creationTimestamp

# 9. 显示标签
kubectl get pods --show-labels

# 10. watch模式
kubectl get pods -w
kubectl get pods --watch
```

---

## 1.6 常见问题与解决

### 1.6.1 配置找不到

```
问题：The connection to the server localhost:8080 was refused

原因：
1. kubeconfig文件不存在或路径错误
2. API Server地址配置错误
3. kubectl未正确配置

解决方案：
┌─────────────────────────────────────────────────────────────────┐
│  1. 检查kubeconfig是否存在                                      │
└─────────────────────────────────────────────────────────────────┘

ls -la ~/.kube/config

# 如果不存在，创建或获取
# 从集群获取：admin.conf
scp root@<master-ip>:/etc/kubernetes/admin.conf ~/.kube/config

# 设置正确的路径
export KUBECONFIG=~/.kube/config

┌─────────────────────────────────────────────────────────────────┐
│  2. 检查API Server地址                                          │
└─────────────────────────────────────────────────────────────────┘

kubectl config view

# 查看cluster配置
# 确保server地址正确（不是localhost）

┌─────────────────────────────────────────────────────────────────┐
│  3. 检查集群状态                                                │
└─────────────────────────────────────────────────────────────────┘

# 如果使用minikube
minikube status
minikube start

# 如果使用kind
kind get clusters
kind delete cluster && kind create cluster

# 如果是真实集群
ssh <master-ip> "systemctl status kubelet"
```

### 1.6.2 证书过期

```
问题：Unable to connect to the server: x509: certificate has expired or is not yet valid

原因：证书已过期

解决方案：
┌─────────────────────────────────────────────────────────────────┐
│  1. 检查证书有效期                                              │
└─────────────────────────────────────────────────────────────────┘

# 查看kubeconfig中的证书
kubectl config view --raw | grep -A 5 "certificate-authority-data"

# 解码查看
echo "<certificate-authority-data>" | base64 -d | openssl x509 -text -noout | grep -A 2 "Validity"

┌─────────────────────────────────────────────────────────────────┐
│  2. 更新kubeconfig                                              │
└─────────────────────────────────────────────────────────────────┘

# 从API Server重新获取（需要管理员权限）
kubectl config view --flatten > ~/.kube/config.new

# 或重新生成admin证书
ssh <master-ip>
cd /etc/kubernetes/pki
# 备份旧证书
cp admin.conf admin.conf.bak
# 重新生成
kubeadm init phase kubeconfig admin --apiserver-advertise-address <ip>
# 复制回来
exit
scp root@<master-ip>:/etc/kubernetes/admin.conf ~/.kube/config

┌─────────────────────────────────────────────────────────────────┐
│  3. 永久解决方案：更新集群证书                                   │
└─────────────────────────────────────────────────────────────────┘

# Kubernetes 1.19+ 使用kubeadm重新生成证书
ssh <master-ip>
kubeadm certs renew all
systemctl restart kubelet
```

### 1.6.3 上下文冲突

```
问题：切换上下文后操作了错误的集群

原因：
1. 多个kubeconfig配置冲突
2. KUBECONFIG环境变量配置了多个文件
3. 没有确认当前上下文

解决方案：
┌─────────────────────────────────────────────────────────────────┐
│  1. 查看当前上下文（每次操作前必看）                             │
└─────────────────────────────────────────────────────────────────┘

kubectl config current-context
# 或
kubectl ctx

# 查看所有上下文
kubectl config get-contexts

┌─────────────────────────────────────────────────────────────────┐
│  2. 清理KUBECONFIG环境变量                                      │
└─────────────────────────────────────────────────────────────────┘

# 查看当前KUBECONFIG
echo $KUBECONFIG

# 清理，只保留需要的配置
export KUBECONFIG=~/.kube/config

# 或清空后只设置一个
unset KUBECONFIG

┌─────────────────────────────────────────────────────────────────┐
│  3. 使用kubectx进行安全切换                                     │
└─────────────────────────────────────────────────────────────────┘

# 查看所有上下文和集群
kubectx

# 切换前确认
kubectx <context-name>

# 查看上下文详细信息
kubectl config view --context=<context-name>
```

### 1.6.4 权限不足

```
问题：Error from server (Forbidden): pods is forbidden: User "system:anonymous" cannot list resource "pods"

原因：
1. 未正确认证
2. 证书用户没有相应权限
3. RBAC配置错误

解决方案：
┌─────────────────────────────────────────────────────────────────┐
│  1. 检查当前用户                                                │
└─────────────────────────────────────────────────────────────────┘

# 使用cluster-admin角色测试
kubectl auth can-i '*' '*' --as=system:admin

# 查看当前用户信息
kubectl config view

┌─────────────────────────────────────────────────────────────────┐
│  2. 重新生成admin配置                                           │
└─────────────────────────────────────────────────────────────────┘

# 在master节点执行
kubeadm kubeconfig user --org system:masters --client-name admin

# 或使用cluster-admin
kubectl config view --raw > ~/.kube/config

┌─────────────────────────────────────────────────────────────────┐
│  3. 检查RBAC配置                                                │
└─────────────────────────────────────────────────────────────────┘

# 查看ClusterRoleBinding
kubectl get clusterrolebinding -A

# 查看用户角色绑定
kubectl get rolebinding -A -o wide
```

---

## 1.7 本章小结

- kubectl是Kubernetes的客户端工具，通过kubeconfig文件配置集群连接信息
- kubeconfig包含clusters、users、contexts三部分，支持多集群配置
- 认证方式包括证书认证、Token认证、OIDC认证等
- kubectl支持多种输出格式和自动补全，可通过别名提高效率
- 常见问题包括配置找不到、证书过期、上下文冲突、权限不足等

---

**下一章：深入Pod管理**
