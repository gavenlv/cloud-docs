# 模板引擎深度解析

## 3.1 Go模板基础

### 3.1.1 模板语法概览

```
┌─────────────────────────────────────────────────────────────────┐
│  Go模板语法                                                      │
└─────────────────────────────────────────────────────────────────┘

基本语法：
├── {{ .Values.key }}        变量访问
├── {{ .Values.key | upper }} 管道操作
├── {{ if .Values.enabled }}  条件判断
├── {{ range .Values.items }} 循环迭代
├── {{ define "name" }}       定义模板
├── {{ template "name" . }}   引用模板
├── {{ include "name" . }}    包含模板（推荐）
└── {{- ... -}}               去除空白

模板对象：
├── .Values      用户配置值
├── .Chart       Chart.yaml内容
├── .Release     Release信息
├── .Capabilities K8s集群信息
├── .Files       Chart内文件
├── .Templates   模板信息
└── .            当前上下文
```

### 3.1.2 变量访问

```yaml
# values.yaml
app:
  name: myapp
  version: "1.0.0"
  config:
    port: 8080
    debug: false

# 模板中使用
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.app.name }}
data:
  version: {{ .Values.app.version }}
  port: {{ .Values.app.config.port | quote }}
  debug: {{ .Values.app.config.debug | quote }}

# 渲染结果
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp
data:
  version: "1.0.0"
  port: "8080"
  debug: "false"
```

### 3.1.3 内置对象

```
┌─────────────────────────────────────────────────────────────────┐
│  内置对象                                                        │
└─────────────────────────────────────────────────────────────────┘

.Values - 用户配置
├── 来自values.yaml
├── 来自-f/--values文件
├── 来自--set参数
└── 示例: .Values.replicaCount

.Chart - Chart元数据
├── .Chart.Name         Chart名称
├── .Chart.Version      Chart版本
├── .Chart.AppVersion   应用版本
├── .Chart.Description  描述
├── .Chart.Type         类型
└── .Chart.Dependencies 依赖列表

.Release - Release信息
├── .Release.Name       Release名称
├── .Release.Namespace  命名空间
├── .Release.IsUpgrade  是否升级
├── .Release.IsInstall  是否安装
├── .Release.Revision   版本号
└── .Release.Service    服务名称("Helm")

.Capabilities - 集群信息
├── .Capabilities.APIVersions   可用API版本
├── .Capabilities.APIVersions.Has "apps/v1"
├── .Capabilities.KubeVersion   K8s版本
├── .Capabilities.KubeVersion.Version
├── .Capabilities.KubeVersion.Major
├── .Capabilities.KubeVersion.Minor
└── .Capabilities.HelmVersion   Helm版本

.Files - 文件访问
├── .Files.Get "config.ini"
├── .Files.GetBytes "binary.bin"
├── .Files.Glob "configs/*.yaml"
└── .Files.Lines "file.txt"

.Templates - 模板信息
├── .Templates.Name     模板名称
└── .Templates.BasePath 模板目录路径
```

---

## 3.2 条件判断

### 3.2.1 if/else语句

```yaml
# 基本if语句
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  # ...
{{- end }}

# if/else语句
{{- if .Values.service.type }}
type: {{ .Values.service.type }}
{{- else }}
type: ClusterIP
{{- end }}

# if/else if/else语句
{{- if eq .Values.service.type "NodePort" }}
nodePort: {{ .Values.service.nodePort }}
{{- else if eq .Values.service.type "LoadBalancer" }}
loadBalancerIP: {{ .Values.service.loadBalancerIP }}
{{- else }}
# ClusterIP - no additional config
{{- end }}
```

### 3.2.2 条件判断函数

```
┌─────────────────────────────────────────────────────────────────┐
│  条件判断函数                                                    │
└─────────────────────────────────────────────────────────────────┘

比较函数：
├── eq .Values.a .Values.b     相等
├── ne .Values.a .Values.b     不相等
├── lt .Values.a .Values.b     小于
├── le .Values.a .Values.b     小于等于
├── gt .Values.a .Values.b     大于
└── ge .Values.a .Values.b     大于等于

逻辑函数：
├── and .Values.a .Values.b    与
├── or .Values.a .Values.b     或
└── not .Values.a              非

存在性检查：
├── .Values.key                键存在且非零值
├── .Values.key | default "x"  提供默认值
├── empty .Values.key          是否为空
└── kindIs "map" .Values.key   类型检查

示例：
{{- if eq .Values.env "production" }}
replicas: 3
{{- end }}

{{- if and .Values.ingress.enabled .Values.ingress.tls }}
tls:
  {{- toYaml .Values.ingress.tls | nindent 2 }}
{{- end }}

{{- if or (eq .Values.env "staging") (eq .Values.env "production") }}
replicas: 2
{{- end }}
```

### 3.2.3 空值判断

```yaml
# 判断是否为空
{{- if .Values.config }}
config:
  {{- toYaml .Values.config | nindent 2 }}
{{- end }}

# 判断列表是否为空
{{- if .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml .Values.imagePullSecrets | nindent 2 }}
{{- end }}

# 判断字典是否为空
{{- if .Values.annotations }}
annotations:
  {{- toYaml .Values.annotations | nindent 2 }}
{{- end }}

# 使用empty函数
{{- if not (empty .Values.env) }}
env:
  {{- toYaml .Values.env | nindent 2 }}
{{- end }}
```

---

## 3.3 循环迭代

### 3.3.1 range基本用法

```yaml
# values.yaml
env:
  - name: ENV1
    value: value1
  - name: ENV2
    value: value2

# 模板
env:
  {{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value }}
  {{- end }}

# 渲染结果
env:
  - name: ENV1
    value: value1
  - name: ENV2
    value: value2
```

### 3.3.2 range遍历字典

```yaml
# values.yaml
labels:
  app: myapp
  tier: frontend
  environment: production

# 模板
labels:
  {{- range $key, $value := .Values.labels }}
  {{ $key }}: {{ $value }}
  {{- end }}

# 渲染结果
labels:
  app: myapp
  tier: frontend
  environment: production
```

### 3.3.3 range遍历列表

```yaml
# values.yaml
hosts:
  - host: app.example.com
    paths:
      - path: /
        pathType: Prefix
  - host: api.example.com
    paths:
      - path: /api
        pathType: Prefix

# 模板
spec:
  rules:
    {{- range .Values.hosts }}
    - host: {{ .host }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "myapp.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
```

### 3.3.4 range中使用全局变量

```yaml
# 在range内部访问外部变量需要使用$
spec:
  containers:
    {{- range .Values.containers }}
    - name: {{ .name }}
      image: {{ .image }}
      ports:
        - containerPort: {{ $.Values.service.port }}
    {{- end }}

# 或者使用with保存上下文
{{- $root := . -}}
spec:
  containers:
    {{- range .Values.containers }}
    - name: {{ .name }}
      image: {{ .image }}
      ports:
        - containerPort: {{ $root.Values.service.port }}
    {{- end }}
```

---

## 3.4 管道与函数

### 3.4.1 管道操作

```yaml
# 管道链式调用
name: {{ .Values.app.name | upper | quote }}

# 渲染结果
name: "MYAPP"

# 多个管道
port: {{ .Values.service.port | default 80 | int | quote }}

# 条件管道
enabled: {{ .Values.feature.enabled | default false }}
```

### 3.4.2 常用Sprig函数

```
┌─────────────────────────────────────────────────────────────────┐
│  字符串函数                                                      │
└─────────────────────────────────────────────────────────────────┘

upper      转大写
lower      转小写
title      首字母大写
trim       去除两端空白
trimPrefix 去除前缀
trimSuffix 去除后缀
quote      添加双引号
squote     添加单引号
default    默认值
replace    替换
trunc      截断
abbrev     缩写

示例：
{{ .Values.name | upper }}           # MYAPP
{{ .Values.name | lower }}           # myapp
{{ .Values.name | quote }}           # "myapp"
{{ .Values.name | default "default" }} # default
{{ .Values.name | trunc 10 }}        # 截断到10字符
{{ .Values.name | replace "-" "_" }} # 替换

┌─────────────────────────────────────────────────────────────────┐
│  类型转换函数                                                    │
└─────────────────────────────────────────────────────────────────┘

toString  转字符串
toInt     转整数
toFloat64 转浮点数
toBool    转布尔值

示例：
{{ .Values.port | int }}
{{ .Values.enabled | toBool | quote }}

┌─────────────────────────────────────────────────────────────────┐
│  列表/字典函数                                                   │
└─────────────────────────────────────────────────────────────────┘

first     第一个元素
last      最后一个元素
rest      除第一个外的元素
initial   除最后一个外的元素
append    追加元素
prepend   前置元素
concat    连接列表
has       检查元素是否存在
keys      获取所有键
values    获取所有值
pick      选择键
omit      排除键

示例：
{{ first .Values.items }}
{{ has "item" .Values.items }}
{{ keys .Values.config }}
{{ .Values.port | toString }}

┌─────────────────────────────────────────────────────────────────┐
│  编码函数                                                        │
└─────────────────────────────────────────────────────────────────┘

toYaml    转YAML
toJson    转JSON
fromYaml  解析YAML
fromJson  解析JSON

示例：
{{- toYaml .Values.resources | nindent 4 }}
{{ .Values.config | toJson }}

┌─────────────────────────────────────────────────────────────────┐
│  加密函数                                                        │
└─────────────────────────────────────────────────────────────────┘

sha256sum SHA256哈希
sha1sum   SHA1哈希
adler32sum Adler32校验
b64enc    Base64编码
b64dec    Base64解码

示例：
{{ .Values.password | b64enc }}
{{ .Values.data | sha256sum }}
```

### 3.4.3 toYaml和nindent

```yaml
# toYaml将对象转为YAML格式
resources:
  {{- toYaml .Values.resources | nindent 2 }}

# nindent添加换行和缩进
# nindent N = 换行 + 缩进N个空格

# values.yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# 渲染结果
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

---

## 3.5 with上下文

### 3.5.1 with基本用法

```yaml
# 不使用with
annotations:
  {{- if .Values.podAnnotations }}
  {{- toYaml .Values.podAnnotations | nindent 2 }}
  {{- end }}

# 使用with简化
{{- with .Values.podAnnotations }}
annotations:
  {{- toYaml . | nindent 2 }}
{{- end }}

# with内部.指向新的上下文
{{- with .Values.service }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "myapp.fullname" $ }}
spec:
  type: {{ .type }}
  port: {{ .port }}
{{- end }}
```

### 3.5.2 with中访问全局变量

```yaml
# 使用$访问根上下文
{{- with .Values.ingress }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" $ }}
  labels:
    {{- include "myapp.labels" $ | nindent 4 }}
spec:
  rules:
    {{- range .hosts }}
    - host: {{ .host }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            backend:
              service:
                name: {{ include "myapp.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

---

## 3.6 模板定义与复用

### 3.6.1 define定义模板

```yaml
# templates/_helpers.tpl

{{/*
定义名称模板
*/}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
定义全名模板
*/}}
{{- define "myapp.fullname" -}}
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

{{/*
定义标签模板
*/}}
{{- define "myapp.labels" -}}
helm.sh/chart: {{ include "myapp.chart" . }}
{{ include "myapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
定义选择器标签模板
*/}}
{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
```

### 3.6.2 template vs include

```yaml
# template - 不传递上下文
metadata:
  name: {{ template "myapp.fullname" . }}
  labels:
    {{ template "myapp.labels" . }}

# include - 推荐使用，支持管道
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}

# include的优势：
# 1. 支持管道操作
# 2. 可以与其他函数组合
# 3. 更灵活的格式控制
```

### 3.6.3 模板组织最佳实践

```yaml
# 按功能分离模板文件

# templates/_names.tpl - 名称相关
{{- define "myapp.name" -}}
...
{{- end -}}

# templates/_labels.tpl - 标签相关
{{- define "myapp.labels" -}}
...
{{- end -}}

# templates/_helpers.tpl - 通用助手
{{- define "myapp.util.merge" -}}
...
{{- end -}}

# 命名规范
# <chart-name>.<function-name>
# 示例: myapp.labels, myapp.fullname
```

---

## 3.7 高级模板技巧

### 3.7.1 空白控制

```yaml
# {{- 去除左边空白
# -}} 去除右边空白

# 不好的写法
{{ if .Values.enabled }}
data: value
{{ end }}

# 渲染结果（有多余空行）：

data: value


# 好的写法
{{- if .Values.enabled }}
data: value
{{- end }}

# 渲染结果
data: value
```

### 3.7.2 条件渲染整个文件

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
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
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

### 3.7.3 动态生成资源

```yaml
# 根据配置生成多个资源
{{- range $name, $config := .Values.configMaps }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "myapp.fullname" $ }}-{{ $name }}
  labels:
    {{- include "myapp.labels" $ | nindent 4 }}
data:
  {{- toYaml $config | nindent 2 }}
{{- end }}

# values.yaml
configMaps:
  app-config:
    DATABASE_URL: "postgres://localhost:5432/db"
    REDIS_URL: "redis://localhost:6379"
  nginx-config:
    nginx.conf: |
      server {
        listen 80;
      }
```

### 3.7.4 使用tpl渲染字符串

```yaml
# values.yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "{{ .Values.service.port }}"

# 模板
metadata:
  annotations:
    {{- range $key, $value := .Values.podAnnotations }}
    {{ $key }}: {{ $value | tpl . }}
    {{- end }}

# 或者
metadata:
  annotations:
    {{- tpl (toYaml .Values.podAnnotations) . | nindent 4 }}
```

### 3.7.5 合并字典

```yaml
# 使用mustMerge合并字典
{{- $merged := mustMerge (dict "a" 1) (dict "b" 2) -}}
# 结果: {"a":1,"b":2}

# 实际应用：合并默认配置和用户配置
{{- $defaultConfig := dict "port" 80 "replicas" 1 -}}
{{- $userConfig := .Values.config | default (dict) -}}
{{- $config := mustMerge $defaultConfig $userConfig -}}
```

---

## 3.8 模板调试

### 3.8.1 调试命令

```bash
# 渲染模板但不安装
helm template myapp ./mychart

# 指定values文件
helm template myapp ./mychart -f values-dev.yaml

# 只渲染特定模板
helm template myapp ./mychart -x templates/deployment.yaml

# 调试模式
helm template myapp ./mychart --debug

# 模拟安装
helm install myapp ./mychart --dry-run --debug

# 模拟升级
helm upgrade myapp ./mychart --dry-run --debug
```

### 3.8.2 调试技巧

```yaml
# 使用fail函数输出调试信息
{{- fail (printf "Debug: %v" .Values) }}

# 使用required确保必需值
replicas: {{ .Values.replicaCount | required "replicaCount is required!" }}

# 输出变量值到注释
# Debug: {{ .Values | toJson }}

# 使用warn输出警告
{{- $_ := warn "This is a warning message" -}}
```

### 3.8.3 常见错误

```
┌─────────────────────────────────────────────────────────────────┐
│  常见模板错误                                                    │
└─────────────────────────────────────────────────────────────────┘

1. 变量未定义
错误: <.Values.nonexistent>: map has no entry for key "nonexistent"
解决: 使用default提供默认值
{{ .Values.nonexistent | default "default" }}

2. 类型错误
错误: wrong type for value
解决: 确保类型正确，使用类型转换函数
{{ .Values.port | int }}

3. 空指针
错误: nil pointer evaluating interface {}
解决: 使用with或条件判断
{{- with .Values.config }}
config: {{ . }}
{{- end }}

4. 模板语法错误
错误: unexpected EOF
解决: 检查模板语法，确保{{ }}成对

5. 缩进错误
错误: YAML解析失败
解决: 使用nindent正确缩进
{{- toYaml .Values.resources | nindent 4 }}
```

---

## 3.9 模板最佳实践

### 3.9.1 可读性

```yaml
# 不好的写法
{{- if and .Values.ingress.enabled (eq .Values.ingress.className "nginx") (not (empty .Values.ingress.hosts)) }}
# ...
{{- end }}

# 好的写法 - 使用变量提高可读性
{{- $ingressEnabled := .Values.ingress.enabled -}}
{{- $isNginx := eq .Values.ingress.className "nginx" -}}
{{- $hasHosts := not (empty .Values.ingress.hosts) -}}
{{- if and $ingressEnabled $isNginx $hasHosts }}
# ...
{{- end }}
```

### 3.9.2 避免复杂逻辑

```yaml
# 不好的写法 - 模板中包含复杂逻辑
{{- if gt (int .Values.replicas) 3 }}
{{- if eq .Values.env "production" }}
{{- if .Values.hpa.enabled }}
# ...
{{- end }}
{{- end }}
{{- end }}

# 好的写法 - 在values中预计算
# values.yaml
highAvailability:
  enabled: false  # 由外部工具或文档说明何时启用

# 模板
{{- if .Values.highAvailability.enabled }}
# ...
{{- end }}
```

### 3.9.3 文档注释

```yaml
# templates/_helpers.tpl

{{/*
Expand the name of the chart.

This function generates a name for resources by using the chart name
or a user-provided override. The name is truncated to 63 characters
to comply with Kubernetes naming limits.

Usage:
  name: {{ include "myapp.name" . }}

Parameters:
  . - The root context

Returns:
  string - The chart name (truncated to 63 chars)
*/}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```

### 3.9.4 测试模板

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

# 运行测试
helm test myapp
```
