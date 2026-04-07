# GCP Secret Manager 集成

## 1. 概述

### 1.1 为什么需要外部Secret管理

```
┌─────────────────────────────────────────────────────────────────┐
│  Kubernetes原生Secret的问题                                       │
└─────────────────────────────────────────────────────────────────┘

问题1: 安全性不足
├── Secret存储在etcd中（Base64编码，非加密）
├── 容易被集群管理员访问
├── 难以实现细粒度权限控制
└── 不符合合规要求

问题2: 管理困难
├── Secret需要手动创建和更新
├── 多环境配置复杂
├── 密钥轮换困难
└── 缺乏审计日志

问题3: 分发问题
├── 不能将Secret提交到Git
├── CI/CD流程中难以安全传递
├── 开发人员需要访问生产密钥
└── 密钥泄露风险高

GCP Secret Manager解决方案：
├── 云端安全存储
├── 细粒度IAM权限控制
├── 自动密钥版本管理
├── 完整审计日志
├── 与Kubernetes无缝集成
```

### 1.2 集成架构

```
┌─────────────────────────────────────────────────────────────────┐
│  GCP Secret Manager与Kubernetes集成架构                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────────┐     ┌─────────────┐
│ GCP Secret  │     │ External Secrets │     │ Kubernetes  │
│   Manager   │────▶│    Operator      │────▶│    Secret   │
└─────────────┘     └─────────────────┘     └─────────────┘
       │                     │                     │
       │                     ▼                     ▼
       │              ┌─────────────┐       ┌─────────────┐
       │              │ SecretStore │       │ Application │
       │              │    CRD      │       │    Pod      │
       │              └─────────────┘       └─────────────┘
       │
       ├─ secret-1 (DB_PASSWORD)
       ├─ secret-2 (API_KEY)
       └─ secret-3 (TLS_CERT)

工作流程：
1. 在GCP Secret Manager中存储密钥
2. 创建ExternalSecret CRD定义同步规则
3. External Secrets Operator从GCP拉取密钥
4. 自动创建/更新Kubernetes Secret
5. 应用通过标准方式使用Kubernetes Secret
```

---

## 2. GCP Secret Manager基础

### 2.1 创建和管理Secret

```bash
# 启用Secret Manager API
gcloud services enable secretmanager.googleapis.com

# 创建Secret
gcloud secrets create my-db-password \
  --replication-policy="automatic"

# 添加Secret版本（存储实际值）
echo -n "my-super-secret-password" | \
  gcloud secrets versions add my-db-password \
  --data-file=-

# 从文件创建Secret
gcloud secrets create tls-certificate \
  --replication-policy="automatic"

gcloud secrets versions add tls-certificate \
  --data-file=./certificate.pem

# 列出所有Secret
gcloud secrets list

# 查看Secret详情
gcloud secrets describe my-db-password

# 获取Secret值（最新版本）
gcloud secrets versions access latest \
  --secret=my-db-password

# 获取特定版本的Secret
gcloud secrets versions access 3 \
  --secret=my-db-password

# 销毁Secret版本
gcloud secrets versions destroy 1 \
  --secret=my-db-password

# 删除Secret
gcloud secrets delete my-db-password
```

### 2.2 IAM权限配置

```bash
# 创建Service Account用于Kubernetes访问
gcloud iam service-accounts create k8s-secrets-reader \
  --display-name="Kubernetes Secrets Reader"

# 授予Secret Viewer角色
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:k8s-secrets-reader@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretViewer"

# 授予Secret Accessor角色（可读取Secret内容）
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:k8s-secrets-reader@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 为特定Secret授予更精细的权限
gcloud secrets add-iam-policy-binding my-db-password \
  --member="serviceAccount:k8s-secrets-reader@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# 创建Service Account Key（JSON格式）
gcloud iam service-accounts keys create ./k8s-secrets-key.json \
  --iam-account=k8s-secrets-reader@${PROJECT_ID}.iam.gserviceaccount.com

# 使用Workload Identity（推荐）
gcloud iam service-accounts add-iam-policy-binding \
  k8s-secrets-reader@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${NAMESPACE}/myapp@${PROJECT_ID}.svc.id.goog"
```

---

## 3. External Secrets Operator安装

### 3.1 安装Operator

```bash
# 方法1: 使用Helm安装
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true

# 方法2: 使用kubectl安装
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/clustersecretstore.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/externalsecret.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/manifests/deploy.yaml

# 验证安装
kubectl get pods -n external-secrets
kubectl get crd | grep external-secrets
```

### 3.2 配置ClusterSecretStore

```yaml
# cluster-secretstore.yaml - 使用Service Account Key
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: my-gcp-project
      auth:
        secretRef:
          secretAccessKey:
            name: gcp-service-account-key
            key: sa.json
---
apiVersion: v1
kind: Secret
metadata:
  name: gcp-service-account-key
  namespace: external-secrets
type: Opaque
stringData:
  sa.json: |
    {
      "type": "service_account",
      "project_id": "my-gcp-project",
      "private_key_id": "...",
      "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
      "client_email": "k8s-secrets-reader@my-gcp-project.iam.gserviceaccount.com",
      ...
    }
```

```yaml
# cluster-secretstore-workload-identity.yaml - 使用Workload Identity（推荐）
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: my-gcp-project
      auth:
        workloadIdentity:
          serviceAccountEmail: k8s-secrets-reader@my-gcp-project.iam.gserviceaccount.com
```

```bash
# 应用配置
kubectl apply -f cluster-secretstore.yaml

# 验证ClusterSecretStore
kubectl get clustersecretstore gcp-secret-manager
kubectl describe clustersecretstore gcp-secret-manager
```

---

## 4. 同步GCP Secret到Kubernetes

### 4.1 基础ExternalSecret

```yaml
# external-secret-basic.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: db-password-k8s
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: my-db-password
```

```bash
# 应用ExternalSecret
kubectl apply -f external-secret-basic.yaml

# 查看创建的Kubernetes Secret
kubectl get secret db-password-k8s -n production
kubectl describe secret db-password-k8s -n production

# 输出：
# Name:         db-password-k8s
# Namespace:    production
# Labels:       <none>
# Annotations:  <none>
#
# Type:  Opaque
# Data
# ====
# password:  24 bytes
```

### 4.2 同步多个字段

```yaml
# external-secret-multi.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
  namespace: production
spec:
  refreshInterval: 30m
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: app-config-k8s
    creationPolicy: Owner
    template:
      type: Opaque
      metadata:
        labels:
          app: myapp
          environment: production
        annotations:
          external-secrets.io/provider: gcp
  dataFrom:
    - extract:
        key: app-database-config
        conversionStrategy: Default
        decodingStrategy: None
    # 或者指定多个key
    - extract:
        key: api-keys
        property: production-api-key
```

### 4.3 JSON格式的Secret

```yaml
# GCP Secret Manager中存储JSON格式
# {"db_host": "localhost", "db_port": "5432", "db_name": "myapp"}

# external-secret-json.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-config
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: database-config-k8s
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: database-config-json
        decodingStrategy: Auto
        rewrite:
          - regexp:
              source: "(.*)"
              target: "$1"
```

### 4.4 特定版本同步

```yaml
# external-secret-version.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password-v3
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: db-password-v3-k8s
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: my-db-password
        version: "3"  # 指定特定版本
```

---

## 5. 应用如何获取和使用Secret

### 5.1 通过环境变量注入

```yaml
# deployment-with-env.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0.0
          ports:
            - containerPort: 8080
          env:
            # 方式1: 直接引用Kubernetes Secret
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-password-k8s
                  key: password
            
            # 方式2: 引用整个ConfigMap中的变量
            envFrom:
              - secretRef:
                  name: app-config-k8s
```

### 5.2 通过Volume挂载

```yaml
# deployment-with-volume.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0.0
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: secrets
              mountPath: /etc/secrets
              readOnly: true
            - name: certs
              mountPath: /etc/certs
              readOnly: true
      volumes:
        # 挂载单个Secret作为文件
        - name: secrets
          secret:
            secretName: db-password-k8s
        # 挂载证书Secret
        - name: certs
          secret:
            secretName: tls-cert-k8s
```

### 5.3 使用CSI Driver直接挂载

```bash
# 安装GCP Secrets CSI Driver
helm repo add csi-secrets-store-provider-gcp https://raw.githubusercontent.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/main/charts
helm install csi-secrets-store-provider-gcp csi-secrets-store-provider-gcp/csi-secrets-store-provider-gcp \
  -n kube-system \
  --set secrets.provider=gcpsm
```

```yaml
# deployment-with-csi.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-csi
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp-csi
  template:
    metadata:
      labels:
        app: myapp-csi
    spec:
      serviceAccountName: myapp-sa
      containers:
        - name: myapp
          image: myapp:v1.0.0
          volumeMounts:
            - name: secrets-store-inline
              mountPath: "/mnt/secrets-store"
              readOnly: true
      volumes:
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "gcp-secret-provider-class"
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: gcp-secret-provider-class
spec:
  provider: gcpsm
  parameters:
    secrets: |
      - resourceName: "projects/my-gcp-project/secrets/my-db-password/versions/latest"
        fileName: "db_password.txt"
      - resourceName: "projects/my-gcp-project/secrets/api-key/versions/latest"
        fileName: "api_key.txt"
```

---

## 6. Helm Chart集成

### 6.1 Helm Values配置

```yaml
# values.yaml
externalSecrets:
  enabled: true
  
  secrets:
    - name: db-password
      storeName: gcp-secret-manager
      targetName: db-password-k8s
      data:
        - secretKey: password
          remoteRef:
            key: my-db-password
    
    - name: api-key
      storeName: gcp-secret-manager
      targetName: api-key-k8s
      data:
        - secretKey: apiKey
          remoteRef:
            key: my-api-key
    
    - name: tls-cert
      storeName: gcp-secret-manager
      targetName: tls-cert-k8s
      data:
        - secretKey: tls.crt
          remoteRef:
            key: my-tls-cert
        - secretKey: tls.key
          remoteRef:
            key: my-tls-key
```

### 6.2 Helm模板

```yaml
# templates/externalsecrets.yaml
{{- if .Values.externalSecrets.enabled }}
{{- range $secret := .Values.externalSecrets.secrets }}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $secret.name }}
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "myapp.labels" $ | nindent 4 }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: {{ $secret.storeName }}
  target:
    name: {{ $secret.targetName }}
    creationPolicy: Owner
  data:
    {{- range $item := $secret.data }}
    - secretKey: {{ $item.secretKey }}
      remoteRef:
        key: {{ $item.remoteRef.key }}
        {{- if $item.remoteRef.version }}
        version: "{{ $item.remoteRef.version }}"
        {{- end }}
    {{- end }}
{{- end }}
{{- end }}
```

### 6.3 应用部署模板

```yaml
# templates/deployment.yaml
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
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          {{- if .Values.externalSecrets.enabled }}
          envFrom:
            {{- range $secret := .Values.externalSecrets.secrets }}
            - secretRef:
                name: {{ $secret.targetName }}
            {{- end }}
          {{- end }}
```

---

## 7. 高级配置

### 7.1 自动刷新策略

```yaml
# external-secret-refresh.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password-auto-refresh
  namespace: production
spec:
  refreshInterval: 5m  # 每5分钟检查一次更新
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: db-password-refreshed
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: my-db-password
```

### 7.2 更新策略

```yaml
# external-secret-update-policy.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password-policy
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: db-password-policy
    creationPolicy: Owner
    updatePolicy: Merge  # 或 Replace
  data:
    - secretKey: password
      remoteRef:
        key: my-db-password
```

### 7.3 命名空间级别的SecretStore

```yaml
# secretstore-namespace.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-secret-manager
  namespace: team-a
spec:
  provider:
    gcpsm:
      projectID: my-gcp-project
      auth:
        workloadIdentity:
          serviceAccountEmail: team-a-secrets-reader@my-gcp-project.iam.gserviceaccount.com
```

---

## 8. 最佳实践

### 8.1 安全最佳实践

```
┌─────────────────────────────────────────────────────────────────┐
│  GCP Secret Manager安全最佳实践                                   │
└─────────────────────────────────────────────────────────────────┘

1. 最小权限原则
   ├── 使用Workload Identity而非Service Account Key
   ├── 为每个命名空间/应用创建专用SA
   ├── 只授予必要的Secret访问权限
   └── 定期审查和清理权限

2. Secret生命周期管理
   ├── 定期轮换密钥
   ├── 设置合理的TTL
   ├── 及时销毁旧版本
   └── 启用自动删除策略

3. 审计和监控
   ├── 启用Cloud Audit Logs
   ├── 监控Secret访问模式
   ├── 设置告警规则
   └── 定期审查访问记录

4. 网络安全
   ├── 使用VPC Service Controls
   ├── 限制IP访问范围
   ├── 启用Private Google Access
   └── 配置防火墙规则
```

### 8.2 运维最佳实践

```bash
# 1. 监控External Secrets Operator状态
kubectl get externalsecrets -A
kubectl describe externalsecrets db-password -n production

# 2. 查看同步事件
kubectl get events -n production --field-selector reason=Synced
kubectl get events -n production --field-selector reason=SyncError

# 3. 强制刷新Secret
kubectl annotate externalsecrets db-password force-sync=$(date +%s) -n production

# 4. 检查Secret健康状态
kubectl get externalsecrets -o wide -A

# 5. 备份和恢复
# 导出ExternalSecret配置
kubectl get externalsecrets -A -o yaml > externalsecrets-backup.yaml

# 导入恢复
kubectl apply -f externalsecrets-backup.yaml
```

### 8.3 故障排除

```bash
# 常见问题及解决方法

# 问题1: ExternalSecret无法同步
# 解决：检查ClusterSecretStore状态
kubectl describe clustersecretstore gcp-secret-manager
kubectl logs -l app=external-secrets-operator -n external-secrets

# 问题2: 权限错误
# 解决：验证Service Account权限
gcloud secrets describe my-db-password
gcloud secrets get-iam-policy my-db-password

# 问题3: Secret不存在
# 解决：确认Secret名称正确
gcloud secrets list --filter="name:my-db-password"

# 问题4: Workload Identity未生效
# 解决：检查Pod注解和服务账户
kubectl describe pod myapp-pod -n production | grep -A10 "Annotations:"
```
