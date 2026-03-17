# DevSecOps实践

## 本章概述

DevSecOps是将安全融入DevOps的实践。本章将学习安全左移、自动化安全检测和合规管理。

## 学习目标

- 理解DevSecOps核心理念
- 掌握安全代码审查
- 学会依赖漏洞扫描
- 掌握容器镜像安全
- 学会IaC安全扫描
- 理解合规自动化

---

## 1. DevSecOps概述

### 1.1 DevSecOps理念

```
DevSecOps演进

传统开发                          DevOps                           DevSecOps
┌─────────────┐              ┌─────────────┐              ┌─────────────┐
│   开发      │              │   开发      │              │   开发      │
│     ↓       │              │     ↓       │              │     ↓       │
│   测试      │              │   测试      │              │   测试      │
│     ↓       │              │     ↓       │              │     ↓       │
│   安全      │◄──后期介入   │   部署      │              │   安全      │◄──内嵌
│     ↓       │              │     ↓       │              │     ↓       │
│   运维      │              │   运维      │              │   部署      │
└─────────────┘              └─────────────┘              └─────────────┘

核心理念：
├── 安全左移 (Shift Left)
├── 安全即代码 (Security as Code)
├── 安全自动化
├── 人人负责安全
└── 持续安全
```

### 1.2 安全左移

```
安全左移实践

需求阶段
├── 威胁建模
├── 安全需求分析
└── 隐私影响评估

设计阶段
├── 安全架构评审
├── 数据流分析
└── 攻击面分析

开发阶段
├── 安全编码规范
├── 代码安全扫描
├── 依赖漏洞检查
└── 静态分析 (SAST)

测试阶段
├── 动态分析 (DAST)
├── 渗透测试
├── 安全回归测试
└── 模糊测试

部署阶段
├── 镜像安全扫描
├── 配置安全检查
├── 密钥管理
└── 安全基线验证

运维阶段
├── 运行时保护
├── 安全监控
├── 漏洞管理
└── 应急响应
```

---

## 2. 安全代码审查

### 2.1 SAST工具集成

```yaml
github-actions-sast:

name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Semgrep
      uses: returntocorp/semgrep-action@v1
      with:
        config: >-
          p/security-audit
          p/secrets
          p/owasp-top-ten
        
    - name: Run CodeQL
      uses: github/codeql-action/analyze@v2
      with:
        languages: javascript, python
        
    - name: Run SonarCloud
      uses: sonarsource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### 2.2 安全编码规范

```python
def process_user_input(user_input: str) -> dict:
    """
    安全处理用户输入
    """
    if not user_input:
        raise ValueError("Input cannot be empty")
    
    sanitized_input = sanitize_input(user_input)
    
    if not validate_input(sanitized_input):
        raise ValueError("Invalid input format")
    
    return {"data": sanitized_input}


def sanitize_input(input_str: str) -> str:
    """
    清理输入，防止XSS和注入攻击
    """
    import html
    import re
    
    sanitized = html.escape(input_str)
    sanitized = re.sub(r'[<>"\']', '', sanitized)
    
    return sanitized.strip()


def execute_safe_query(user_id: str, db_connection):
    """
    安全执行数据库查询，防止SQL注入
    """
    query = "SELECT * FROM users WHERE id = %s"
    cursor = db_connection.cursor()
    cursor.execute(query, (user_id,))
    return cursor.fetchall()
```

---

## 3. 依赖漏洞扫描

### 3.1 依赖扫描配置

```yaml
dependency-scan:
  tools:
    - name: Snyk
      config:
        severity-threshold: high
        fail-on: true
        
    - name: Dependabot
      config:
        update-schedule: daily
        open-pull-requests-limit: 10
        
    - name: OWASP Dependency-Check
      config:
        suppression-file: dependency-check-suppressions.xml
        fail-on-cvss: 7
        
  scan-config:
    scan-node-modules: true
    scan-python-packages: true
    scan-java-dependencies: true
```

### 3.2 CI/CD集成

```yaml
dependency-security-pipeline:

name: Dependency Security Scan

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 0 * * *'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high
        
    - name: Run npm audit
      run: npm audit --audit-level=high
      
    - name: Run pip-audit
      run: |
        pip install pip-audit
        pip-audit --desc-only --ignore-vuln PYSEC-2023-123
```

---

## 4. 容器镜像安全

### 4.1 镜像安全扫描

```yaml
container-security-pipeline:

name: Container Security

on:
  push:
    paths:
    - 'Dockerfile'
    - 'docker/**'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build image
      run: docker build -t myapp:${{ github.sha }} .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'myapp:${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
        
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
    - name: Run Grype scanner
      uses: anchore/scan-action@v3
      with:
        image: 'myapp:${{ github.sha }}'
        fail-build: true
        severity-cutoff: high
```

### 4.2 安全Dockerfile

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs18-debian11

WORKDIR /app

COPY --from=builder --chown=nonroot:nonroot /app/dist ./dist
COPY --from=builder --chown=nonroot:nonroot /app/node_modules ./node_modules

USER nonroot

EXPOSE 3000

CMD ["dist/main.js"]
```

---

## 5. IaC安全扫描

### 5.1 Terraform安全扫描

```yaml
iac-security-pipeline:

name: IaC Security Scan

on:
  push:
    paths:
    - '**.tf'
    - '**.tfvars'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: ./terraform
        framework: terraform
        soft_fail: false
        output_format: sarif
        output_file_path: results.sarif
        
    - name: Run tfsec
      uses: aquasecurity/tfsec-action@v1.0.0
      with:
        soft_fail: false
        
    - name: Run Terrascan
      uses: tenable/terrascan-action@main
      with:
        iac_type: terraform
        iac_dir: ./terraform
```

### 5.2 安全Terraform配置

```hcl
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket"
  
  tags = {
    Environment = "production"
    Security    = "high"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bucket_key.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "enforce_ssl" {
  bucket = aws_s3_bucket.secure_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

---

## 6. 合规自动化

### 6.1 策略即代码

```yaml
opa-policies:

package security

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Containers must run as non-root user"
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container %v is privileged", [container.name])
}

deny[msg] {
    input.kind == "Service"
    input.spec.type == "NodePort"
    msg := "NodePort services are not allowed"
}

warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %v has no memory limit", [container.name])
}
```

### 6.2 合规检查流水线

```yaml
compliance-pipeline:

name: Compliance Check

on:
  push:
  schedule:
    - cron: '0 6 * * 1'

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Prowler (AWS Security)
      run: |
        pip install prowler
        prowler aws --severity critical high
        
    - name: Run ScoutSuite
      run: |
        pip install scoutsuite
        scout aws
        
    - name: Run Open Policy Agent
      run: |
        opa test ./policies -v
        
    - name: Generate Compliance Report
      run: |
        python scripts/generate_compliance_report.py
```

---

## 7. 实操项目

### 项目：构建DevSecOps流水线

```yaml
devsecops-pipeline:

name: DevSecOps Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: SAST - Semgrep
      uses: returntocorp/semgrep-action@v1
      
    - name: SAST - CodeQL
      uses: github/codeql-action/analyze@v2
      
    - name: Dependency Scan
      uses: snyk/actions/node@master
      
  container-scan:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Container
      run: docker build -t app:${{ github.sha }} .
      
    - name: Container Scan - Trivy
      uses: aquasecurity/trivy-action@master
      
    - name: Container Scan - Grype
      uses: anchore/scan-action@v3
      
  iac-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: IaC Scan - Checkov
      uses: bridgecrewio/checkov-action@master
      
    - name: IaC Scan - tfsec
      uses: aquasecurity/tfsec-action@v1.0.0
      
  deploy:
    needs: [security-scan, container-scan, iac-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to Production
      run: |
        kubectl apply -f k8s/
```

---

## 8. 知识检测

### 选择题

1. DevSecOps的核心理念是什么？
   - A. 安全后期介入
   - B. 安全左移
   - C. 安全外包
   - D. 安全可选

2. SAST代表什么？
   - A. 动态应用安全测试
   - B. 静态应用安全测试
   - C. 软件安全测试
   - D. 系统安全测试

3. 哪个工具用于容器镜像安全扫描？
   - A. Semgrep
   - B. Checkov
   - C. Trivy
   - D. SonarQube

---

## 9. 扩展阅读

- [OWASP DevSecOps](https://owasp.org/www-project-devsecops/)
- [NIST Secure Software Development](https://csrc.nist.gov/publications/detail/sp/800-218/final)
- [DevSecOps Manifesto](https://www.devsecops.org/)

---

## 学习进度

- [ ] 理解DevSecOps理念
- [ ] 掌握安全代码审查
- [ ] 学会依赖漏洞扫描
- [ ] 掌握容器镜像安全
- [ ] 学会IaC安全扫描
- [ ] 理解合规自动化
- [ ] 完成实操项目
