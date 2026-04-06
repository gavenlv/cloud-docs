# Chart结构详解

## 2.1 Chart目录结构

### 2.1.1 标准Chart结构

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart目录结构                                                   │
└─────────────────────────────────────────────────────────────────┘

mychart/
├── Chart.yaml              # Chart元数据（必需）
├── values.yaml             # 默认配置值（必需）
├── values.schema.json      # 配置验证Schema（可选）
├── charts/                 # 依赖Chart目录（可选）
│   └── dependency-chart/
├── templates/              # 模板文件目录（必需）
│   ├── deployment.yaml     # Deployment模板
│   ├── service.yaml        # Service模板
│   ├── ingress.yaml        # Ingress模板
│   ├── configmap.yaml      # ConfigMap模板
│   ├── secret.yaml         # Secret模板
│   ├── pvc.yaml            # PersistentVolumeClaim模板
│   ├── serviceaccount.yaml # ServiceAccount模板
│   ├── hpa.yaml            # HorizontalPodAutoscaler模板
│   ├── NOTES.txt           # 安装后说明
│   ├── _helpers.tpl        # 模板助手函数
│   └── tests/              # 测试文件
│       └── test-connection.yaml
├── .helmignore             # 打包时忽略的文件
├── LICENSE                 # 许可证文件（可选）
└── README.md               # Chart说明文档（可选）

文件说明：
├── Chart.yaml: Chart的元数据信息
├── values.yaml: 默认配置值
├── templates/: Kubernetes资源模板
├── charts/: 依赖的子Chart
├── .helmignore: 打包时排除的文件
└── README.md: 用户文档
```

### 2.1.2 创建Chart

```bash
# 创建新Chart
helm create mychart

# 查看生成的结构
tree mychart

# 输出：
# mychart/
# ├── Chart.yaml
# ├── charts/
# ├── templates/
# │   ├── deployment.yaml
# │   ├── _helpers.tpl
# │   ├── ingress.yaml
# │   ├── NOTES.txt
# │   ├── serviceaccount.yaml
# │   ├── service.yaml
# │   └── tests/
# │       └── test-connection.yaml
# └── values.yaml

# 验证Chart
helm lint mychart

# 输出：
# ==> Linting mychart
# [INFO] Chart.yaml: icon is recommended
# 
# 1 chart(s) linted, 0 chart(s) failed
```

---

## 2.2 Chart.yaml详解

### 2.2.1 基本结构

```yaml
apiVersion: v2
name: myapp
version: 1.0.0
appVersion: "2.0.0"
description: A Helm chart for deploying my application
type: application
keywords:
  - web
  - frontend
  - react
home: https://example.com
sources:
  - https://github.com/example/myapp
maintainers:
  - name: John Doe
    email: john@example.com
    url: https://johndoe.com
icon: https://example.com/icon.png
deprecated: false
annotations:
  artifacthub.io/license: Apache-2.0
  artifacthub.io/signKey: |
    fingerprint: "C874911F28F8F9E665B77F8F52B6B9B88E8F8E8F"
    url: https://example.com/public.key
kubeVersion: ">=1.23.0-0"
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    alias: db
    tags:
      - database
```

### 2.2.2 字段详解

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart.yaml字段说明                                              │
└─────────────────────────────────────────────────────────────────┘

必需字段：
├── apiVersion: Chart API版本
│   ├── v1: Helm 2格式
│   └── v2: Helm 3格式（推荐）
├── name: Chart名称
│   ├── 小写字母、数字、连字符
│   ├── 不允许下划线和点
│   └── 示例: my-app, nginx-ingress
├── version: Chart版本（语义化版本）
│   ├── 格式: MAJOR.MINOR.PATCH
│   ├── 每次修改必须递增
│   └── 用于版本约束
└── type: Chart类型
    ├── application: 可部署的应用Chart
    └── library: 库Chart（不可部署）

可选字段：
├── appVersion: 应用版本
│   ├── 不需要遵循语义化版本
│   └── 表示应用本身的版本
├── description: Chart描述
├── keywords: 关键词列表
├── home: 项目主页URL
├── sources: 源代码URL列表
├── maintainers: 维护者列表
│   ├── name: 姓名（必需）
│   ├── email: 邮箱
│   └── url: 个人主页
├── icon: 图标URL（SVG或PNG）
├── deprecated: 是否已废弃
├── annotations: 注解（键值对）
├── kubeVersion: 兼容的Kubernetes版本
└── dependencies: 依赖列表
```

### 2.2.3 版本管理

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart版本 vs 应用版本                                           │
└─────────────────────────────────────────────────────────────────┘

version (Chart版本):
├── 语义化版本: MAJOR.MINOR.PATCH
├── 修改模板或values时必须递增
├── 用于依赖版本约束
└── 示例: 1.2.3

appVersion (应用版本):
├── 应用本身的版本号
├── 不需要遵循语义化版本
├── 可在模板中使用 .Chart.AppVersion
└── 示例: "2.0.0", "v1.0.0-rc1", "latest"

版本递增规则：
├── MAJOR: 不兼容的API变更
├── MINOR: 向后兼容的功能新增
└── PATCH: 向后兼容的问题修复

示例：
初始版本:
  version: 1.0.0
  appVersion: "1.0.0"

修复Bug:
  version: 1.0.1
  appVersion: "1.0.1"

新增功能:
  version: 1.1.0
  appVersion: "1.1.0"

重大变更:
  version: 2.0.0
  appVersion: "2.0.0"
```

---

## 2.3 values.yaml详解

### 2.3.1 基本结构

```yaml
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

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

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}

tolerations: []

affinity: {}

extraEnv: []

extraVolumes: []

extraVolumeMounts: []
```

### 2.3.2 Values设计原则

```
┌─────────────────────────────────────────────────────────────────┐
│  Values设计最佳实践                                              │
└─────────────────────────────────────────────────────────────────┘

1. 合理的默认值
   ├── 开箱即用
   ├── 生产级安全配置
   └── 最小资源需求

2. 清晰的层次结构
   ├── 按功能分组
   ├── 命名有意义
   └── 深度不超过3层

3. 类型一致性
   ├── 字符串: tag: ""
   ├── 列表: imagePullSecrets: []
   ├── 字典: annotations: {}
   └── 数字: replicaCount: 3

4. 可扩展性
   ├── extraEnv: []
   ├── extraVolumes: []
   └── extraVolumeMounts: []

5. 条件开关
   ├── enabled: false
   ├── create: true
   └── 使用布尔值而非字符串

不好的设计：
myapp:
  deployment:
    spec:
      template:
        spec:
          containers:
            - name: myapp
              image: nginx

好的设计：
image:
  repository: nginx
  tag: "1.25.0"
replicaCount: 3
```

### 2.3.3 常用Values模式

```yaml
# 模式1: 镜像配置
image:
  repository: nginx
  tag: "1.25.0"
  pullPolicy: IfNotPresent

# 模式2: 服务配置
service:
  type: ClusterIP
  port: 80
  targetPort: http
  annotations: {}

# 模式3: Ingress配置
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

# 模式4: 资源配置
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 128Mi

# 模式5: 副本和扩缩容
replicaCount: 3
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# 模式6: 亲和性和容忍
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: myapp
          topologyKey: kubernetes.io/hostname

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "app"
    effect: "NoSchedule"

# 模式7: 额外配置扩展
extraEnv:
  - name: MY_VAR
    value: "my-value"
  - name: MY_SECRET
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: password

extraVolumes:
  - name: config
    configMap:
      name: my-config

extraVolumeMounts:
  - name: config
    mountPath: /etc/config
    readOnly: true
```

---

## 2.4 templates目录

### 2.4.1 模板文件类型

```
┌─────────────────────────────────────────────────────────────────┐
│  模板文件类型                                                    │
└─────────────────────────────────────────────────────────────────┘

1. 资源模板 (*.yaml)
   ├── deployment.yaml
   ├── service.yaml
   ├── ingress.yaml
   ├── configmap.yaml
   ├── secret.yaml
   ├── pvc.yaml
   ├── serviceaccount.yaml
   ├── hpa.yaml
   └── 自定义资源

2. 助手模板 (_*.tpl)
   ├── _helpers.tpl: 通用助手函数
   ├── _names.tpl: 名称生成函数
   └── _labels.tpl: 标签生成函数

3. 说明文件
   └── NOTES.txt: 安装后显示的说明

4. 测试文件 (tests/*.yaml)
   └── test-connection.yaml: 测试Pod

命名规范：
├── 资源模板: <资源类型>.yaml
├── 助手模板: _<功能>.tpl
├── 测试文件: tests/<测试名>.yaml
└── 说明文件: NOTES.txt
```

### 2.4.2 模板文件结构

```yaml
# templates/deployment.yaml

{{- if .Values.deployment.enabled -}}
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
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "myapp.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort | default 80 }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
          readinessProbe:
            httpGet:
              path: /ready
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
```

### 2.4.3 _helpers.tpl助手模板

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "myapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "myapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "myapp.labels" -}}
helm.sh/chart: {{ include "myapp.chart" . }}
{{ include "myapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "myapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "myapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

---

## 2.5 values.schema.json

### 2.5.1 Schema基本结构

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": [
    "image"
  ],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "description": "Number of replicas"
    },
    "image": {
      "type": "object",
      "required": [
        "repository"
      ],
      "properties": {
        "repository": {
          "type": "string",
          "description": "Image repository"
        },
        "tag": {
          "type": "string",
          "description": "Image tag"
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"],
          "default": "IfNotPresent"
        }
      }
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["ClusterIP", "NodePort", "LoadBalancer"],
          "default": "ClusterIP"
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535
        }
      }
    },
    "ingress": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean"
        },
        "hosts": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["host"],
            "properties": {
              "host": {
                "type": "string",
                "format": "hostname"
              },
              "paths": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "path": {
                      "type": "string"
                    },
                    "pathType": {
                      "type": "string",
                      "enum": ["Exact", "Prefix", "ImplementationSpecific"]
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### 2.5.2 Schema验证

```bash
# 安装时自动验证
helm install myapp ./mychart -f values.yaml

# 如果values.yaml不符合schema，会报错：
# Error: values don't meet the specifications of the schema(s) in the following chart(s):
# mychart:
# - (root): image is required
# - service.type: service.type must be one of the following: "ClusterIP", "NodePort", "LoadBalancer"

# 使用--dry-run验证
helm install myapp ./mychart -f values.yaml --dry-run
```

---

## 2.6 .helmignore文件

### 2.6.1 默认内容

```
# Patterns to ignore when building packages.
# This supports shell glob matching, relative path matching, and
# negation (prefixed with !). Only one pattern per line.

# Common VCS dirs
.git/
.gitignore
.bzr/
.bzrignore
.hg/
.hgignore
.svn/

# Common backup files
*.swp
*.bak
*.tmp
*.orig
*~

# Various IDEs
.project
.idea/
*.tmproj
.vscode/

# Test files
tests/
*.test.yaml

# Documentation
*.md
!README.md
```

### 2.6.2 自定义忽略规则

```
# 忽略开发文件
.env
.env.*
*.log

# 忽略临时文件
tmp/
temp/

# 忽略测试覆盖率
coverage/
.coverage

# 忽略构建产物
dist/
build/

# 但保留特定文件
!build/production/
```

---

## 2.7 Chart打包与分发

### 2.7.1 打包Chart

```bash
# 基本打包
helm package ./mychart

# 输出：
# Successfully packaged chart and saved it to: /path/to/mychart-0.1.0.tgz

# 指定版本
helm package ./mychart --version 1.0.0

# 指定输出目录
helm package ./mychart -d ./packages/

# 指定appVersion
helm package ./mychart --app-version "2.0.0"

# 签名打包
helm package ./mychart --sign --key 'John Doe' --keyring ~/.gnupg/pubring.gpg

# 输出：
# Successfully packaged chart and saved it to: /path/to/mychart-0.1.0.tgz
# Successfully signed chart and saved it to: /path/to/mychart-0.1.0.tgz.prov
```

### 2.7.2 验证打包

```bash
# 验证Chart
helm lint ./mychart

# 输出：
# ==> Linting mychart
# [INFO] Chart.yaml: icon is recommended
# 
# 1 chart(s) linted, 0 chart(s) failed

# 严格验证
helm lint ./mychart --strict

# 验证打包文件
helm verify mychart-0.1.0.tgz

# 验证签名
helm verify mychart-0.1.0.tgz --keyring ~/.gnupg/pubring.gpg
```

### 2.7.3 查看Chart信息

```bash
# 查看所有信息
helm show all ./mychart-0.1.0.tgz

# 只查看values
helm show values ./mychart-0.1.0.tgz

# 只查看Chart.yaml
helm show chart ./mychart-0.1.0.tgz

# 只查看README
helm show readme ./mychart-0.1.0.tgz

# 拉取远程Chart
helm pull bitnami/nginx

# 拉取并解压
helm pull bitnami/nginx --untar

# 拉取特定版本
helm pull bitnami/nginx --version 15.0.0
```

---

## 2.8 Library Chart

### 2.8.1 Library Chart概念

```
┌─────────────────────────────────────────────────────────────────┐
│  Library Chart                                                   │
└─────────────────────────────────────────────────────────────────┘

定义：
├── 可复用的模板库
├── 不包含Kubernetes资源模板
├── 不能直接部署
└── 被其他Chart依赖使用

用途：
├── 共享通用模板函数
├── 标准化标签和注解
├── 统一命名规范
└── 共享配置模式

Chart.yaml:
apiVersion: v2
name: common
version: 1.0.0
type: library
description: Common templates for my charts
```

### 2.8.2 创建Library Chart

```yaml
# common/Chart.yaml
apiVersion: v2
name: common
version: 1.0.0
type: library
description: Common templates and helpers

# common/templates/_labels.tpl
{{/*
Standard labels
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/name: {{ .Values.name | default .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

# common/templates/_names.tpl
{{/*
Generate a fully qualified name
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
```

### 2.8.3 使用Library Chart

```yaml
# myapp/Chart.yaml
apiVersion: v2
name: myapp
version: 1.0.0
dependencies:
  - name: common
    version: "1.x.x"
    repository: file://../common

# myapp/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  # ...
```
