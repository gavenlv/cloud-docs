# 安全配置

## 本章导学

**学完本章后，你将能够：**

- 理解Jenkins安全架构
- 配置用户认证和授权
- 管理凭证和API Token

**学习方法：**

```
安全框架 → 认证配置 → 授权配置 → 凭证管理
```

---

# 1. Jenkins安全框架

## 1.1 安全架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins安全架构                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Jenkins Security                             │
├─────────────────────────────────────────────────────────────────┤
│ 认证 (Authentication)        │ 授权 (Authorization)              │
│ - 谁可以访问                 │ - 可以做什么                      │
│ - 用户数据库                  │ - 矩阵权限                        │
│ - LDAP/SSO                   │ - 项目矩阵权限                    │
│ - API Token                  │ - Role-Based                     │
├──────────────────────────────┴─────────────────────────────────┤
│ 凭证管理 (Credentials)                                          │
│ - 用户名/密码                                                 │
│ - SSH密钥                                                     │
│ - 证书                                                         │
│ - Secret文件                                                  │
└─────────────────────────────────────────────────────────────────┘

# 安全配置路径: Manage Jenkins → Security
```

## 1.2 安全配置界面

```
┌─────────────────────────────────────────────────────────────────┐
│                    安全配置项                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 配置项                        │ 说明                              │
├───────────────────────────────┼─────────────────────────────────┤
│ 安全域 (Security Realm)        │ 用户认证方式                     │
│ 授权策略 (Authorization)       │ 权限控制策略                     │
│ 跨站请求伪造 (CSRF)           │ 防止跨站请求伪造                  │
│ 代理/端口                     │ Agent通信端口                    │
│ 凭证                         │ 凭证管理                         │
│ API Token                    │ API访问令牌                      │
│ 标记格式化器                  │ 显示安全控制                     │
└───────────────────────────────┴─────────────────────────────────┘
```

---

# 2. 认证配置

## 2.1 Jenkins用户数据库

```groovy
// 启用Jenkins用户数据库
// Manage Jenkins → Security → Security Realm
// 选择: Jenkins' own user database

// 注册用户
// Jenkins首页 → Sign Up (首次)
// 或者由管理员创建

// 配置用户注册
// Manage Jenkins → Configure Global Security
// Allow users to sign up: ✓ (开发环境)
// 建议生产环境禁用
```

## 2.2 LDAP认证

```groovy
// LDAP配置
// Manage Jenkins → Security → Security Realm
// 选择: LDAP

// LDAP服务器配置:
Server: ldap://ldap.example.com
Port: 389 (或636 for SSL)
Root DN: dc=example,dc=com

// 用户搜索:
User search base: ou=people
User search filter: (uid={0})

// 组搜索:
Group search base: ou=groups
Group search filter: (member={0})

// 高级配置:
// Display Name LDAP attribute: displayName
// Email LDAP attribute: mail
// Manager DN: cn=admin,dc=example,dc=com
// Manager Password: ********

// 测试连接
// Test LDAP settings
```

## 2.3 SSO集成

```groovy
// SAML 2.0配置 (使用插件)
# 安装: SAML Plugin

# Configure:
# - IdP Metadata URL: https://idp.example.com/metadata
# - Jenkins SP Entity ID: jenkins
# - Display Name Attribute: displayName
# - Email Attribute: email
# - Groups Attribute: groups

// OAuth/GitHub集成
# 安装: GitHub Authentication Plugin

# GitHub OAuth配置:
# - GitHub App: 创建GitHub App
# - Or OAuth:
#   Client ID: ***
#   Client Secret: ***
#   Authorized users: 组织成员
```

---

# 3. 授权配置

## 3.1 授权策略类型

```
┌─────────────────────────────────────────────────────────────────┐
│                    授权策略                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 策略                          │ 说明                              │
├───────────────────────────────┼─────────────────────────────────┤
│ Anyone can do anything        │ 任何人完全控制 (不推荐)          │
│ Legacy mode                   │ 旧版兼容模式                      │
│ Logged-in users can do anything│ 登录用户完全控制                 │
│ Matrix-based security         │ 矩阵权限 (全局)                  │
│ Project-based Matrix Authorization│ 项目矩阵权限                  │
│ Role-Based Access Control     │ 基于角色的权限 (需插件)          │
└───────────────────────────────┴─────────────────────────────────┘
```

## 3.2 矩阵权限配置

```
┌─────────────────────────────────────────────────────────────────┐
│                    矩阵权限配置                                   │
└─────────────────────────────────────────────────────────────────┘

# 全局权限 (Matrix-based security):
# Manage Jenkins → Security → Authorization
# 选择: Matrix-based security

# 权限矩阵:
┌─────────────────────────────────────────────────────────────────┐
│ 权限                    │ Admin │ Developer │ Viewer            │
├─────────────────────────┼───────┼───────────┼──────────────────┤
│ Overall/Administer      │   ✓   │           │                  │
│ Overall/Read           │   ✓   │     ✓     │        ✓         │
│ Overall/Run Scripts     │   ✓   │           │                  │
│ Job/Build              │   ✓   │     ✓     │                  │
│ Job/Configure          │   ✓   │     ✓     │                  │
│ Job/Create             │   ✓   │     ✓     │                  │
│ Job/Delete             │   ✓   │           │                  │
│ Job/Discover           │   ✓   │     ✓     │        ✓         │
│ Job/Move               │   ✓   │           │                  │
│ Job/Read               │   ✓   │     ✓     │        ✓         │
│ Job/Workspace          │   ✓   │     ✓     │                  │
│ Credentials/View       │   ✓   │     ✓     │        ✓         │
│ Credentials/Update     │   ✓   │           │                  │
│ Agent/Build            │   ✓   │     ✓     │                  │
│ Agent/Configure       │   ✓   │           │                  │
│ Agent/Connect         │   ✓   │           │                  │
│ Agent/Create          │   ✓   │           │                  │
│ Agent/Delete         │   ✓   │           │                  │
└─────────────────────────┴───────┴───────────┴──────────────────┘
```

## 3.3 项目矩阵权限

```groovy
// 项目级别权限配置
// 在Job配置中启用: Enable project-based security

// Pipeline中配置
pipeline {
    agent any

    options {
        buildAuthorizationMatrix {
            permissions([
                'hudson.model.Item.Build:jane',
                'hudson.model.Item.Configure:jane',
                'hudson.model.Item.Read:john'
            ])
        }
    }

    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}
```

## 3.4 Role-Based Access Control

```groovy
// 安装: Role-based Authorization Strategy插件

// 配置步骤:
// 1. Manage Jenkins → Security → Authorization
//    选择: Role-Based Access Control

// 2. Manage and Assign Roles
//    - Manage Roles: 定义全局角色和项目角色
//    - Assign Roles: 分配角色给用户

// 定义全局角色:
// Manage Jenkins → Manage and Assign Roles → Manage Roles
// Global roles:
//   - admin: 所有权限
//   - developer: Job相关权限
//   - viewer: 只读权限

// 定义项目角色:
// Project roles:
//   - frontend-*: 前端项目权限
//   - backend-*: 后端项目权限

// 分配角色:
// Manage Jenkins → Manage and Assign Roles → Assign Roles
//   admin  → admin (global)
//   jane   → developer (global) + frontend-* (project)
//   john   → viewer (global) + backend-* (project)
```

---

# 4. 凭证管理

## 4.1 凭证类型

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins凭证类型                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 类型              │ 说明                                        │
├───────────────────┼────────────────────────────────────────────┤
│ Username with password│ 用户名密码                               │
│ SSH Username with private key│ SSH用户名和私钥              │
│ Secret file       │ 加密的secret文件                            │
│ Secret text       │ 加密的文本                                  │
│ Certificate       │ PKCS#12证书文件                             │
│ Docker Host Certificate│ Docker TLS证书                        │
└─────────────────────────────────────────────────────────────────┘

# 凭证存储位置: Manage Jenkins → Security → Credentials
```

## 4.2 创建凭证

```groovy
// 方式1: Web界面创建
// Manage Jenkins → Security → Credentials → System → Add Credentials

// 方式2: Pipeline中使用
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    ),
                    string(
                        credentialsId: 'api-key',
                        variable: 'API_KEY'
                    ),
                    sshUserPrivateKey(
                        credentialsId: 'ssh-key',
                        usernameVariable: 'SSH_USER',
                        privateKeyVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        echo "用户: $DB_USER"
                        db-deploy --user $DB_USER --password $DB_PASS
                    '''
                }
            }
        }
    }
}
```

## 4.3 凭证安全

```groovy
// 凭证掩码
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'secret',
                        variable: 'MY_SECRET'
                    )
                ]) {
                    // 在日志中隐藏secret
                    echo "Secret: ${MY_SECRET}"
                }
            }
        }
    }
}

// 禁用凭证序列化警告
// Manage Jenkins → Configure Global Security
// Enable Credentials wrapping?: ✓

// 安全Realm配置
// 防止跨维度攻击
```

---

# 5. API安全

## 5.1 API Token

```groovy
// 用户API Token配置
// 用户 → Configure → API Token

// 使用API Token访问
curl -u "username:api_token" http://jenkins:8080/api/json

// 或
curl -H "Authorization: $(echo -n username:token | base64)" \
     http://jenkins:8080/api/json
```

## 5.2 CSRF防护

```
┌─────────────────────────────────────────────────────────────────┐
│                    CSRF防护                                      │
└─────────────────────────────────────────────────────────────────┘

# CSRF (Cross-Site Request Forgery) 防护
# 默认启用

# Crumb (Jenkins生成的安全令牌):
# - HEADER: Jenkins-Crumb
# - PARAM: .crumb

# 禁用CSRF (不推荐):
# Manage Jenkins → Configure Global Security
# Prevent Cross Site Request Forgery exploits: ✗

# API调用时包含crumb:
curl -X POST \
     -H "Jenkins-Crumb: ${CRUMB}" \
     -u "user:token" \
     -d "parameter=value" \
     http://jenkins:8080/job/myjob/build
```

## 5.3 API使用示例

```groovy
// 获取crumb
CRUMB=$(curl -s "http://user:token@jenkins:8080/crumbIssuer/api/json" | jq -r .crumbRequestField":"crumb)

// 创建构建
curl -X POST \
     -H "${CRUMB}" \
     -u "user:token" \
     http://jenkins:8080/job/myjob/build

// 获取构建状态
curl -u "user:token" \
     "http://jenkins:8080/job/myjob/lastBuild/api/json"

// 获取控制台输出
curl -u "user:token" \
     "http://jenkins:8080/job/myjob/lastBuild/consoleText"

// 触发参数化构建
curl -X POST \
     -H "${CRUMB}" \
     -u "user:token" \
     -d "param1=value1&param2=value2" \
     http://jenkins:8080/job/myjob/buildWithParameters
```

---

# 6. 端口和协议安全

## 6.1 Agent通信端口

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent端口安全                                 │
└─────────────────────────────────────────────────────────────────┘

# 默认端口: 50000

# 配置:
# Manage Jenkins → Configure Global Security
# Agents → TCP port for inbound agents
#   - Random: 随机端口
#   - Fixed: 固定端口
#   - Disable: 禁用

# 防火墙配置:
# 确保Agent能连接到Master的agent端口
```

## 6.2 协议配置

```
┌─────────────────────────────────────────────────────────────────┐
│                    协议配置                                      │
└─────────────────────────────────────────────────────────────────┘

# 启用/禁用协议:
# Manage Jenkins → Configure Global Security

# 可用协议:
# - JNLP-connect: Java Web Start
# - JNLP4-connect: JNLP4 (推荐)
# - CLI over Remoting
# - Swarm

# 建议:
# - 禁用旧协议 (JNLP-connect, CLI over Remoting)
# - 启用 JNLP4-connect
```

---

## 本章小结

- **认证**确定用户身份，常见方式包括Jenkins用户数据库、LDAP、OAuth
- **授权**控制用户权限，矩阵权限和RBAC是常用策略
- **凭证**安全存储敏感信息，支持多种类型
- **API Token**用于编程访问Jenkins
- **CSRF防护**防止跨站请求伪造

**安全配置要点:**

```bash
# 关键安全配置:
# 1. 启用CSRF防护
# 2. 使用LDAP/SSO统一认证
# 3. 配置最小权限原则
# 4. 安全存储凭证
# 5. 禁用旧版协议
# 6. 定期轮换API Token
```