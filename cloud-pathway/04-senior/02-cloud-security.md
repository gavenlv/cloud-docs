# 云安全

## 本章概述

安全是云计算的核心关注点。本章将深入学习云安全架构、身份认证、数据保护和安全合规。

## 学习目标

- 理解共享责任模型
- 掌握身份与访问管理
- 理解加密技术应用
- 掌握网络安全防护
- 学会安全审计与合规
- 掌握安全最佳实践

---

## 1. 共享责任模型

### 1.1 责任划分

```
共享责任模型

┌─────────────────────────────────────────────────────────────────────────┐
│                          云服务商责任                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     基础设施安全                                  │   │
│  │  ├── 物理安全（数据中心）                                         │   │
│  │  ├── 网络基础设施                                                 │   │
│  │  ├── 虚拟化层                                                     │   │
│  │  └── 硬件维护                                                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│                          客户责任                                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     应用与数据安全                                │   │
│  │  ├── 数据加密                                                     │   │
│  │  ├── 访问控制                                                     │   │
│  │  ├── 网络配置                                                     │   │
│  │  ├── 操作系统补丁                                                 │   │
│  │  └── 应用安全                                                     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘

按服务模型划分：

IaaS:
├── 云商：物理、网络、虚拟化
└── 客户：OS、应用、数据

PaaS:
├── 云商：物理、网络、虚拟化、OS、运行时
└── 客户：应用、数据

SaaS:
├── 云商：全部基础设施和应用
└── 客户：数据、访问控制
```

---

## 2. 身份与访问管理

### 2.1 IAM核心概念

```
IAM核心组件

┌─────────────────────────────────────────────────────────────────────────┐
│                           IAM 架构                                       │
│                                                                         │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐              │
│  │    User     │     │    Group    │     │    Role     │              │
│  │  (用户)     │     │   (组)      │     │   (角色)    │              │
│  └──────┬──────┘     └──────┬──────┘     └──────┬──────┘              │
│         │                   │                   │                      │
│         └───────────────────┼───────────────────┘                      │
│                             │                                          │
│                             ▼                                          │
│                    ┌─────────────────┐                                 │
│                    │     Policy      │                                 │
│                    │    (策略)       │                                 │
│                    └────────┬────────┘                                 │
│                             │                                          │
│                             ▼                                          │
│                    ┌─────────────────┐                                 │
│                    │    Resource     │                                 │
│                    │    (资源)       │                                 │
│                    └─────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 最小权限原则

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/8"
        },
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

### 2.3 角色与临时凭证

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/AppRole
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: app-service-account
      containers:
      - name: app
        image: my-app:latest
```

---

## 3. 加密技术

### 3.1 加密类型

```
加密类型对比

传输加密 (In Transit)
├── TLS/SSL
├── HTTPS
├── VPN
└── SSH

静态加密 (At Rest)
├── 服务器端加密 (SSE)
│   ├── SSE-S3 (S3管理密钥)
│   ├── SSE-KMS (KMS管理密钥)
│   └── SSE-C (客户管理密钥)
└── 客户端加密
    └── 应用层加密

使用中加密 (In Use)
├── 内存加密
└── 可信执行环境 (TEE)
```

### 3.2 密钥管理

```yaml
kms-configuration:
  key-rotation:
    enabled: true
    period: 365d
    
  key-policies:
    - name: admin-access
      principals:
        - arn:aws:iam::123456789012:role/AdminRole
      actions:
        - kms:CreateKey
        - kms:ScheduleKeyDeletion
        
    - name: encrypt-decrypt
      principals:
        - arn:aws:iam::123456789012:role/AppRole
      actions:
        - kms:Encrypt
        - kms:Decrypt
        - kms:GenerateDataKey
        
  alias:
    - alias/app-key
    - alias/database-key
```

### 3.3 数据加密实践

```python
import boto3
from cryptography.fernet import Fernet

kms = boto3.client('kms')

def encrypt_data(plaintext, key_id):
    response = kms.encrypt(
        KeyId=key_id,
        Plaintext=plaintext.encode()
    )
    return response['CiphertextBlob']

def decrypt_data(ciphertext):
    response = kms.decrypt(
        CiphertextBlob=ciphertext
    )
    return response['Plaintext'].decode()

def generate_data_key(key_id):
    response = kms.generate_data_key(
        KeyId=key_id,
        KeySpec='AES_256'
    )
    return {
        'plaintext': response['Plaintext'],
        'encrypted_key': response['CiphertextBlob']
    }
```

---

## 4. 网络安全

### 4.1 网络分层防护

```
网络安全分层

┌─────────────────────────────────────────────────────────────────────────┐
│  Layer 1: 边界防护                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  WAF (Web应用防火墙) + DDoS防护                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 2: 网络隔离                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  VPC + 子网 + 安全组 + NACL                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 3: 传输安全                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  TLS加密 + 私有链接 (PrivateLink)                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│  Layer 4: 应用安全                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  身份认证 + 授权 + 输入验证                                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 安全组配置

```yaml
security-groups:
  web-tier:
    ingress:
      - port: 443
        protocol: TCP
        source: 0.0.0.0/0
        description: HTTPS from internet
      - port: 80
        protocol: TCP
        source: 0.0.0.0/0
        description: HTTP redirect
    egress:
      - port: 0
        protocol: ALL
        destination: 0.0.0.0/0
        
  app-tier:
    ingress:
      - port: 8080
        protocol: TCP
        source: sg-web-tier
        description: From web tier
    egress:
      - port: 443
        protocol: TCP
        destination: 0.0.0.0/0
      - port: 3306
        protocol: TCP
        destination: sg-db-tier
        
  db-tier:
    ingress:
      - port: 3306
        protocol: TCP
        source: sg-app-tier
        description: From app tier
    egress: []
```

### 4.3 WAF规则

```yaml
waf-configuration:
  default-action: ALLOW
  
  rules:
    - name: block-sql-injection
      priority: 1
      statement:
        sqliMatchStatement:
          fieldToMatch:
            queryString: {}
          textTransformations:
            - type: URL_DECODE
            - type: HTML_ENTITY_DECODE
      action:
        block: {}
        
    - name: rate-limit
      priority: 2
      statement:
        rateBasedStatement:
          limit: 1000
          aggregateKeyType: IP
      action:
        block: {}
        
    - name: geo-block
      priority: 3
      statement:
        geoMatchStatement:
          countryCodes:
            - XX
            - YY
      action:
        block: {}
```

---

## 5. 安全审计与合规

### 5.1 审计日志

```yaml
audit-logging:
  cloudtrail:
    enabled: true
    multi-region: true
    global-events: true
    log-file-validation: true
    s3-bucket: audit-logs-bucket
    kms-key: audit-key
    
  cloudwatch-logs:
    retention: 365
    encryption: enabled
    
  vpc-flow-logs:
    enabled: true
    traffic-type: ALL
    destination: cloudwatch-logs
```

### 5.2 合规检查

```python
import boto3

securityhub = boto3.client('securityhub')

def check_compliance():
    findings = securityhub.get_findings(
        Filters={
            'ComplianceStatus': [{'Value': 'FAILED', 'Comparison': 'EQUALS'}],
            'RecordState': [{'Value': 'ACTIVE', 'Comparison': 'EQUALS'}]
        }
    )
    
    for finding in findings['Findings']:
        print(f"Finding: {finding['Title']}")
        print(f"Severity: {finding['Severity']['Label']}")
        print(f"Resource: {finding['Resources'][0]['Id']}")
        print(f"Remediation: {finding.get('Remediation', {}).get('Recommendation', {}).get('Text')}")
```

### 5.3 安全基线

```yaml
security-baseline:
  identity:
    - mfa-required-for-console
    - password-policy-min-length-14
    - no-root-access-keys
    - unused-credentials-90-days
    
  network:
    - no-ssh-from-internet
    - no-rdp-from-internet
    - vpc-flow-logs-enabled
    - default-vpc-unused
    
  encryption:
    - s3-bucket-encryption
    - rds-encryption-at-rest
    - ebs-encryption-default
    - kms-key-rotation
    
  logging:
    - cloudtrail-enabled
    - config-enabled
    - guardduty-enabled
    - securityhub-enabled
```

---

## 6. 安全最佳实践

### 6.1 安全检查清单

```
安全检查清单

身份认证
├── [ ] 启用MFA
├── [ ] 强密码策略
├── [ ] 定期轮换凭证
├── [ ] 使用角色而非用户
└── [ ] 最小权限原则

网络安全
├── [ ] VPC网络隔离
├── [ ] 安全组最小开放
├── [ ] NACL作为补充
├── [ ] WAF防护
└── [ ] DDoS防护

数据安全
├── [ ] 静态数据加密
├── [ ] 传输数据加密
├── [ ] 密钥轮换
├── [ ] 数据分类
└── [ ] 备份加密

监控审计
├── [ ] CloudTrail启用
├── [ ] 日志集中收集
├── [ ] 异常告警
├── [ ] 定期审计
└── [ ] 备份加密
```

### 6.2 加密技术深度原理

**TLS/SSL加密是怎么保护数据传输的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              TLS加密核心机制解析                                   │
└─────────────────────────────────────────────────────────────────┘

TLS 1.3握手流程：

┌─────────────────────────────────────────────────────────────────┐
│  Client → Server: ClientHello                                    │
│  ├── 支持的TLS版本                                             │
│  ├── 支持的加密套件                                             │
│  ├── 随机数 (Client Random)                                    │
│  └── Key Share (用于密钥交换)                                  │
│                                                                  │
│  Server → Client: ServerHello                                    │
│  ├── 选择的TLS版本                                              │
│  ├── 选择的加密套件                                              │
│  ├── 随机数 (Server Random)                                    │
│  ├── Key Share (用于密钥交换)                                  │
│  └── 证书链                                                    │
│                                                                  │
│  Server → Client: (可选) CertificateRequest                      │
│  ├── 请求客户端证书                                             │
│  └── 支持的证书类型                                             │
│                                                                  │
│  Server → Client: ServerHelloDone                               │
│  └── 握手消息结束                                               │
│                                                                  │
│  Client → Server: (可选) Certificate                            │
│  └── 客户端证书                                                 │
│                                                                  │
│  Client → Server: CertificateVerify                              │
│  ├── 使用私钥签名                                               │
│  └── 验证客户端身份                                             │
│                                                                  │
│  Client → Server: Finished                                      │
│  └── 握手完成                                                   │
│                                                                  │
│  双方计算共享密钥：                                               │
│  ├── 使用ECDHE算法                                             │
│  ├── 前向安全 (Perfect Forward Secrecy)                         │
│  └── 生成会话密钥                                              │
└─────────────────────────────────────────────────────────────────┘

对称加密 vs 非对称加密：

┌─────────────────────────────────────────────────────────────────┐
│  对称加密：                                                     │
│  ├── 加密和解密使用同一个密钥                                   │
│  ├── 优点：速度快，适合大量数据                                 │
│  ├── 缺点：密钥分发困难                                       │
│  ├── 常用算法：AES-256, ChaCha20                             │
│  └── 用途：TLS会话加密，磁盘加密                               │
│                                                                  │
│  非对称加密：                                                   │
│  ├── 使用公钥加密，私钥解密                                     │
│  ├── 优点：密钥分发安全                                       │
│  ├── 缺点：速度慢，不适合大量数据                               │
│  ├── 常用算法：RSA, ECC, ECDSA                               │
│  └── 用途：密钥交换，数字签名                                 │
│                                                                  │
│  TLS混合加密：                                                   │
│  ├── 使用非对称加密交换密钥                                     │
│  ├── 使用对称加密传输数据                                       │
│  ├── 结合两者优点                                              │
│  └── 示例：ECDHE + AES-256-GCM                              │
└─────────────────────────────────────────────────────────────────┘

KMS密钥管理：

┌─────────────────────────────────────────────────────────────────┐
│  AWS KMS密钥层次：                                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Customer Master Key (CMK)                             │   │
│  │  ├── 主密钥，由KMS管理                                  │   │
│  │  ├── 永不离开KMS硬件安全模块 (HSM)                      │   │
│  │  ├── 用于加密数据密钥 (DEK)                              │   │
│  │  └── 支持自动轮换                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Data Encryption Key (DEK)                             │   │
│  │  ├── 数据密钥，用于加密实际数据                          │   │
│  │  ├── 由CMK加密后存储                                    │   │
│  │  ├── 可以离开KMS                                       │   │
│  │  └── 每次加密使用新的DEK                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  加密流程：                                             │   │
│  │  1. 调用KMS GenerateDataKey                            │   │
│  │  2. KMS生成DEK，用CMK加密                               │   │
│  │  3. 返回明文DEK和加密DEK                               │   │
│  │  4. 应用使用明文DEK加密数据                              │   │
│  │  5. 删除明文DEK，存储加密DEK                            │   │
│  │  6. 解密时调用KMS Decrypt                              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

IAM策略评估机制：

┌─────────────────────────────────────────────────────────────────┐
│  IAM策略评估流程：                                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  1. 显式拒绝 (Explicit Deny)                            │   │
│  │  ├── 如果任何策略包含Deny                                │   │
│  │  ├── 立即拒绝请求                                        │   │
│  │  └── 不再继续评估                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  2. 边界策略 (Boundary Policies)                        │   │
│  │  ├── SCP (Service Control Policy)                       │   │
│  │  ├── 组织级别的权限边界                                 │   │
│  │  ├── 限制可用的服务和操作                               │   │
│  │  └── 优先于允许策略                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  3. 身份策略 (Identity Policies)                        │   │
│  │  ├── 附加到用户/角色的策略                               │   │
│  │  ├── 基于策略 (Managed Policies)                         │   │
│  │  ├── 内联策略 (Inline Policies)                          │   │
│  │  └── 包含Allow和Deny语句                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  4. 资源策略 (Resource Policies)                        │   │
│  │  ├── 附加到资源的策略                                   │   │
│  │  ├── S3 Bucket Policy                                  │   │
│  │  ├── SQS Queue Policy                                  │   │
│  │  └── SNS Topic Policy                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  5. 会话策略 (Session Policies)                         │   │
│  │  ├── 临时凭证的权限限制                                 │   │
│  │  ├── AssumeRole时传入                                  │   │
│  │  └── 进一步缩小权限范围                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  6. 最终决定                                           │   │
│  │  ├── 如果有任何Allow → 允许                             │   │
│  │  ├── 如果没有Allow → 拒绝                               │   │
│  │  └── 默认拒绝 (Default Deny)                           │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 实操项目

### 项目：构建安全基础设施

```yaml
security-infrastructure:
  identity:
    iam:
      - name: admin-role
        policies:
          - AdministratorAccess
        mfa-required: true
        
      - name: developer-role
        policies:
          - PowerUserAccess
        mfa-required: true
        
      - name: readonly-role
        policies:
          - ViewOnlyAccess
        
  network:
    vpc:
      cidr: 10.0.0.0/16
      subnets:
        public:
          - 10.0.1.0/24
          - 10.0.2.0/24
        private:
          - 10.0.10.0/24
          - 10.0.11.0/24
          
    security-groups:
      bastion:
        ingress:
          - port: 22
            source: corporate-ip
      app:
        ingress:
          - port: 443
            source: alb-sg
            
  encryption:
    kms:
      - alias: app-key
        rotation: enabled
      - alias: database-key
        rotation: enabled
        
  monitoring:
    guardduty: enabled
    securityhub: enabled
    config: enabled
```

---

## 8. 知识检测

### 选择题

1. 在共享责任模型中，PaaS模式下客户负责什么？
   - A. 物理安全
   - B. 网络基础设施
   - C. 应用和数据
   - D. 虚拟化层

2. 哪种加密方式由AWS KMS管理密钥？
   - A. SSE-S3
   - B. SSE-KMS
   - C. SSE-C
   - D. 客户端加密

3. 安全组工作在OSI模型的哪一层？
   - A. 第2层
   - B. 第3层
   - C. 第4层
   - D. 第7层

---

## 9. 扩展阅读

- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

---

## 学习进度

- [ ] 理解共享责任模型
- [ ] 掌握IAM管理
- [ ] 理解加密技术
- [ ] 掌握网络安全
- [ ] 学会安全审计
- [ ] 完成实操项目
