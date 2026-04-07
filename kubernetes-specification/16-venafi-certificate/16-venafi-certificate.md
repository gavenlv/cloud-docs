# Venafi 证书管理集成

## 1. 概述

### 1.1 为什么需要证书自动化管理

```
┌─────────────────────────────────────────────────────────────────┐
│  传统证书管理的痛点                                               │
└─────────────────────────────────────────────────────────────────┘

问题1: 手动操作风险高
├── 人工申请、审批流程繁琐
├── 容易忘记续期导致服务中断
├── 私钥泄露风险
└── 人为错误难以避免

问题2: 合规要求严格
├── PCI DSS要求证书有效期不超过398天
├── GDPR要求数据加密传输
├── SOX要求密钥管理审计
└── 行业监管要求PKI合规

问题3: 大规模部署困难
├── 微服务架构需要大量证书
├── 多环境、多集群证书管理复杂
├── 证书生命周期难以追踪
└── 缺乏统一的证书清单

Venafi解决方案：
├── 企业级PKI管理平台
├── 自动化证书签发和续期
├── 集中化密钥存储和管理
├── 完整的审计和合规报告
├── 与Kubernetes深度集成
```

### 1.2 集成架构

```
┌─────────────────────────────────────────────────────────────────┐
│  Venafi与Kubernetes集成架构                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────────┐     ┌─────────────┐
│   Venafi    │     │ cert-manager    │     │ Kubernetes  │
│   Platform  │────▶│   Operator      │────▶│ Certificate │
└─────────────┘     └─────────────────┘     └─────────────┘
       │                     │                     │
       │                     ▼                     ▼
       │              ┌─────────────┐       ┌─────────────┐
       │              │ Issuer/     │       │ Ingress/TLS │
       │              │ ClusterIssuer│      │ Termination │
       │              └─────────────┘       └─────────────┘
       │
       ├─ TPP (Trust Protection Platform)
       ├─ Cloud (Venafi as a Service)
       └─ TLS Protect for Kubernetes

工作流程：
1. 创建Certificate CRD定义证书需求
2. cert-manager向Venafi请求签名
3. Venafi验证并签发证书
4. cert-manager创建Kubernetes Secret
5. 自动配置Ingress/TLS终止
6. 定期自动续期（默认30天前）
```

---

## 2. Venafi平台介绍

### 2.1 Venafi产品线

```
┌─────────────────────────────────────────────────────────────────┐
│  Venafi产品选择指南                                              │
└─────────────────────────────────────────────────────────────────┘

1. Venafi TPP (Trust Protection Platform)
   ├── 企业内部部署
   ├── 完整的PKI功能
   ├── 支持所有主流CA
   ├── 高度可定制
   └── 适合大型企业

2. Venafi Cloud (TaaS - Trust as a Service)
   ├── SaaS模式，无需维护
   ├── 快速上手
   ├── 按需付费
   ├── 自动升级
   └── 适合中小型企业

3. TLS Protect for Kubernetes
   ├── Kubernetes原生集成
   ├── 简化的证书管理
   ├── 内置cert-manager支持
   ├── 开箱即用
   └── 专门针对K8s优化
```

### 2.2 Venafi Cloud配置

```bash
# 1. 登录Venafi Cloud控制台
# https://cloud.venafi.com/

# 2. 创建API Key
# 导航到: Settings -> API Keys -> Create API Key
# 记录API Key和Zone信息

# 3. 配置Zone (Certificate Issuing Template)
# Zone格式: <zone-name>
# 例如: "kubernetes-production"

# 4. 验证连接
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.venafi.cloud/v1/zones
```

### 2.3 Venafi TPP配置

```bash
# 1. 获取TPP访问凭据
# - URL: https://tpp.example.com
# - Username/Password 或 API Key
# - Zone/Certificate Template名称

# 2. 验证连接
curl -k --user 'username:password' \
  'https://tpp.example.com/VedSDK/Authorize'

# 3. 获取可用Zone列表
curl -k --user 'username:password' \
  'https://tpp.example.com/VedSDK/Config/Read'
```

---

## 3. cert-manager安装和配置

### 3.1 安装cert-manager

```bash
# 方法1: 使用Helm安装（推荐）
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  -n cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --version v1.14.0

# 方法2: 使用kubectl安装
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# 验证安装
kubectl get pods -n cert-manager
kubectl get crd | grep cert-manager
```

### 3.2 配置Venafi ClusterIssuer

```yaml
# clusterissuer-venafi-cloud.yaml - Venafi Cloud
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: venafi-cloud-issuer
spec:
  venafi:
    zone: "kubernetes-production"
    api:
      tokenRef:
        key: api-key
        name: venafi-api-secret
---
apiVersion: v1
kind: Secret
metadata:
  name: venafi-api-secret
  namespace: cert-manager
type: Opaque
stringData:
  api-key: "YOUR_VENAFI_CLOUD_API_KEY"
```

```yaml
# clusterissuer-venafi-tpp.yaml - Venafi TPP
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: venafi-tpp-issuer
spec:
  venafi:
    zone: "Certificates\\Kubernetes\\Production"
    tpp:
      url: https://tpp.example.com
      credentialsRef:
        name: venafi-tpp-credentials
        namespace: cert-manager
---
apiVersion: v1
kind: Secret
metadata:
  name: venafi-tpp-credentials
  namespace: cert-manager
type: Opaque
stringData:
  username: "your-username"
  password: "your-password"
```

```bash
# 应用ClusterIssuer配置
kubectl apply -f clusterissuer-venafi-cloud.yaml

# 验证ClusterIssuer状态
kubectl get clusterissuer
kubectl describe clusterissuer venafi-cloud-issuer
```

---

## 4. 证书申请和管理

### 4.1 基础证书申请

```yaml
# certificate-basic.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-tls-cert
  namespace: production
spec:
  secretName: myapp-tls-secret
  duration: 2160h  # 90天
  renewBefore: 720h  # 30天前续期
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
    - www.myapp.example.com
  usages:
    - server auth
    - client auth
  privateKey:
    algorithm: RSA
    size: 2048
```

```bash
# 申请证书
kubectl apply -f certificate-basic.yaml

# 查看证书状态
kubectl get certificate myapp-tls-cert -n production
kubectl describe certificate myapp-tls-cert -n production

# 查看创建的Secret
kubectl get secret myapp-tls-secret -n production
kubectl describe secret myapp-tls-secret -n production

# 输出：
# Name:         myapp-tls-secret
# Namespace:    production
# Type:  kubernetes.io/tls
# Data
# ====
# tls.crt:  1234 bytes
# tls.key:  1675 bytes
```

### 4.2 通配符证书

```yaml
# certificate-wildcard.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-example-com
  namespace: production
spec:
  secretName: wildcard-example-com-tls
  duration: 8760h  # 1年
  renewBefore: 2592h  # 108天前续期
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: "*.example.com"
  dnsNames:
    - "*.example.com"
    - example.com
  usages:
    - server auth
  privateKey:
    algorithm: ECDSA
    size: 256
```

### 4.3 多域名证书（SAN）

```yaml
# certificate-san.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: multi-domain-cert
  namespace: production
spec:
  secretName: multi-domain-tls
  duration: 4380h  # 6个月
  renewBefore: 1440h  # 60天前续期
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: app.example.com
  dnsNames:
    - app.example.com
    - api.example.com
    - admin.example.com
    - staging.app.example.com
  ipAddresses:
    - 10.0.0.100
  uris:
    - spiffe://example.com/myapp
  emailAddresses:
    - security@example.com
  subject:
    organizations:
      - Example Corp
    organizationalUnits:
      - Engineering
    localities:
      - San Francisco
    provinces:
      - California
    countries:
      - US
  usages:
    - server auth
    - client auth
    - digital signature
  privateKey:
    algorithm: RSA
    size: 4096
```

### 4.4 CA证书（用于mTLS）

```yaml
# certificate-ca.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-ca
  namespace: production
spec:
  isCA: true
  secretName: my-ca-secret
  duration: 17520h  # 2年
  renewBefore: 4320h  # 180天前续期
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: "My Internal CA"
  organization:
    - Example Corp
  usages:
    - signing
    - key encipherment
    - cert sign
    - crl sign
  privateKey:
    algorithm: RSA
    size: 4096
```

---

## 5. Ingress TLS自动配置

### 5.1 自动TLS终止

```yaml
# ingress-with-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "venafi-cloud-issuer"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - myapp.example.com
        - www.myapp.example.com
      secretName: myapp-ingress-tls
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-service
                port:
                  number: 80
    - host: www.myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-service
                port:
                  number: 80
```

### 5.2 使用预申请的证书

```yaml
# ingress-with-existing-cert.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress-predefined
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls-secret  # 使用之前申请的证书
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-service
                port:
                  number: 80
```

### 5.3 多路径多证书

```yaml
# ingress-multi-cert.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "venafi-cloud-issuer"
spec:
  tls:
    - hosts:
        - app1.example.com
      secretName: app1-tls
    - hosts:
        - app2.example.com
      secretName: app2-tls
  rules:
    - host: app1.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: app1-service
                port:
                  number: 8080
    - host: app2.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app2-service
                port:
                  number: 3000
```

---

## 6. mTLS双向认证

### 6.1 服务端证书

```yaml
# certificate-server-mtls.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: server-mtls-cert
  namespace: production
spec:
  secretName: server-mtls-tls
  duration: 2160h
  renewBefore: 720h
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: server.production.svc.cluster.local
  dnsNames:
    - server.production.svc.cluster.local
    - server.production
  usages:
    - server auth
  privateKey:
    algorithm: RSA
    size: 2048
```

### 6.2 客户端证书

```yaml
# certificate-client-mtls.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: client-mtls-cert
  namespace: production
spec:
  secretName: client-mtls-tls
  duration: 2160h
  renewBefore: 720h
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: client.production.svc.cluster.local
  dnsNames:
    - client.production.svc.cluster.local
  usages:
    - client auth
  privateKey:
    algorithm: RSA
    size: 2048
```

### 6.3 mTLS服务配置

```yaml
# deployment-server-mtls.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mtls-server
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mtls-server
  template:
    metadata:
      labels:
        app: mtls-server
    spec:
      containers:
        - name: mtls-server
          image: nginx:alpine
          ports:
            - containerPort: 443
          volumeMounts:
            - name: server-certs
              mountPath: /etc/nginx/tls
              readOnly: true
            - name: ca-certs
              mountPath: /etc/nginx/ca
              readOnly: true
      volumes:
        - name: server-certs
          secret:
            secretName: server-mtls-tls
        - name: ca-certs
          secret:
            secretName: my-ca-secret
---
apiVersion: v1
kind: Service
metadata:
  name: mtls-server
  namespace: production
spec:
  selector:
    app: mtls-server
  ports:
    - port: 443
      targetPort: 443
```

```yaml
# deployment-client-mtls.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mtls-client
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mtls-client
  template:
    metadata:
      labels:
        app: mtls-client
    spec:
      containers:
        - name: mtls-client
          image: curlimages/curl:latest
          command: ["sleep", "3600"]
          volumeMounts:
            - name: client-certs
              mountPath: /client/tls
              readOnly: true
            - name: ca-certs
              mountPath: /client/ca
              readOnly: true
      volumes:
        - name: client-certs
          secret:
            secretName: client-mtls-tls
        - name: ca-certs
          secret:
            secretName: my-ca-secret
```

---

## 7. Helm Chart集成

### 7.1 Helm Values配置

```yaml
# values.yaml
certManager:
  enabled: true
  
  certificates:
    - name: myapp-tls
      issuerName: venafi-cloud-issuer
      issuerKind: ClusterIssuer
      secretName: myapp-tls-secret
      commonName: myapp.example.com
      dnsNames:
        - myapp.example.com
        - www.myapp.example.com
      duration: 90d
      renewBefore: 30d
      
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "venafi-cloud-issuer"
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls-secret
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
```

### 7.2 Helm模板

```yaml
# templates/certificate.yaml
{{- if .Values.certManager.enabled }}
{{- range $cert := .Values.certManager.certificates }}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ $cert.name }}
  namespace: {{ $.Release.Namespace }}
  labels:
    {{- include "myapp.labels" $ | nindent 4 }}
spec:
  secretName: {{ $cert.secretName }}
  duration: {{ default "2160h" $cert.duration }}
  renewBefore: {{ default "720h" $cert.renewBefore }}
  issuerRef:
    name: {{ $cert.issuerName }}
    kind: {{ $cert.issuerKind }}
  commonName: {{ $cert.commonName }}
  {{- if $cert.dnsNames }}
  dnsNames:
    {{- range $cert.dnsNames }}
    - {{ . }}
    {{- end }}
  {{- end }}
  {{- if $cert.ipAddresses }}
  ipAddresses:
    {{- range $cert.ipAddresses }}
    - {{ . }}
    {{- end }}
  {{- end }}
  usages:
    - server auth
  privateKey:
    algorithm: RSA
    size: 2048
{{- end }}
{{- end }}
```

---

## 8. 监控和运维

### 8.1 证书监控

```bash
# 1. 查看所有证书状态
kubectl get certificates -A
kubectl get certificates -A -o wide

# 2. 查看即将过期的证书
kubectl get certificates -A \
  -o custom-columns='NAME:.metadata.namespace/.metadata.name,EXPIRES:.status.notAfter' \
  --sort-by=.status.notAfter

# 3. 查看证书详情
kubectl describe certificate myapp-tls-cert -n production

# 4. 查看证书事件
kubectl get events -n production --field-selector involvedObject.name=myapp-tls-cert

# 5. 检查证书内容
kubectl get secret myapp-tls-secret -n production -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### 8.2 Prometheus监控指标

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cert-manager-alerts
  namespace: monitoring
spec:
  groups:
    - name: cert-manager
      rules:
        - alert: CertManagerCertExpiringSoon
          expr: |
            certmanager_certificate_expiration_timestamp_seconds{} - time() < 86400 * 30
          for: 1h
          labels:
            severity: warning
          annotations:
            summary: "Certificate {{ $labels.name }} is expiring in less than 30 days"
            
        - alert: CertManagerCertNotReady
          expr: |
            certmanager_certificate_ready_status{condition="Ready"} == 0
          for: 10m
          labels:
            severity: critical
          annotations:
            summary: "Certificate {{ $labels.name }} is not ready"
            
        - alert: CertManagerCertRenewalFailure
          expr: |
            increase(certmanager_certificate_renewal_timestamp_seconds[24h]) == 0 and 
            certmanager_certificate_expiration_timestamp_seconds{} - time() < 86400 * 15
          for: 1h
          labels:
            severity: critical
          annotations:
            summary: "Certificate {{ $labels.name }} renewal failed"
```

### 8.3 Grafana仪表板

```json
{
  "dashboard": {
    "title": "Certificate Management",
    "panels": [
      {
        "title": "Certificate Expiry",
        "targets": [
          {
            "expr": "certmanager_certificate_expiration_timestamp_seconds",
            "legendFormat": "{{namespace}}/{{name}}"
          }
        ],
        "type": "gauge"
      },
      {
        "title": "Certificate Status",
        "targets": [
          {
            "expr": "certmanager_certificate_ready_status",
            "legendFormat": "{{namespace}}/{{name}}"
          }
        ],
        "type": "table"
      }
    ]
  }
}
```

---

## 9. 最佳实践

### 9.1 安全最佳实践

```
┌─────────────────────────────────────────────────────────────────┐
│  Venafi证书管理安全最佳实践                                        │
└─────────────────────────────────────────────────────────────────┘

1. 证书策略
   ├── 使用短有效期（90天或更短）
   ├── 启用自动续期
   ├── 定期轮换私钥
   └── 使用强加密算法（RSA 4096或ECDSA P256）

2. 权限控制
   ├── 最小权限原则
   ├── 分离签发和使用权限
   ├── 审计所有证书操作
   └── 定期审查证书清单

3. 存储安全
   ├── 不要将证书提交到Git
   ├── 使用Kubernetes Secret加密
   ├── 启用etcd加密
   └── 限制Secret访问权限

4. 网络安全
   ├── 强制HTTPS
   ├── 启用HSTS
   ├── 使用安全的TLS版本（1.2+）
   └── 禁用弱密码套件
```

### 9.2 运维最佳实践

```bash
# 1. 定期检查证书状态
#!/bin/bash
# check-certs.sh

echo "=== 证书状态检查 ==="
kubectl get certificates -A -o wide

echo ""
echo "=== 即将过期（30天内）的证书 ==="
for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get certificates -n "$ns" -o json | jq -r '
    .items[] | select(
      (.status.notAfter | fromdateiso8601) - now < 2592000
    ) | "\(.metadata.namespace)/\(.metadata.name): \(.status.notAfter)"
  '
done

echo ""
echo "=== 异常状态的证书 ==="
kubectl get certificates -A -o json | jq -r '.items[] | select(.status.conditions[].status != "True") | "\(.metadata.namespace)/\(.metadata.name): \(.status.conditions[].reason)"'
```

### 9.3 故障排除

```bash
# 常见问题及解决方法

# 问题1: 证书申请失败
# 解决：检查ClusterIssuer状态
kubectl describe clusterissuer venafi-cloud-issuer
kubectl logs -l app=cert-manager -n cert-manager

# 问题2: 证书未自动续期
# 解决：检查renewBefore设置和cert-manager日志
kubectl get certificate myapp-tls-cert -n production -o yaml
kubectl logs -l app=cert-manager -n cert-manager --tail=50

# 问题3: Venafi连接失败
# 解决：验证凭据和网络连接
kubectl get secret venafi-api-secret -n cert-manager -o yaml
# 测试Venafi API连接

# 问题4: DNS验证失败
# 解决：检查DNS记录和DNS提供商配置
kubectl describe certificaterequest <request-name> -n production

# 问题5: Ingress TLS不生效
# 解决：检查Ingress注解和证书Secret
kubectl describe ingress myapp-ingress -n production
kubectl get secret myapp-ingress-tls -n production
```

---

## 10. 高级场景

### 10.1 证书链管理

```yaml
# certificate-chain.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: fullchain-cert
  namespace: production
spec:
  secretName: fullchain-tls
  duration: 2160h
  renewBefore: 720h
  issuerRef:
    name: venafi-cloud-issuer
    kind: ClusterIssuer
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
  additionalOutputFormats:
    - type: CombinedPEM
  privateKey:
    algorithm: RSA
    size: 2048
```

### 10.2 证书导出和备份

```bash
# 导出证书和私钥
kubectl get secret myapp-tls-secret -n production -o jsonpath='{.data.tls\.crt}' | base64 -d > tls.crt
kubectl get secret myapp-tls-secret -n production -o jsonpath='{.data.tls\.key}' | base64 -d > tls.key

# 导出完整证书链
kubectl get secret fullchain-tls -n production -o jsonpath='{.data.ca\.crt}' | base64 -d > chain.crt

# 备份所有证书配置
kubectl get certificates -A -o yaml > certificates-backup.yaml
kubectl get clusterissuers -o yaml > issuers-backup.yaml
```

### 10.3 多环境证书管理

```yaml
# certificate-staging.yaml - 测试环境
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-tls-staging
  namespace: staging
spec:
  secretName: myapp-tls-staging
  duration: 168h  # 7天（测试环境使用更短的周期）
  renewBefore: 48h
  issuerRef:
    name: venafi-staging-issuer
    kind: ClusterIssuer
  commonName: staging.myapp.example.com
  dnsNames:
    - staging.myapp.example.com
  usages:
    - server auth
  privateKey:
    algorithm: RSA
    size: 2048
```

```yaml
# certificate-production.yaml - 生产环境
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-tls-production
  namespace: production
spec:
  secretName: myapp-tls-production
  duration: 2160h  # 90天
  renewBefore: 720h
  issuerRef:
    name: venafi-production-issuer
    kind: ClusterIssuer
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
    - www.myapp.example.com
  usages:
    - server auth
  privateKey:
    algorithm: RSA
    size: 4096
```
