# 高级模式与最佳实践

## 7.1 如何用好Helm

### 7.1.1 设计原则

```
┌─────────────────────────────────────────────────────────────────┐
│  Chart设计原则                                                   │
└─────────────────────────────────────────────────────────────────┘

1. 单一职责
   ├── 一个Chart一个应用
   ├── 避免打包多个不相关服务
   ├── 使用依赖组合复杂系统
   └── 保持Chart简洁

2. 合理默认值
   ├── 开箱即用
   ├── 安全的默认配置
   ├── 最小资源需求
   └── 生产级选项

3. 可配置性
   ├── 支持常见配置场景
   ├── 提供扩展点
   ├── 避免过度配置
   └── 文档化配置选项

4. 可复用性
   ├── 参数化所有可变部分
   ├── 使用Library Chart共享模板
   ├── 遵循命名规范
   └── 版本化发布

5. 可维护性
   ├── 清晰的目录结构
   ├── 注释和文档
   ├── 测试覆盖
   └── 变更日志
```

### 7.1.2 Chart复杂度管理

```
┌─────────────────────────────────────────────────────────────────┐
│  复杂度层次                                                      │
└─────────────────────────────────────────────────────────────────┘

Level 1: 简单Chart
├── 单一Deployment
├── 单一Service
├── 少量配置选项
└── 示例: nginx, redis

Level 2: 标准Chart
├── Deployment + Service
├── ConfigMap + Secret
├── Ingress (可选)
├── HPA (可选)
└── 示例: webapp, api-server

Level 3: 复杂Chart
├── 多个Deployment
├── StatefulSet
├── 多种资源类型
├── 依赖管理
└── 示例: gitlab, elk-stack

Level 4: Umbrella Chart
├── 组合多个子Chart
├── 统一配置管理
├── 依赖编排
└── 示例: microservices-platform

建议：
├── 从简单开始
├── 逐步增加复杂度
├── 避免过度设计
└── 保持可维护性
```

---

## 7.2 高级设计模式

### 7.2.1 Umbrella Chart模式

```yaml
# Umbrella Chart: 组合多个Chart的顶层Chart

# 目录结构
microservices/
├── Chart.yaml
├── values.yaml
├── charts/
│   ├── frontend/
│   ├── backend/
│   └── database/
└── templates/
    └── configmap.yaml  # 共享配置

# Chart.yaml
apiVersion: v2
name: microservices
version: 1.0.0
dependencies:
  - name: frontend
    version: "1.x.x"
    repository: file://charts/frontend
  - name: backend
    version: "1.x.x"
    repository: file://charts/backend
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled

# values.yaml
global:
  imageRegistry: registry.example.com
  imagePullSecrets:
    - name: registry-secret
  environment: production

frontend:
  replicaCount: 2
  image:
    repository: frontend
    tag: v1.0.0

backend:
  replicaCount: 3
  image:
    repository: backend
    tag: v1.0.0

postgresql:
  enabled: true
  auth:
    database: myapp
```

### 7.2.2 Library Chart模式

```yaml
# Library Chart: 可复用的模板库

# common/Chart.yaml
apiVersion: v2
name: common
version: 1.0.0
type: library
description: Common templates and helpers

# common/templates/_names.tpl
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

# common/templates/_labels.tpl
{{- define "common.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

# 使用Library Chart
# myapp/Chart.yaml
apiVersion: v2
name: myapp
version: 1.0.0
dependencies:
  - name: common
    version: "1.x.x"
    repository: file://../common

# myapp/templates/deployment.yaml
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
```

### 7.2.3 Sidecar模式

```yaml
# values.yaml
mainContainer:
  image:
    repository: myapp
    tag: "1.0.0"
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

sidecars:
  logCollector:
    enabled: true
    image:
      repository: fluent/fluent-bit
      tag: latest
    config:
      flush: 1
      log_level: info

  proxy:
    enabled: true
    image:
      repository: envoyproxy/envoy
      tag: latest

# templates/deployment.yaml
spec:
  containers:
    - name: main
      image: "{{ .Values.mainContainer.image.repository }}:{{ .Values.mainContainer.image.tag }}"
      # ...

    {{- range $name, $sidecar := .Values.sidecars }}
    {{- if $sidecar.enabled }}
    - name: {{ $name }}
      image: "{{ $sidecar.image.repository }}:{{ $sidecar.image.tag }}"
      {{- if $sidecar.config }}
      env:
        {{- range $key, $value := $sidecar.config }}
        - name: {{ $key | upper }}
          value: {{ $value | quote }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
```

### 7.2.4 Init Container模式

```yaml
# values.yaml
initContainers:
  - name: init-db
    image: busybox
    command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']
  
  - name: init-config
    image: busybox
    command: ['sh', '-c', 'cp /config-template/* /config/']
    volumeMounts:
      - name: config-template
        mountPath: /config-template
      - name: config
        mountPath: /config

# templates/deployment.yaml
spec:
  initContainers:
    {{- toYaml .Values.initContainers | nindent 4 }}
  containers:
    - name: {{ .Chart.Name }}
      # ...
```

---

## 7.3 配置管理最佳实践

### 7.3.1 多环境配置策略

```yaml
# 策略1: 层叠Values文件

# values.yaml - 基础配置
replicaCount: 1
image:
  repository: myapp
  pullPolicy: IfNotPresent

# values-staging.yaml - 预发布环境
replicaCount: 2
image:
  tag: staging
ingress:
  enabled: true
  hosts:
    - host: staging.example.com

# values-prod.yaml - 生产环境
replicaCount: 3
image:
  tag: v1.0.0
  pullPolicy: Always
ingress:
  enabled: true
  hosts:
    - host: app.example.com
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

# 部署命令
helm upgrade --install myapp ./mychart \
  -f values.yaml \
  -f values-prod.yaml
```

### 7.3.2 全局配置

```yaml
# Umbrella Chart中的全局配置
# values.yaml
global:
  imageRegistry: registry.example.com
  imagePullSecrets:
    - name: registry-secret
  storageClass: standard
  ingress:
    className: nginx
    tls:
      enabled: true
      issuer: letsencrypt-prod

# 子Chart中使用全局配置
# templates/deployment.yaml
image: "{{ .Values.global.imageRegistry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}"
imagePullSecrets:
  {{- toYaml .Values.global.imagePullSecrets | nindent 2 }}

# templates/pvc.yaml
storageClassName: {{ .Values.global.storageClass }}
```

### 7.3.3 配置验证

```yaml
# templates/_validation.tpl
{{- define "myapp.validate" -}}
{{- $errors := list -}}

{{- if not .Values.image.repository -}}
{{- $errors = append $errors "image.repository is required" -}}
{{- end -}}

{{- if and .Values.ingress.enabled (empty .Values.ingress.hosts) -}}
{{- $errors = append $errors "ingress.hosts is required when ingress is enabled" -}}
{{- end -}}

{{- if gt (int .Values.replicaCount) 100 -}}
{{- $errors = append $errors "replicaCount cannot exceed 100" -}}
{{- end -}}

{{- if $errors -}}
{{- fail (join "\n" $errors) -}}
{{- end -}}
{{- end -}}

# 在模板开头调用
{{- include "myapp.validate" . -}}
```

---

## 7.4 发布管理最佳实践

### 7.4.1 版本策略

```
┌─────────────────────────────────────────────────────────────────┐
│  版本管理策略                                                    │
└─────────────────────────────────────────────────────────────────┘

Chart版本 (version):
├── 遵循语义化版本
├── MAJOR.MINOR.PATCH
├── 模板变更时递增
└── 不兼容变更时升级MAJOR

应用版本 (appVersion):
├── 应用本身的版本
├── 可使用任意格式
└── 与Chart版本独立

版本递增规则：
├── PATCH: Bug修复、文档更新
├── MINOR: 新功能、向后兼容
└── MAJOR: 重大变更、不兼容

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

### 7.4.2 发布流程

```yaml
# .github/workflows/release.yaml
name: Release Chart

on:
  push:
    tags:
      - 'chart-v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.5.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

      - name: Push to OCI Registry
        run: |
          helm registry login ghcr.io -u ${{ github.actor }} -p ${{ secrets.GITHUB_TOKEN }}
          helm push mychart-*.tgz oci://ghcr.io/${{ github.repository_owner }}/charts
```

### 7.4.3 回滚策略

```bash
# 查看发布历史
helm history myapp

# 回滚到特定版本
helm rollback myapp 2

# 使用--atomic自动回滚
helm upgrade myapp ./mychart --atomic --timeout 5m

# 使用helmfile管理
# helmfile.yaml
releases:
  - name: myapp
    chart: ./mychart
    installed: true
    timeout: 300
    atomic: true
    cleanupOnFail: true
```

---

## 7.5 安全最佳实践

### 7.5.1 安全配置

```yaml
# values.yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL

serviceAccount:
  create: true
  annotations: {}
  automountServiceAccountToken: false

# templates/deployment.yaml
spec:
  serviceAccountName: {{ include "myapp.serviceAccountName" . }}
  automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  containers:
    - name: {{ .Chart.Name }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
```

### 7.5.2 网络策略

```yaml
# templates/networkpolicy.yaml
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              {{- toYaml .Values.networkPolicy.ingress.from | nindent 14 }}
      ports:
        - port: {{ .Values.service.port }}
          protocol: TCP
  egress:
    - to:
        {{- toYaml .Values.networkPolicy.egress.to | nindent 8 }}
{{- end }}
```

### 7.5.3 RBAC最小权限

```yaml
# templates/role.yaml
{{- if .Values.rbac.create }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list", "watch"]
    resourceNames: ["myapp-config"]
{{- end }}

# templates/rolebinding.yaml
{{- if .Values.rbac.create }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "myapp.fullname" . }}
subjects:
  - kind: ServiceAccount
    name: {{ include "myapp.serviceAccountName" . }}
    namespace: {{ .Release.Namespace }}
{{- end }}
```

---

## 7.6 性能优化

### 7.6.1 模板优化

```yaml
# 避免重复计算
{{- $fullName := include "myapp.fullname" . -}}
{{- $labels := include "myapp.labels" . -}}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $fullName }}
  labels:
    {{- $labels | nindent 4 }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ $fullName }}
  labels:
    {{- $labels | nindent 4 }}

# 使用with减少嵌套
{{- with .Values.ingress }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}
spec:
  rules:
    {{- range .hosts }}
    - host: {{ .host }}
    {{- end }}
{{- end }}
```

### 7.6.2 资源限制

```yaml
# 设置合理的资源限制
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 128Mi

# 使用LimitRange
# templates/limitrange.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
```

---

## 7.7 测试最佳实践

### 7.7.1 Chart测试

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "myapp.fullname" . }}-test-connection"
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "myapp.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never

# templates/tests/test-database.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "myapp.fullname" . }}-test-database"
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: psql
      image: postgres:14
      command: ['psql']
      args:
        - '-c'
        - 'SELECT 1'
      env:
        - name: PGHOST
          value: {{ include "myapp.fullname" . }}-postgresql
        - name: PGUSER
          value: postgres
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "myapp.fullname" . }}-postgresql
              key: postgres-password
  restartPolicy: Never

# 运行测试
helm test myapp
```

### 7.7.2 CI/CD集成

```yaml
# .github/workflows/test.yaml
name: Test Chart

on:
  pull_request:
    paths:
      - 'charts/**'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Lint Chart
        run: helm lint ./charts/mychart

      - name: Lint with ct
        uses: helm/chart-testing-action@v2.3.1
        with:
          command: lint
          config: .ct.yaml

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v3

      - name: Create kind cluster
        uses: helm/kind-action@v1.5.0

      - name: Install Chart
        run: |
          helm install myapp ./charts/mychart \
            --wait \
            --timeout 5m

      - name: Run Tests
        run: helm test myapp
```

---

## 7.8 文档最佳实践

### 7.8.1 README模板

```markdown
# myapp Helm Chart

## 简介

myapp是一个...

## 前置要求

- Kubernetes 1.23+
- Helm 3.0+

## 安装

```bash
helm repo add myrepo https://charts.example.com
helm install myapp myrepo/myapp
```

## 配置

### 基本配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `replicaCount` | 副本数 | `1` |
| `image.repository` | 镜像仓库 | `nginx` |
| `image.tag` | 镜像标签 | `""` |

### 完整配置

参见 [values.yaml](values.yaml)

## 示例

### 开发环境

```bash
helm install myapp myrepo/myapp -f values-dev.yaml
```

### 生产环境

```bash
helm install myapp myrepo/myapp -f values-prod.yaml
```

## 升级

```bash
helm upgrade myapp myrepo/myapp
```

## 卸载

```bash
helm uninstall myapp
```
```

### 7.8.2 NOTES.txt

```yaml
# templates/NOTES.txt
Thank you for installing {{ .Chart.Name }}!

Your release is named: {{ .Release.Name }}
Namespace: {{ .Release.Namespace }}

{{- if .Values.ingress.enabled }}

Access your application:
{{- range $host := .Values.ingress.hosts }}
  {{- range .paths }}
  http{{ if $.Values.ingress.tls }}s{{ end }}://{{ $host.host }}{{ .path }}
  {{- end }}
{{- end }}
{{- else }}

Get the application URL:
{{- if contains "NodePort" .Values.service.type }}
  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "myapp.fullname" . }})
  export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
{{- else if contains "LoadBalancer" .Values.service.type }}
  export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "myapp.fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  echo http://$SERVICE_IP:{{ .Values.service.port }}
{{- else }}
  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "myapp.name" . }},app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace {{ .Release.Namespace }} $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace {{ .Release.Namespace }} port-forward $POD_NAME 8080:$CONTAINER_PORT
{{- end }}
{{- end }}

{{- if .Values.postgresql.enabled }}
Database credentials:
  Host: {{ include "myapp.fullname" . }}-postgresql
  Port: 5432
  Database: {{ .Values.postgresql.auth.database }}
{{- end }}
```
