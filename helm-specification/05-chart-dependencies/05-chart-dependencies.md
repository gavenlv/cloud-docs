# Chart依赖管理

## 5.1 依赖概述

### 5.1.1 为什么需要依赖管理

```
┌─────────────────────────────────────────────────────────────────┐
│  依赖管理解决的问题                                              │
└─────────────────────────────────────────────────────────────────┘

场景1: 应用依赖基础服务
├── Web应用依赖数据库
├── 应用依赖消息队列
├── 应用依赖缓存服务
└── 手动管理复杂且易出错

场景2: 共享通用组件
├── 多个应用使用相同的监控配置
├── 统一日志收集配置
├── 标准化安全配置
└── 避免重复定义

场景3: 版本一致性
├── 确保依赖版本兼容
├── 统一升级依赖
├── 避免版本冲突
└── 可追溯的依赖关系

Helm依赖管理提供：
├── 声明式依赖定义
├── 自动下载和安装
├── 版本约束
├── 条件依赖
└── 依赖传递管理
```

---

## 5.2 声明依赖

### 5.2.1 Chart.yaml中的dependencies

```yaml
# Chart.yaml
apiVersion: v2
name: myapp
version: 1.0.0
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    alias: db
    tags:
      - database

  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled

  - name: common
    version: "2.x.x"
    repository: https://charts.bitnami.com/bitnami
    tags:
      - helper

  - name: mylib
    version: "1.0.0"
    repository: "file://../mylib"
```

### 5.2.2 依赖字段说明

```
┌─────────────────────────────────────────────────────────────────┐
│  依赖字段说明                                                    │
└─────────────────────────────────────────────────────────────────┘

name (必需)
├── Chart名称
└── 示例: postgresql

version (必需)
├── 版本约束
├── 支持语义化版本范围
└── 示例: "12.x.x", ">=12.0.0 <13.0.0"

repository (必需)
├── Chart仓库URL
├── 支持HTTP/HTTPS
├── 支持OCI: oci://registry.example.com/charts
└── 支持本地: file://../relative/path

condition (可选)
├── 条件启用依赖
├── 对应Values中的布尔值路径
└── 示例: postgresql.enabled

tags (可选)
├── 标签分组
├── 可通过--tags启用/禁用
└── 示例: ["database", "backend"]

alias (可选)
├── 依赖别名
├── 用于区分同名Chart的不同实例
└── 示例: db

import-values (可选)
├── 导入子Chart的值
├── 用于共享配置
└── 示例: [child:parent]
```

### 5.2.3 版本约束语法

```
┌─────────────────────────────────────────────────────────────────┐
│  版本约束语法                                                    │
└─────────────────────────────────────────────────────────────────┘

精确版本
├── "1.2.3"           精确匹配
└── "=1.2.3"          精确匹配

比较运算
├── ">1.2.3"          大于
├── ">=1.2.3"         大于等于
├── "<1.2.3"          小于
├── "<=1.2.3"         小于等于
└── "!=1.2.3"         不等于

范围运算
├── "1.2.x"           1.2系列的任何版本
├── "~1.2.3"          >=1.2.3 <1.3.0
├── "~1.2"            >=1.2.0 <2.0.0
├── "^1.2.3"          >=1.2.3 <2.0.0
└── "1.2.3 - 1.3.0"   >=1.2.3 <=1.3.0

组合约束
├── ">=1.2.3 <2.0.0"  范围约束
└── "1.x.x, !=1.3.0"  多个约束

推荐使用：
├── "12.x.x"          允许次版本更新
├── ">=12.0.0 <13.0.0" 明确范围
└── 避免使用 "*" 或空版本
```

---

## 5.3 管理依赖

### 5.3.1 下载依赖

```bash
# 更新依赖（下载到charts/目录）
helm dependency update ./mychart

# 输出：
# Saving 2 charts
# Downloading postgresql from repo https://charts.bitnami.com/bitnami
# Downloading redis from repo https://charts.bitnami.com/bitnami
# Deleting outdated charts

# 构建依赖（不更新）
helm dependency build ./mychart

# 查看依赖列表
helm dependency list ./mychart

# 输出：
# NAME        VERSION     REPOSITORY                              STATUS
# postgresql  12.12.0     https://charts.bitnami.com/bitnami      ok
# redis       17.15.2     https://charts.bitnami.com/bitnami      ok
```

### 5.3.2 charts目录

```
┌─────────────────────────────────────────────────────────────────┐
│  charts目录结构                                                  │
└─────────────────────────────────────────────────────────────────┘

mychart/
├── Chart.yaml
├── charts/
│   ├── postgresql-12.12.0.tgz    # 打包的依赖
│   └── redis-17.15.2.tgz
├── values.yaml
└── templates/

或者解压后的目录：
mychart/
├── Chart.yaml
├── charts/
│   ├── postgresql/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── redis/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── values.yaml
└── templates/

Chart.lock文件：
dependencies:
- name: postgresql
  repository: https://charts.bitnami.com/bitnami
  version: 12.12.0
- name: redis
  repository: https://charts.bitnami.com/bitnami
  version: 17.15.2
digest: sha256:xxx
generated: "2024-01-15T00:00:00Z"
```

### 5.3.3 本地依赖

```yaml
# Chart.yaml
dependencies:
  - name: mylib
    version: "1.0.0"
    repository: "file://../mylib"

# 目录结构：
# workspace/
# ├── myapp/
# │   ├── Chart.yaml
# │   └── charts/
# └── mylib/
#     ├── Chart.yaml
#     └── templates/

# 更新本地依赖
helm dependency update ./myapp
```

---

## 5.4 子Chart配置

### 5.4.1 配置子Chart

```yaml
# values.yaml

# 主应用配置
replicaCount: 3
image:
  repository: myapp
  tag: "1.0.0"

# 子Chart配置（使用Chart名称作为顶级键）
postgresql:
  enabled: true
  auth:
    postgresPassword: "secret"
    database: "myapp"
  primary:
    persistence:
      size: 10Gi

redis:
  enabled: true
  auth:
    password: "secret"
  master:
    persistence:
      size: 1Gi
```

### 5.4.2 使用别名

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    alias: primary-db

  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    alias: replica-db

# values.yaml
primary-db:
  enabled: true
  auth:
    database: "primary"

replica-db:
  enabled: true
  auth:
    database: "replica"
```

### 5.4.3 条件依赖

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled

  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled

# values.yaml
postgresql:
  enabled: true

redis:
  enabled: false

# 安装时只有postgresql会被部署
```

### 5.4.4 标签分组

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    tags:
      - database

  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    tags:
      - cache

  - name: prometheus
    version: "15.x.x"
    repository: https://prometheus-community.github.io/helm-charts
    tags:
      - monitoring

# 安装时使用标签
helm install myapp ./mychart --tags database

# 只安装database标签的依赖
# prometheus和redis不会被安装
```

---

## 5.5 导入子Chart值

### 5.5.1 import-values语法

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    import-values:
      - child: service.port
        parent: database.port
      - child: auth
        parent: database.auth

# 导入后可以在父Chart中访问：
# .Values.database.port
# .Values.database.auth
```

### 5.5.2 导入所有值

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    import-values:
      - data

# 所有postgresql的值被导入到 .Values.postgresql
```

---

## 5.6 依赖最佳实践

### 5.6.1 版本锁定

```yaml
# 开发环境：使用范围版本
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami

# 生产环境：使用精确版本
dependencies:
  - name: postgresql
    version: "12.12.0"
    repository: https://charts.bitnami.com/bitnami

# 提交Chart.lock到版本控制
# 确保团队成员使用相同版本的依赖
```

### 5.6.2 条件依赖设计

```yaml
# 好的设计：默认禁用外部依赖
postgresql:
  enabled: false
  # 外部PostgreSQL配置
  external:
    host: postgres.example.com
    port: 5432
    database: myapp
    existingSecret: postgres-secret

# 内置PostgreSQL配置（仅在enabled=true时使用）
  auth:
    postgresPassword: ""
    database: myapp

# 模板中处理
{{- if .Values.postgresql.enabled }}
# 使用内置PostgreSQL
{{- else }}
# 使用外部PostgreSQL
{{- end }}
```

### 5.6.3 避免依赖地狱

```
┌─────────────────────────────────────────────────────────────────┐
│  避免依赖问题                                                    │
└─────────────────────────────────────────────────────────────────┘

1. 最小化依赖
   ├── 只依赖必要的Chart
   ├── 考虑使用外部服务
   └── 避免过度依赖

2. 版本约束
   ├── 使用明确的版本范围
   ├── 定期更新依赖
   └── 测试依赖升级

3. 依赖隔离
   ├── 使用别名区分实例
   ├── 避免命名冲突
   └── 合理配置资源

4. 文档化依赖
   ├── 说明依赖用途
   ├── 记录配置选项
   └── 提供升级指南
```
