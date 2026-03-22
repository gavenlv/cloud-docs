# Helm包管理深度解析

## 8.1 Helm原理

### 8.1.1 Helm的核心概念

```
Helm的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Helm是什么？                                           │
└─────────────────────────────────────────────────────────────────┘

Helm是Kubernetes的包管理器：

1. 包管理
   ├── 打包Kubernetes资源
   ├── 版本管理
   ├── 依赖管理
   └── 分发管理

2. 模板引擎
   ├── Go模板语法
   ├── 变量替换
   ├── 条件判断
   └── 循环迭代

3. 配置管理
   ├── Values文件
   ├── 环境配置
   ├── 默认配置
   └── 自定义配置

4. 生命周期管理
   ├── 安装
   ├── 升级
   ├── 回滚
   └── 卸载

Helm的优势：

1. 简化部署
   ├── 一键部署复杂应用
   ├── 自动处理依赖关系
   ├── 自动配置资源
   └── 自动管理生命周期

2. 版本管理
   ├── 支持版本控制
   ├── 支持版本回滚
   ├── 支持版本历史
   └── 支持版本比较

3. 配置灵活
   ├── 支持多环境配置
   ├── 支持自定义配置
   ├── 支持配置覆盖
   └── 支持配置验证

4. 生态丰富
   ├── 官方Chart仓库
   ├── 社区Chart仓库
   ├── 自定义Chart仓库
   └── Chart共享和复用
```

### 8.1.2 Chart结构

```
Chart结构：

┌─────────────────────────────────────────────────────────────────┐
│  Chart结构                                              │
└─────────────────────────────────────────────────────────────────┘

myapp/
├── Chart.yaml              # Chart元数据
├── values.yaml             # 默认配置值
├── values.schema.json       # 配置验证模式
├── charts/                # 依赖Chart
│   └── postgresql/
│       ├── Chart.yaml
│       └── values.yaml
├── templates/             # 模板文件
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── pvc.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   ├── _helpers.tpl       # 模板助手
│   └── NOTES.txt         # 安装说明
├── templates/tests/        # 测试文件
│   └── test-connection.yaml
├── .helmignore            # 忽略文件
├── .helmignore           # 忽略文件
└── README.md             # Chart说明

Chart.yaml：

apiVersion: v2
name: myapp
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - myapp
  - kubernetes
maintainers:
  - name: John Doe
    email: john@example.com
engine: gotpl
icon: https://example.com/icon.png
home: https://example.com
sources:
  - https://github.com/example/myapp
dependencies:
  - name: postgresql
    version: 12.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    alias: db

values.yaml：

replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25.0"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext: {}

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources: {}

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

postgresql:
  enabled: true
  auth:
    postgresPassword: "secret"
    database: "myapp"
```

### 8.1.3 模板引擎

```
模板引擎：

┌─────────────────────────────────────────────────────────────────┐
│  Go模板语法                                             │
└─────────────────────────────────────────────────────────────────┘

1. 变量替换

语法：
├── {{ .Values.replicaCount }}
├── {{ .Values.image.repository }}
├── {{ .Values.image.tag }}
└── {{ .Release.Name }}

示例：
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}

2. 条件判断

语法：
├── {{ if .Values.ingress.enabled }}
├── {{ else if .Values.ingress.enabled }}
├── {{ else }}
└── {{ end }}

示例：
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "myapp.fullname" $ }}
                port:
                  number: {{ .Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}

3. 循环迭代

语法：
├── {{ range .Values.items }}
├── {{ end }}
├── {{ range $key, $value := .Values.items }}
└── {{ end }}

示例：
{{- range .Values.nodeSelector }}
{{ .key }}: {{ .value }}
{{- end }}

{{- range $key, $value := .Values.nodeSelector }}
{{ $key }}: {{ $value }}
{{- end }}

4. 管道函数

语法：
├── {{ .Values.image.tag | default .Chart.AppVersion }}
├── {{ .Values.replicaCount | quote }}
├── {{ .Values.annotations | toYaml }}
└── {{ .Values.labels | nindent 4 }}

示例：
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
replicas: {{ .Values.replicaCount }}
annotations:
  {{- toYaml .Values.podAnnotations | nindent 4 }}
```

### 8.1.4 Values文件

```
Values文件：

┌─────────────────────────────────────────────────────────────────┐
│  Values文件管理                                          │
└─────────────────────────────────────────────────────────────────┘

1. 默认Values

values.yaml：
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25.0"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []

2. 环境Values

values-dev.yaml：
replicaCount: 1

image:
  tag: "1.25.0-dev"

service:
  type: NodePort

ingress:
  enabled: false

values-staging.yaml：
replicaCount: 2

image:
  tag: "1.25.0-staging"

service:
  type: ClusterIP

ingress:
  enabled: true
  hosts:
    - host: staging.example.com
      paths:
        - path: /
          pathType: Prefix

values-prod.yaml：
replicaCount: 3

image:
  tag: "1.25.0"

service:
  type: ClusterIP

ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls

3. 自定义Values

custom-values.yaml：
replicaCount: 5

image:
  repository: custom-registry.example.com/nginx
  tag: "1.25.0-custom"

service:
  type: LoadBalancer

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: custom.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - custom.example.com
      secretName: custom-tls

4. Values优先级

优先级从高到低：
├── --set / --set-file / --set-string
├── -f / --values
├── values.yaml
└── Chart默认值

示例：
helm install myapp ./myapp \
  --values values-prod.yaml \
  --set replicaCount=5 \
  --set image.tag=1.25.0-custom
```

---

## 8.2 Chart创建

### 8.2.1 创建Chart

```bash
# 创建Chart
helm create myapp

# 输出：
# Creating myapp

# 查看Chart结构
tree myapp

# 输出：
# myapp/
# ├── Chart.yaml
# ├── charts/
# ├── .helmignore
# ├── values.yaml
# ├── templates/
# │   ├── deployment.yaml
# │   ├── _helpers.tpl
# │   ├── ingress.yaml
# │   ├── NOTES.txt
# │   ├── serviceaccount.yaml
# │   ├── service.yaml
# │   └── tests/
# │       └── test-connection.yaml
# └── README.md

# 查看Chart.yaml
cat myapp/Chart.yaml

# 输出：
# apiVersion: v2
# name: myapp
# description: A Helm chart for Kubernetes
# 
# # A chart can be either an 'application' or a 'library' chart.
# #
# # Application charts are a collection of templates that can be packaged into versioned archives
# # to be deployed.
# #
# # Library charts provide useful utilities or functions for the chart developer. They're included as
# # a dependency of application charts to inject those utilities and functions into the rendering
# # pipeline. Library charts do not define any templates and therefore cannot be deployed.
# type: application
# 
# # This is the chart version. This version number should be incremented each time you make changes
# # to the chart and its templates, including the app version.
# # Versions are expected to follow Semantic Versioning (https://semver.org/)
# version: 0.1.0
# 
# # This is the version number of the application being deployed. This version number should be
# # incremented each time you make changes to the application. Versions are not expected to
# # follow Semantic Versioning. They should reflect the version the application is using.
# # It is recommended to use it with quotes.
# appVersion: "1.16.0"
```

### 8.2.2 编写模板

```yaml
# templates/deployment.yaml

# Kubernetes API 版本 - 应用API组
# 可选值: apps/v1, apps/v1beta1, apps/v1beta2
apiVersion: apps/v1

# 资源类型 - Deployment
# 可选值: Deployment, StatefulSet, DaemonSet
kind: Deployment

# 元数据 - 使用Helm模板函数生成名称
metadata:
  # 名称 - 从include函数获取完整名称
  name: {{ include "myapp.fullname" . }}

  # 标签 - 从include函数获取标签
  labels:
    # nindent函数用于缩进
    {{- include "myapp.labels" . | nindent 4 }}

# 规格说明
spec:
  # 条件判断 - 如果未启用自动扩缩容
  {{- if not .Values.autoscaling.enabled }}
  # 副本数 - 从values获取
  replicas: {{ .Values.replicaCount }}
  {{- end }}

  # 选择器
  selector:
    matchLabels:
      # 从include函数获取选择器标签
      {{- include "myapp.selectorLabels" . | nindent 6 }}

  # Pod模板
  template:
    metadata:
      # 条件注解 - 如果有podAnnotations
      {{- with .Values.podAnnotations }}
      annotations:
        # toYaml将对象转为YAML格式
        {{- toYaml . | nindent 8 }}
      {{- end }}

      # 标签
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}

    spec:
      # 镜像拉取密钥 - 如果有配置
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      # 服务账户
      serviceAccountName: {{ include "myapp.serviceAccountName" . }}

      # Pod安全上下文
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}

      # 容器列表
      containers:
        - # 容器名称 - 从Chart名称获取
          name: {{ .Chart.Name }}

          # 安全上下文
          securityContext:
            {{- toYaml .Values.securityContext | nindent 10 }}

          # 镜像 - 格式: 仓库:标签
          # tag使用Values中的值，默认为Chart的AppVersion
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"

          # 镜像拉取策略
          # 可选值:
          #   - Always: 总是拉取
          #   - IfNotPresent: 本地有就用本地，没有就拉取
          #   - Never: 从不拉取
          imagePullPolicy: {{ .Values.image.pullPolicy }}

          # 端口配置
          ports:
            - # 端口名称
              name: http
              # 容器端口
              containerPort: 80
              # 协议
              protocol: TCP

          # 存活探针
          livenessProbe:
            httpGet:
              # 探测路径
              path: /
              # 探测端口 - 使用端口名称
              port: http

          # 就绪探针
          readinessProbe:
            httpGet:
              path: /
              port: http

          # 资源限制
          resources:
            {{- toYaml .Values.resources | nindent 10 }}

      # 节点选择器
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      # 亲和性配置
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      # 容忍配置 - 允许Pod调度到带污点的节点
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

### 8.2.3 编写Values

```yaml
# values.yaml

# 副本数
# 可选值: 正整数
replicaCount: 3

# 镜像配置
image:
  # 镜像仓库
  repository: nginx
  # 拉取策略
  # 可选值: Always, IfNotPresent, Never
  pullPolicy: IfNotPresent
  # 镜像标签
  # 如果为空，使用Chart的appVersion
  tag: "1.25.0"

# 镜像拉取密钥列表
# 用于拉取私有镜像
imagePullSecrets: []

# 名称覆盖 - 替换Chart生成的完整名称
nameOverride: ""

# 全名覆盖 - 替换Chart生成的全名
fullnameOverride: ""

# 服务账户配置
serviceAccount:
  # 是否创建ServiceAccount
  create: true

  # 注解
  annotations: {}

  # 名称 - 如果为空，使用生成的名字
  name: ""

# Pod注解
podAnnotations: {}

# Pod安全上下文
podSecurityContext: {}

# 容器安全上下文
securityContext: {}

# 服务配置
service:
  # Service类型
  # 可选值: ClusterIP, NodePort, LoadBalancer
  type: ClusterIP

  # 服务端口
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources: {}

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}
```

---

## 8.3 Chart实战

### 8.3.1 安装Chart

```bash
# 安装Chart
helm install myapp ./myapp

# 输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:00:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

# 查看Release
helm list

# 输出：
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         1               2024-01-15 10:00:00 +0000 UTC        deployed        myapp-0.1.0     1.16.0

# 查看Release状态
helm status myapp

# 输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:00:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# DESCRIPTION: Install complete
#
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:00:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

### 8.3.2 升级Chart

```bash
# 升级Chart
helm upgrade myapp ./myapp --set replicaCount=5

# 输出：
# Release "myapp" has been upgraded. Happy Helming!
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:05:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 2
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

# 查看Release
helm list

# 输出：
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         2               2024-01-15 10:05:00 +0000 UTC        deployed        myapp-0.1.0     1.16.0

# 查看Release历史
helm history myapp

# 输出：
# REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
# 1               Mon Jan 15 10:00:00 2024      superseded      myapp-0.1.0     1.16.0          Install complete
# 2               Mon Jan 15 10:05:00 2024      deployed        myapp-0.1.0     1.16.0          Upgrade complete
```

### 8.3.3 回滚Chart

```bash
# 回滚Chart
helm rollback myapp 1

# 输出：
# Rollback was a success! Happy Helming!
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:10:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 3
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

# 查看Release历史
helm history myapp

# 输出：
# REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
# 1               Mon Jan 15 10:00:00 2024      superseded      myapp-0.1.0     1.16.0          Install complete
# 2               Mon Jan 15 10:05:00 2024      superseded      myapp-0.1.0     1.16.0          Upgrade complete
# 3               Mon Jan 15 10:10:00 2024      deployed        myapp-0.1.0     1.16.0          Rollback to 1
```

### 8.3.4 卸载Chart

```bash
# 卸载Chart
helm uninstall myapp

# 输出：
# release "myapp" uninstalled

# 查看Release
helm list

# 输出：
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION

# 查看已卸载的Release
helm list --all

# 输出：
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         3               2024-01-15 10:10:00 2024        uninstalled     myapp-0.1.0     1.16.0
```

### 8.3.5 使用Values文件

```bash
# 使用Values文件安装
helm install myapp ./myapp --values values-prod.yaml

# 输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:15:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

# 使用多个Values文件安装
helm install myapp ./myapp \
  --values values-prod.yaml \
  --values custom-values.yaml

# 输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:20:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT

# 使用--set参数安装
helm install myapp ./myapp \
  --set replicaCount=5 \
  --set image.tag=1.25.0-custom \
  --set service.type=LoadBalancer

# 输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:25:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:
#   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=myapp,app.kubernetes.io/instance=myapp" -o jsonpath="{.items[0].metadata.name}")
#   export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
#   echo "Visit http://127.0.0.1:8080 to use your application"
#   kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT
```

---

## 8.4 Helm 实战练习 - 一步步部署 Web 应用

### 8.4.1 环境准备

```bash
# 1. 检查 Helm 是否已安装
helm version

# 输出示例：
# version.BuildInfo{Version:"v3.14.0", GitCommit:"xxxxx", GitTreeState:"clean", GoVersion:"go1.21"}

# 2. 如果没有安装，请先安装 Helm
# macOS:
brew install helm

# Windows (使用 Chocolatey):
choco install kubernetes-helm

# Linux:
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# 3. 添加常用的 Chart 仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# 4. 更新仓库索引
helm repo update

# 5. 查看已添加的仓库
helm repo list

# 输出：
# NAME            URL
# bitnami         https://charts.bitnami.com/bitnami
# prometheus      https://prometheus-community.github.io/helm-charts
# ingress-nginx   https://kubernetes.github.io/ingress-nginx
```

### 8.4.2 方式一：使用现成 Chart 部署应用

#### 步骤1：搜索 Chart

```bash
# 搜索 Nginx Chart
helm search repo nginx

# 输出：
# NAME                    CHART VERSION   APP VERSION     DESCRIPTION
# bitnami/nginx           15.x.x          1.25.x          Chart for nginx
# bitnami/nginx-ingress-controller 9.x.x   1.9.x          NGINX Ingress Controller

# 搜索 MySQL Chart
helm search repo mysql

# 输出：
# NAME                    CHART VERSION   APP VERSION     DESCRIPTION
# bitnami/mysql           9.x.x           8.0.x           Chart for MySQL
```

#### 步骤2：查看 Chart 详细信息

```bash
# 查看 Chart 的所有可配置参数
helm show values bitnami/nginx

# 输出（部分）：
# replicaCount: 1
# image:
#   registry: docker.io
#   repository: bitnami/nginx
#   tag: 1.25.0
#   pullPolicy: IfNotPresent
# service:
#   type: LoadBalancer
#   port: 80
# ingress:
#   enabled: false
# ...
```

#### 步骤3：安装 Chart

```bash
# 基本安装
helm install my-nginx bitnami/nginx

# 输出：
# NAME: my-nginx
# LAST DEPLOYED: Sun Mar 22 21:00:00 2026
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None

# 查看安装的 Release
helm list

# 查看 Pod 状态
kubectl get pods

# 输出：
# NAME                               READY   STATUS    RESTARTS   AGE
# my-nginx-nginx-86d56df7b9-xxxxx    1/1     Running   0          30s

# 查看 Service
kubectl get svc

# 输出：
# NAME            TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# my-nginx-nginx  LoadBalancer   10.96.xxx.xxx    localhost     80:30000/TCP   30s
```

#### 步骤4：自定义配置安装

```bash
# 创建自定义配置文件 my-values.yaml
# my-values.yaml
replicaCount: 3
service:
  type: NodePort
  nodePorts:
    http: 30080
ingress:
  enabled: true
  hostname: myapp.example.com

# 使用自定义配置安装
helm install my-nginx bitnami/nginx --values my-values.yaml

# 或者使用 --set 参数覆盖单个值
helm install my-nginx bitnami/nginx \
  --set replicaCount=2 \
  --set service.type=NodePort
```

#### 步骤5：升级和回滚

```bash
# 升级到新版本或更新配置
helm upgrade my-nginx bitnami/nginx --set replicaCount=5

# 查看 Release 历史
helm history my-nginx

# 输出：
# REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
# 1               Sun Mar 22 21:00:00 2026        deployed        nginx-15.x.x     1.25.x          Install complete
# 2               Sun Mar 22 21:05:00 2026        deployed        nginx-15.x.x     1.25.x          Upgrade complete

# 回滚到上一个版本
helm rollback my-nginx

# 回滚到指定版本
helm rollback my-nginx 1

# 查看回滚结果
helm history my-nginx

# 输出：
# REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
# 1               Sun Mar 22 21:00:00 2026        superseded      nginx-15.x.x     1.25.x          Install complete
# 2               Sun Mar 22 21:05:00 2026        superseded      nginx-15.x.x     1.25.x          Upgrade complete
# 3               Sun Mar 22 21:10:00 2026        deployed        nginx-15.x.x     1.25.x          Rollback to 1
```

#### 步骤6：卸载

```bash
# 卸载 Release
helm uninstall my-nginx

# 输出：
# release "my-nginx" uninstalled

# 确认已卸载
helm list
```

### 8.4.3 方式二：创建自己的 Chart

#### 步骤1：创建 Chart

```bash
# 创建新的 Chart
helm create mywebapp

# 查看创建的 Chart 结构
ls -la mywebapp/

# 输出：
# mywebapp/
# ├── Chart.yaml
# ├── charts/
# ├── .helmignore
# ├── values.yaml
# ├── templates/
# │   ├── deployment.yaml
# │   ├── _helpers.tpl
# │   ├── ingress.yaml
# │   ├── NOTES.txt
# │   ├── serviceaccount.yaml
# │   ├── service.yaml
# │   └── tests/
# │       └── test-connection.yaml
# └── README.md
```

#### 步骤2：修改 Chart.yaml

```yaml
# Chart.yaml
apiVersion: v2
name: mywebapp
description: 我的第一个 Helm Chart - Web 应用
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - webapp
  - nginx
maintainers:
  - name: Your Name
    email: your@email.com
```

#### 步骤3：编写 values.yaml

```yaml
# values.yaml

# 应用名称
appName: mywebapp

# 副本数
replicaCount: 2

# 镜像配置
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25.0"

# 端口配置
service:
  type: ClusterIP
  port: 80
  targetPort: 80

# Ingress 配置
ingress:
  enabled: true
  className: nginx
  hostname: mywebapp.example.com
  path: /
  pathType: Prefix

# 资源配置
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# 环境变量
env:
  - name: ENV
    value: production
  - name: LOG_LEVEL
    value: info
```

#### 步骤4：编写模板文件

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}
  labels:
    app: {{ .Values.appName }}
    version: {{ .Chart.Version }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
        version: {{ .Chart.Version }}
    spec:
      containers:
        - name: {{ .Values.appName }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.targetPort }}
          env:
            {{- range .Values.env }}
            - name: {{ .name }}
              value: {{ .value | quote }}
            {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 10 }}
```

```yaml
# templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.appName }}
  labels:
    app: {{ .Values.appName }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
  selector:
    app: {{ .Values.appName }}
```

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.appName }}
  labels:
    app: {{ .Values.appName }}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
    - host: {{ .Values.ingress.hostname | quote }}
      http:
        paths:
          - path: {{ .Values.ingress.path }}
            pathType: {{ .Values.ingress.pathType }}
            backend:
              service:
                name: {{ .Values.appName }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
```

#### 步骤5：验证模板

```bash
# 本地调试 - 查看渲染后的模板
helm template mywebapp ./mywebapp

# 验证 Chart 语法
helm lint ./mywebapp

# 输出：
# ==> Linting ./mywebapp
# [INFO] Chart.yaml: icon is recommended
# ==> Linting ./mywebapp
# 1 chart(s) linted, 0 chart(s) failed, 0 chart(s) warning
```

#### 步骤6：安装和测试

```bash
# 安装 Chart（开发环境）
helm install mywebapp ./mywebapp --dry-run --debug

# 实际安装
helm install mywebapp ./mywebapp

# 查看安装状态
helm status mywebapp

# 查看 Pod
kubectl get pods -l app=mywebapp

# 查看 Service
kubectl get svc mywebapp

# 查看 Ingress
kubectl get ingress mywebapp

# 测试访问（端口转发）
kubectl port-forward svc/mywebapp 8080:80

# 在另一个终端测试
curl http://localhost:8080
```

#### 步骤7：打包和分发

```bash
# 打包 Chart
helm package ./mywebapp

# 输出：
# Successfully packaged chart and saved it to: /path/to/mywebapp-1.0.0.tgz

# 创建（或更新）索引文件
helm repo index . --url https://charts.example.com/

# 上传到 Chart 仓库（需要 chartmuseum 或其他工具）
# helm cm-push mywebapp-1.0.0.tgz myrepo
```

### 8.4.4 实战：部署包含多资源的完整应用

#### 创建电商应用 Chart

```bash
# 创建 Chart
helm create myshop
cd myshop
```

#### 编辑 Chart.yaml 添加依赖

```yaml
# Chart.yaml
apiVersion: v2
name: myshop
description: 电商应用 Chart
type: application
version: 1.0.0
appVersion: "1.0.0"

dependencies:
  - name: postgresql
    version: 12.x.x
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

#### 创建 ConfigMap

```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.appName }}-config
data:
  DATABASE_HOST: "{{ .Values.appName }}-postgresql"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "{{ .Values.dbName }}"
  LOG_LEVEL: "{{ .Values.logLevel }}"
```

#### 创建 Deployment

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
    spec:
      containers:
        - name: {{ .Values.appName }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ .Values.appName }}-config
            - secretRef:
                name: {{ .Values.appName }}-secret
          resources:
            {{- toYaml .Values.resources | nindent 10 }}
```

#### 创建 Service

```yaml
# templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.appName }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
  selector:
    app: {{ .Values.appName }}
```

#### 创建 Secret

```yaml
# templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.appName }}-secret
type: Opaque
stringData:
  DATABASE_USERNAME: {{ .Values.dbUsername | quote }}
  DATABASE_PASSWORD: {{ .Values.dbPassword | quote }}
```

#### 编辑 values.yaml

```yaml
# values.yaml

appName: myshop
replicaCount: 3

image:
  repository: nginx
  tag: "1.25.0"

service:
  type: ClusterIP
  port: 8080

dbName: shopdb
dbUsername: shopuser
dbPassword: shoppassword

logLevel: info

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

postgresql:
  enabled: true
  auth:
    postgresPassword: "secretpassword"
    database: "shopdb"
```

#### 安装应用

```bash
# 更新依赖
helm dependency build ./myshop

# 安装
helm install myshop ./myshop

# 查看所有资源
kubectl get all -l app=myshop

# 查看 Pod 日志
kubectl logs -l app=myshop

# 升级（更新镜像版本）
helm upgrade myshop ./myshop --set image.tag=1.25.1

# 回滚
helm rollback myshop

# 卸载
helm uninstall myshop
```

---

## 本章小结

- Helm是Kubernetes的包管理器，用于简化应用部署和管理
- Chart是Helm的包，包含模板、配置、依赖等
- Chart结构包括Chart.yaml、values.yaml、templates、charts等
- 模板引擎使用Go模板语法，支持变量替换、条件判断、循环迭代
- Values文件用于配置Chart，支持默认配置、环境配置、自定义配置
- Values优先级从高到低：--set > -f > values.yaml > Chart默认值
- 可以使用helm create创建Chart
- 可以使用helm install安装Chart
- 可以使用helm upgrade升级Chart
- 可以使用helm rollback回滚Chart
- 可以使用helm uninstall卸载Chart
- 可以使用helm list查看Release
- 可以使用helm history查看Release历史
- 可以使用helm status查看Release状态

---

**下一章：Kubernetes最佳实践**
