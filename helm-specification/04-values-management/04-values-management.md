# Values配置管理

## 4.1 Values优先级

### 4.1.1 优先级顺序

```
┌─────────────────────────────────────────────────────────────────┐
│  Values优先级（从高到低）                                        │
└─────────────────────────────────────────────────────────────────┘

1. --set-file           从文件读取的值
2. --set-string         强制字符串类型的值
3. --set                命令行设置的值
4. -f/--values          Values文件（最后一个文件优先级最高）
5. values.yaml          Chart默认Values
6. Chart默认值          模板中定义的默认值

示例：
helm install myapp ./mychart \
  --values values.yaml \
  --values values-prod.yaml \
  --set replicaCount=5 \
  --set-string image.tag="v1.0.0"

优先级：
values-prod.yaml > values.yaml > values.yaml(Chart内) > 模板默认值
--set > -f/--values
```

### 4.1.2 --set语法

```bash
# 基本设置
helm install myapp ./mychart --set replicaCount=3

# 嵌套值
helm install myapp ./mychart --set image.repository=nginx

# 列表值
helm install myapp ./mychart --set servers[0].port=80

# 多个值
helm install myapp ./mychart --set replicaCount=3,image.tag=v1.0.0

# 特殊字符转义
helm install myapp ./mychart --set name="value\,with\,commas"

# null值（删除值）
helm install myapp ./mychart --set image.tag=null
```

### 4.1.3 --set-file语法

```bash
# 从文件读取值
helm install myapp ./mychart --set-file config.content=config.ini

# 文件内容会被作为字符串值
# config.ini:
# key1=value1
# key2=value2

# 结果：
# config.content: "key1=value1\nkey2=value2"
```

### 4.1.4 --set-string语法

```bash
# 强制字符串类型
helm install myapp ./mychart --set-string port="8080"

# 区别：
# --set port=8080     -> 整数 8080
# --set-string port="8080" -> 字符串 "8080"

# 适用场景：确保数字作为字符串处理
helm install myapp ./mychart --set-string version="1.0"
```

---

## 4.2 多环境配置

### 4.2.1 环境分离策略

```
┌─────────────────────────────────────────────────────────────────┐
│  多环境配置策略                                                  │
└─────────────────────────────────────────────────────────────────┘

策略1: 独立Values文件
├── values.yaml           基础配置
├── values-dev.yaml       开发环境
├── values-staging.yaml   预发布环境
└── values-prod.yaml      生产环境

策略2: 环境目录
├── values/
│   ├── base.yaml         基础配置
│   ├── dev/
│   │   └── values.yaml
│   ├── staging/
│   │   └── values.yaml
│   └── prod/
│       └── values.yaml

策略3: Helmfile管理
├── helmfile.yaml
├── environments/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── prod.yaml
└── values/
    └── ...
```

### 4.2.2 独立Values文件

```yaml
# values.yaml - 基础配置
replicaCount: 1

image:
  repository: myapp
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# values-dev.yaml - 开发环境
replicaCount: 1

image:
  tag: dev

service:
  type: NodePort
  nodePort: 30080

ingress:
  enabled: true
  hosts:
    - host: dev.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 50m
    memory: 64Mi

# values-staging.yaml - 预发布环境
replicaCount: 2

image:
  tag: staging

service:
  type: ClusterIP

ingress:
  enabled: true
  hosts:
    - host: staging.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: staging-tls
      hosts:
        - staging.example.com

# values-prod.yaml - 生产环境
replicaCount: 3

image:
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP

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

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: myapp
        topologyKey: kubernetes.io/hostname
```

### 4.2.3 使用多个Values文件

```bash
# 基础配置 + 环境配置
helm install myapp ./mychart \
  -f values.yaml \
  -f values-prod.yaml

# 后面的文件会覆盖前面的值
# values-prod.yaml 中的值会覆盖 values.yaml 中的同名值

# 查看合并后的值
helm template myapp ./mychart \
  -f values.yaml \
  -f values-prod.yaml \
  --show-only templates/deployment.yaml
```

### 4.2.4 Helmfile管理

```yaml
# helmfile.yaml
environments:
  dev:
    values:
      - environments/dev.yaml
  staging:
    values:
      - environments/staging.yaml
  prod:
    values:
      - environments/prod.yaml

releases:
  - name: myapp
    namespace: {{ .Values.namespace }}
    chart: ./mychart
    values:
      - values.yaml
      - values-{{ .Environment.Name }}.yaml
    set:
      - name: image.tag
        value: {{ .Values.imageTag }}

# environments/dev.yaml
namespace: dev
imageTag: dev

# environments/prod.yaml
namespace: prod
imageTag: v1.0.0

# 使用
helmfile -e dev apply
helmfile -e prod apply
```

---

## 4.3 Values合并策略

### 4.3.1 深度合并

```yaml
# values.yaml
config:
  database:
    host: localhost
    port: 5432
    name: mydb
  cache:
    host: localhost
    port: 6379

# values-prod.yaml
config:
  database:
    host: prod-db.example.com
    port: 5432

# 合并结果（深度合并）
config:
  database:
    host: prod-db.example.com  # 覆盖
    port: 5432                 # 保留
    name: mydb                 # 保留
  cache:                       # 整个保留
    host: localhost
    port: 6379
```

### 4.3.2 列表覆盖

```yaml
# values.yaml
env:
  - name: ENV1
    value: value1
  - name: ENV2
    value: value2

# values-prod.yaml
env:
  - name: ENV3
    value: value3

# 合并结果（列表完全替换，不是合并）
env:
  - name: ENV3
    value: value3

# 如果需要合并列表，需要使用不同的键
# values.yaml
defaultEnv:
  - name: ENV1
    value: value1

# values-prod.yaml
extraEnv:
  - name: ENV3
    value: value3

# 模板中合并
env:
  {{- toYaml .Values.defaultEnv | nindent 2 }}
  {{- toYaml .Values.extraEnv | nindent 2 }}
```

### 4.3.3 null值删除

```yaml
# values.yaml
config:
  database:
    host: localhost
    port: 5432
  cache:
    enabled: true

# values-prod.yaml
config:
  cache: null

# 合并结果（cache被删除）
config:
  database:
    host: localhost
    port: 5432

# 使用--set删除
helm install myapp ./mychart --set config.cache=null
```

---

## 4.4 JSON Schema验证

### 4.4.1 Schema结构

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
      "default": 1,
      "description": "Number of replicas for the deployment"
    },
    "image": {
      "type": "object",
      "required": [
        "repository"
      ],
      "properties": {
        "repository": {
          "type": "string",
          "minLength": 1,
          "description": "Container image repository"
        },
        "tag": {
          "type": "string",
          "description": "Container image tag"
        },
        "pullPolicy": {
          "type": "string",
          "enum": [
            "Always",
            "IfNotPresent",
            "Never"
          ],
          "default": "IfNotPresent"
        }
      }
    },
    "service": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "ClusterIP",
            "NodePort",
            "LoadBalancer",
            "ExternalName"
          ]
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
            "required": [
              "host"
            ],
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
                      "enum": [
                        "Exact",
                        "Prefix",
                        "ImplementationSpecific"
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "resources": {
      "type": "object",
      "properties": {
        "limits": {
          "type": "object",
          "properties": {
            "cpu": {
              "type": "string",
              "pattern": "^[0-9]+m?$"
            },
            "memory": {
              "type": "string",
              "pattern": "^[0-9]+(Ki|Mi|Gi|Ti)?$"
            }
          }
        },
        "requests": {
          "type": "object",
          "properties": {
            "cpu": {
              "type": "string",
              "pattern": "^[0-9]+m?$"
            },
            "memory": {
              "type": "string",
              "pattern": "^[0-9]+(Ki|Mi|Gi|Ti)?$"
            }
          }
        }
      }
    }
  }
}
```

### 4.4.2 Schema验证示例

```bash
# 安装时自动验证
helm install myapp ./mychart -f values.yaml

# 验证失败示例
# Error: values don't meet the specifications of the schema(s):
# - (root): image is required
# - service.type: service.type must be one of: "ClusterIP", "NodePort", "LoadBalancer"
# - replicaCount: must be <= 100

# 使用--dry-run验证
helm install myapp ./mychart -f values.yaml --dry-run
```

### 4.4.3 常用Schema模式

```json
{
  "required": ["必须字段"],

  "properties": {
    "stringField": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100,
      "pattern": "^[a-z]+$"
    },
    "numberField": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "enumField": {
      "type": "string",
      "enum": ["value1", "value2", "value3"]
    },
    "arrayField": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "string"
      }
    },
    "objectField": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    },
    "booleanField": {
      "type": "boolean"
    },
    "nullableField": {
      "type": ["string", "null"]
    }
  }
}
```

---

## 4.5 敏感信息管理

### 4.5.1 敏感信息策略

```
┌─────────────────────────────────────────────────────────────────┐
│  敏感信息管理策略                                                │
└─────────────────────────────────────────────────────────────────┘

策略1: helm-secrets插件
├── 加密values文件
├── 支持多种加密后端
└── Git友好

策略2: 外部Secret管理
├── HashiCorp Vault
├── AWS Secrets Manager
├── Azure Key Vault
└── External Secrets Operator

策略3: Sealed Secrets
├── 加密Secret资源
├── 可存储在Git
└── 集群内解密

策略4: 环境变量注入
├── 运行时注入
├── 不存储在Chart
└── CI/CD系统集成
```

### 4.5.2 helm-secrets插件

```bash
# 安装插件
helm plugin install https://github.com/jkroepke/helm-secrets

# 创建加密文件
helm secrets encrypt values-prod.yaml > values-prod.encrypted.yaml

# 编辑加密文件
helm secrets edit values-prod.yaml

# 使用加密文件
helm secrets install myapp ./mychart -f values-prod.yaml

# 查看加密文件
helm secrets view values-prod.yaml

# 解密文件
helm secrets decrypt values-prod.yaml > values-prod.decrypted.yaml
```

### 4.5.3 External Secrets Operator

```yaml
# ExternalSecret资源
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: myapp-secrets
    creationPolicy: Owner
  data:
    - secretKey: database-password
      remoteRef:
        key: myapp/database
        property: password
    - secretKey: api-key
      remoteRef:
        key: myapp/api
        property: key

# Helm模板引用
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: myapp-secrets
        key: database-password
```

### 4.5.4 Values中的敏感信息处理

```yaml
# 不好的做法 - 明文存储
database:
  password: "my-secret-password"

# 好的做法1 - 引用现有Secret
database:
  existingSecret: "myapp-db-secret"
  existingSecretKey: "password"

# 模板中处理
{{- if .Values.database.existingSecret }}
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.database.existingSecret }}
        key: {{ .Values.database.existingSecretKey }}
{{- else }}
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "myapp.fullname" . }}-db
        key: password
{{- end }}

# 好的做法2 - 使用helm-secrets
# values-secrets.yaml (加密存储)
database:
  password: {{ .Values.database.password }}

# 安装时解密
helm secrets install myapp ./mychart -f values-secrets.yaml
```

---

## 4.6 Values设计最佳实践

### 4.6.1 结构设计

```yaml
# 好的结构设计

# 1. 镜像配置
image:
  repository: myapp
  tag: ""  # 空字符串，使用.Chart.AppVersion
  pullPolicy: IfNotPresent

# 2. 副本和扩缩容
replicaCount: 1
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

# 3. 服务配置
service:
  type: ClusterIP
  port: 80
  targetPort: http

# 4. 入口配置
ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts: []
  tls: []

# 5. 资源配置
resources:
  limits: {}
  requests: {}

# 6. 安全配置
podSecurityContext: {}
securityContext: {}

# 7. 调度配置
nodeSelector: {}
tolerations: []
affinity: {}

# 8. 扩展配置
extraEnv: []
extraVolumes: []
extraVolumeMounts: []
extraContainers: []
extraInitContainers: []
```

### 4.6.2 命名规范

```yaml
# 好的命名
replicaCount: 3
imagePullSecrets: []
podAnnotations: {}
serviceAccount:
  create: true
  name: ""

# 不好的命名
replicas: 3           # 不够明确
image_pull_secrets: [] # 使用下划线
pod-annotations: {}    # 使用连字符

# 布尔值命名
ingress.enabled: true    # 好的
service.create: true     # 好的
ingress.enable: true     # 不一致

# 列表和字典命名
extraEnv: []             # 复数形式
extraVolumes: []         # 复数形式
podAnnotations: {}       # 复数形式
```

### 4.6.3 默认值策略

```yaml
# 策略1: 安全默认值
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true

# 策略2: 最小资源
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 10m
    memory: 32Mi

# 策略3: 可选功能默认关闭
ingress:
  enabled: false

autoscaling:
  enabled: false

# 策略4: 空值表示可选
imagePullSecrets: []
nodeSelector: {}
tolerations: []
affinity: {}
```

### 4.6.4 文档化Values

```yaml
# values.yaml with comments

# -- Number of replicas for the deployment
# @default -- 1
replicaCount: 1

# -- Container image configuration
image:
  # -- Image repository
  repository: nginx
  # -- Image tag
  # @default -- .Chart.AppVersion
  tag: ""
  # -- Image pull policy
  # @default -- IfNotPresent
  pullPolicy: IfNotPresent

# -- Service configuration
service:
  # -- Service type
  # Options: ClusterIP, NodePort, LoadBalancer
  type: ClusterIP
  # -- Service port
  port: 80

# -- Ingress configuration
ingress:
  # -- Enable ingress
  enabled: false
  # -- Ingress class name
  className: ""
  # -- Ingress annotations
  annotations: {}
  # -- Ingress hosts
  hosts: []
  # -- Ingress TLS configuration
  tls: []
```

---

## 4.7 查看和管理Values

### 4.7.1 查看Values

```bash
# 查看Chart默认values
helm show values ./mychart
helm show values bitnami/nginx

# 查看已安装Release的values
helm get values myapp

# 查看所有values（包括默认值）
helm get values myapp --all

# 查看values的JSON格式
helm get values myapp -o json

# 查看values的YAML格式
helm get values myapp -o yaml
```

### 4.7.2 升级时复用Values

```bash
# 复用上次安装的values
helm upgrade myapp ./mychart --reuse-values

# 复用values并覆盖特定值
helm upgrade myapp ./mychart --reuse-values --set replicaCount=5

# 重置为默认values
helm upgrade myapp ./mychart --reset-values

# 注意：--reuse-values和--reset-values不能同时使用
```

### 4.7.3 比较Values

```bash
# 使用helm-diff插件比较差异
helm plugin install https://github.com/databus23/helm-diff

# 比较升级前后的差异
helm diff upgrade myapp ./mychart

# 比较不同values文件的差异
helm diff upgrade myapp ./mychart -f values-prod.yaml

# 比较不同版本
helm diff revision myapp 1 2
```
