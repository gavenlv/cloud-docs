# GCP 认证原理详解

## 概述

理解 GCP 认证机制是使用 Terraform、kubectl、gcloud 等工具的基础。本文档深入讲解 GCP 认证的底层原理。

---

## 1. GCP 认证体系架构

### 1.1 整体架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GCP 认证完整架构                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                          Google OAuth 2.0 Server                         │
│                                  │                                       │
│                    ┌─────────────┴─────────────┐                        │
│                    │                           │                        │
│                    ▼                           ▼                        │
│  ┌─────────────────────────┐    ┌─────────────────────────┐           │
│  │   gcloud auth login     │    │   ADC login             │           │
│  │                         │    │                         │           │
│  │   用户账号凭据           │    │   应用默认凭据           │           │
│  │   (User Credentials)    │    │   (ADC)                 │           │
│  └───────────┬─────────────┘    └───────────┬─────────────┘           │
│              │                              │                          │
│              ▼                              ▼                          │
│  ┌─────────────────────────┐    ┌─────────────────────────┐           │
│  │  credentials.db         │    │  application_default_   │           │
│  │  (SQLite)               │    │  credentials.json       │           │
│  │                         │    │                         │           │
│  │  仅 gcloud CLI 可读     │    │  所有 SDK 可读          │           │
│  └───────────┬─────────────┘    └───────────┬─────────────┘           │
│              │                              │                          │
│              ▼                              ▼                          │
│  ┌─────────────────────────┐    ┌─────────────────────────┐           │
│  │  gcloud 命令            │    │  Terraform              │           │
│  │  - gcloud compute       │    │  Python SDK             │           │
│  │  - gcloud container     │    │  Java SDK               │           │
│  │  - gcloud sql           │    │  Go SDK                 │           │
│  └─────────────────────────┘    │  kubectl (via plugin)   │           │
│                                 └─────────────────────────┘           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 两种认证的区别

| 认证方式 | 命令 | 存储位置 | 使用者 | 场景 |
|----------|------|----------|--------|------|
| 用户凭据 | `gcloud auth login` | `credentials.db` | gcloud CLI | 命令行操作 |
| 应用默认凭据 | `gcloud auth application-default login` | `application_default_credentials.json` | 所有 SDK | 应用程序 |

---

## 2. gcloud auth login 原理

### 2.1 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│              gcloud auth login 工作流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. 执行命令                                                     │
│     $ gcloud auth login                                         │
│                                                                  │
│  2. 打开浏览器                                                   │
│     ┌─────────────────────────────────────────┐                │
│     │  Google OAuth 2.0 授权页面              │                │
│     │                                         │                │
│     │  选择你的 Google 账号                   │                │
│     │  授权 gcloud 访问你的账号               │                │
│     └─────────────────────────────────────────┘                │
│                                                                  │
│  3. 获取授权码                                                   │
│     浏览器重定向到 http://localhost:8085/?code=xxx              │
│     gcloud 捕获授权码                                            │
│                                                                  │
│  4. 交换令牌                                                     │
│     授权码 ──> Access Token + Refresh Token                     │
│                                                                  │
│  5. 存储凭据                                                     │
│     ~/.config/gcloud/credentials.db (SQLite 数据库)             │
│                                                                  │
│  6. 后续请求                                                     │
│     gcloud 命令 ──> 读取 credentials.db ──> 使用 Refresh Token  │
│     获取新的 Access Token ──> 调用 GCP API                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 OAuth 2.0 流程详解

```
┌─────────────────────────────────────────────────────────────────┐
│                    OAuth 2.0 授权码流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  用户                gcloud              Google OAuth            │
│   │                    │                      │                  │
│   │  1. gcloud auth login                    │                  │
│   │ ──────────────────>│                      │                  │
│   │                    │                      │                  │
│   │                    │  2. 打开浏览器       │                  │
│   │ <──────────────────│                      │                  │
│   │                    │                      │                  │
│   │  3. 用户登录并授权                       │                  │
│   │ ──────────────────────────────────────────>                  │
│   │                    │                      │                  │
│   │  4. 重定向到 localhost?code=AUTH_CODE   │                  │
│   │ <─────────────────────────────────────────                  │
│   │                    │                      │                  │
│   │                    │  5. 捕获授权码       │                  │
│   │                    │ <────────────────────│                  │
│   │                    │                      │                  │
│   │                    │  6. 用授权码换令牌   │                  │
│   │                    │ ────────────────────>│                  │
│   │                    │                      │                  │
│   │                    │  7. 返回令牌         │                  │
│   │                    │ <────────────────────│                  │
│   │                    │  (Access Token +     │                  │
│   │                    │   Refresh Token)     │                  │
│   │                    │                      │                  │
│   │  8. 认证成功       │                      │                  │
│   │ <──────────────────│                      │                  │
│   │                    │                      │                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 令牌类型

```
┌─────────────────────────────────────────────────────────────────┐
│                        令牌类型说明                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Access Token（访问令牌）                                        │
│  ─────────────────────                                          │
│  ├── 用途：访问 GCP API                                         │
│  ├── 有效期：通常 1 小时                                        │
│  ├── 格式：ya29.a0AfH6SMBx...                                   │
│  └── 放在 HTTP Header：Authorization: Bearer ya29.xxx           │
│                                                                  │
│  Refresh Token（刷新令牌）                                       │
│  ─────────────────────                                          │
│  ├── 用途：获取新的 Access Token                                │
│  ├── 有效期：长期有效（直到用户撤销）                            │
│  ├── 格式：1//0g...很长的token...                               │
│  └── 存储在本地，不通过网络传输                                 │
│                                                                  │
│  令牌刷新流程：                                                  │
│  ─────────────                                                  │
│  Access Token 过期                                               │
│       │                                                          │
│       ▼                                                          │
│  gcloud 使用 Refresh Token                                      │
│       │                                                          │
│       ▼                                                          │
│  向 Google OAuth 服务器请求新 Access Token                      │
│       │                                                          │
│       ▼                                                          │
│  获取新的 Access Token（无需用户再次登录）                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 存储位置

```
凭据存储位置：

Windows:
  %APPDATA%\gcloud\credentials.db
  %APPDATA%\gcloud\access_tokens.db

Linux/macOS:
  ~/.config/gcloud/credentials.db
  ~/.config/gcloud/access_tokens.db

文件格式：
  SQLite 数据库，包含加密的令牌信息
```

---

## 3. Application Default Credentials (ADC) 原理

### 3.1 什么是 ADC

```
┌─────────────────────────────────────────────────────────────────┐
│              Application Default Credentials (ADC)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  定义：                                                          │
│  ADC 是 Google 提供的一种标准化凭据查找机制，                    │
│  允许应用程序自动获取认证凭据，无需硬编码。                       │
│                                                                  │
│  设计目标：                                                      │
│  ├── 应用程序无需关心凭据来源                                    │
│  ├── 同一份代码可在不同环境运行                                  │
│  ├── 自动适配本地、GKE、Cloud Run、Compute Engine 等环境         │
│  └── 简化认证配置                                                │
│                                                                  │
│  支持的语言/工具：                                               │
│  ├── Terraform                                                   │
│  ├── Python (google-cloud-python)                               │
│  ├── Go (google-cloud-go)                                       │
│  ├── Java (google-cloud-java)                                   │
│  ├── Node.js (google-cloud-nodejs)                              │
│  └── kubectl (通过 gke-gcloud-auth-plugin)                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 ADC 查找顺序（核心原理）

```
┌─────────────────────────────────────────────────────────────────┐
│                    ADC 凭据查找顺序                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  优先级从高到低：                                                │
│                                                                  │
│  1. 环境变量 GOOGLE_APPLICATION_CREDENTIALS                     │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  export GOOGLE_APPLICATION_CREDENTIALS="/path/key.json" │
│     │                                                     │    │
│     │  如果设置，直接使用指定的 JSON 密钥文件              │    │
│     │  适用于：CI/CD、服务账号认证                        │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
│  2. 环境变量 GOOGLE_CREDENTIALS                                 │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  export GOOGLE_CREDENTIALS='{"type":"service_account"...}' │
│     │                                                     │    │
│     │  直接包含 JSON 内容（Terraform 常用）               │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
│  3. 应用默认凭据文件                                            │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  Windows: %APPDATA%\gcloud\application_default_credentials.json │
│     │  Linux/macOS: ~/.config/gcloud/application_default_credentials.json │
│     │                                                     │    │
│     │  由 gcloud auth application-default login 生成      │    │
│     │  适用于：本地开发                                   │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
│  4. GKE / Cloud Run / Cloud Functions                           │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  自动使用工作负载身份                   │    │
│     │  或默认服务账号                                     │    │
│     │                                                     │    │
│     │  无需任何配置，自动获取凭据                         │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
│  5. Compute Engine / App Engine                                 │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  自动使用实例服务账号                               │    │
│     │  通过元数据服务获取令牌                             │    │
│     │                                                     │    │
│     │  无需任何配置，自动获取凭据                         │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
│  6. 未找到凭据                                                   │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  报错：google: could not find default credentials   │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 ADC 文件内容

```json
{
  "client_id": "764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com",
  "client_secret": "d-FL95Q19q7MQmFpd7hHD0Ty",
  "refresh_token": "1//0g...很长的token...",
  "type": "authorized_user"
}
```

**关键字段说明：**

| 字段 | 说明 |
|------|------|
| `client_id` | Google 预定义的客户端 ID |
| `client_secret` | 对应的客户端密钥 |
| `refresh_token` | 用于获取 Access Token |
| `type` | 凭据类型，`authorized_user` 表示用户账号 |

### 3.4 为什么需要两个登录？

```
┌─────────────────────────────────────────────────────────────────┐
│                为什么需要 gcloud auth login 和 ADC？              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  设计原因：                                                      │
│                                                                  │
│  1. 安全隔离                                                     │
│     ├── gcloud CLI 和应用程序使用不同的凭据存储                  │
│     ├── 可以给 CLI 和应用设置不同的权限                          │
│     └── 降低凭据泄露风险                                        │
│                                                                  │
│  2. 标准化                                                       │
│     ├── ADC 是 Google 定义的行业标准                            │
│     ├── 所有 Google 客户端库都支持                              │
│     └── 开发者无需学习不同的认证 API                            │
│                                                                  │
│  3. 环境适配                                                     │
│     ├── 同一份代码可在本地、云端运行                            │
│     ├── ADC 自动检测运行环境                                    │
│     └── 无需修改代码即可切换环境                                │
│                                                                  │
│  实际使用：                                                      │
│                                                                  │
│  场景 1：本地开发                                                │
│  ├── gcloud auth login（用于 gcloud 命令）                      │
│  └── gcloud auth application-default login（用于 Terraform）    │
│                                                                  │
│  场景 2：CI/CD                                                   │
│  ├── 不需要 gcloud auth login                                   │
│  └── 设置 GOOGLE_APPLICATION_CREDENTIALS 环境变量               │
│                                                                  │
│  场景 3：GKE/Cloud Run                                           │
│  ├── 不需要任何登录                                             │
│  └── 自动使用服务账号                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. 服务账号 vs 用户账号

### 4.1 对比

```
┌─────────────────────────────────────────────────────────────────┐
│                    两种账号类型对比                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  用户账号                                      │
│  ─────────────────────────────                                 │
│  ├── 代表：一个真实的人                                          │
│  ├── 认证方式：OAuth 2.0（浏览器登录）                          │
│  ├── 凭据存储：本地文件                                         │
│  ├── 适合：开发、调试、临时操作                                 │
│  ├── 不适合：生产环境、CI/CD                                    │
│  └── 示例：user@gmail.com                                       │
│                                                                  │
│  服务账号                                   │
│  ─────────────────────────────                                 │
│  ├── 代表：一个应用程序/服务                                     │
│  ├── 认证方式：JSON 密钥文件 / Workload Identity                │
│  ├── 凭据存储：可分发到服务器                                   │
│  ├── 适合：生产环境、CI/CD、自动化                              │
│  ├── 最佳实践：定期轮换密钥                                     │
│  └── 示例：terraform@project-id.iam.gserviceaccount.com         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 服务账号密钥文件格式

```json
{
  "type": "service_account",
  "project_id": "my-project-id",
  "private_key_id": "abcd1234...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "terraform@my-project-id.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/terraform%40my-project-id.iam.gserviceaccount.com"
}
```

**关键字段说明：**

| 字段 | 说明 |
|------|------|
| `type` | 固定为 `service_account` |
| `project_id` | GCP 项目 ID |
| `private_key` | RSA 私钥，用于签名 JWT |
| `client_email` | 服务账号邮箱 |
| `token_uri` | 获取 Access Token 的端点 |

---

## 5. 认证流程总结

### 5.1 本地开发流程

```bash
# 1. 用户账号登录（用于 gcloud 命令）
gcloud auth login

# 2. ADC 登录（用于 Terraform、SDK）
gcloud auth application-default login

# 3. 设置默认项目
gcloud config set project PROJECT_ID

# 4. 验证认证状态
gcloud auth list
gcloud auth application-default print-access-token
```

### 5.2 CI/CD 流程

```bash
# 方式 1：使用服务账号密钥
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# 方式 2：使用 Workload Identity（推荐）
# 无需密钥文件，通过 OIDC 自动获取令牌
```

### 5.3 云端运行流程

```
GKE / Cloud Run / Cloud Functions / Compute Engine

无需任何配置，ADC 自动：
1. 检测运行环境
2. 从元数据服务获取服务账号
3. 自动获取 Access Token
4. 调用 GCP API
```

---

## 6. 常见问题

### 6.1 为什么 Terraform 报错 "could not find default credentials"？

**原因：** 未执行 `gcloud auth application-default login`

**解决：**

```bash
gcloud auth application-default login
```

### 6.2 为什么 gcloud 命令正常，但 Terraform 报错？

**原因：** `gcloud auth login` 和 ADC 是两个独立的认证系统

**解决：** 需要同时执行两个登录：

```bash
gcloud auth login                    # gcloud CLI
gcloud auth application-default login  # Terraform
```

### 6.3 如何查看当前使用的凭据？

```bash
# 查看 gcloud 认证账号
gcloud auth list

# 查看 ADC 状态
gcloud auth application-default print-access-token

# 查看配置
gcloud config list
```

### 6.4 如何切换账号？

```bash
# 切换 gcloud 账号
gcloud config set account ACCOUNT_EMAIL

# 重新登录 ADC
gcloud auth application-default login
```

---

## 参考链接

- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
- [OAuth 2.0 for Client-side Web Applications](https://developers.google.com/identity/protocols/oauth2)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
