# 最佳实践

## 本章导学

**学完本章后，你将能够：**

- 掌握Pipeline设计和编写最佳实践
- 理解代码质量和安全最佳实践
- 掌握性能优化和团队协作最佳实践

**学习方法：**

```
Pipeline设计 → 代码质量 → 安全 → 性能 → 团队协作
```

---

# 1. Pipeline设计最佳实践

## 1.1 Pipeline结构

```groovy
// 推荐的Pipeline结构
pipeline {
    // 1. 代理配置
    agent {
        label 'linux'
    }

    // 2. 环境变量
    environment {
        APP_NAME = 'myapp'
        REGISTRY = 'myregistry.io'
    }

    // 3. 选项配置
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    // 4. 参数配置
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: '分支')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: '环境')
    }

    // 5. 阶段定义
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'make build'
            }
        }

        stage('Test') {
            steps {
                sh 'make test'
            }
        }

        stage('Deploy') {
            steps {
                sh 'make deploy ENV=${params.ENV}'
            }
        }
    }

    // 6. 后置处理
    post {
        always {
            cleanWs()
        }
        success {
            notifySuccess()
        }
        failure {
            notifyFailure()
        }
    }
}
```

## 1.2 代码复用

```groovy
// 使用共享库提高复用性

// vars/buildApp.groovy
def call(String appName, String version = 'latest') {
    sh "mvn clean package -Dapp.name=${appName} -Dapp.version=${version}"
}

// vars/deployApp.groovy
def call(String environment) {
    sh "./deploy.sh -e ${environment}"
}

// Pipeline中使用
@Library('my-shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                buildApp 'myapp', '1.0.0'
            }
        }
        stage('Deploy') {
            steps {
                deployApp 'production'
            }
        }
    }
}
```

## 1.3 错误处理

```groovy
// 建议的错误处理方式

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    try {
                        sh 'mvn clean package'
                    } catch (Exception e) {
                        echo "构建失败: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
    }
}

// 重试机制
stage('Deploy') {
    steps {
        retry(3) {
            sh './deploy.sh'
        }
    }
}

// 超时设置
stage('Long Running') {
    steps {
        timeout(time: 30, unit: 'MINUTES') {
            sh './long-task.sh'
        }
    }
}
```

---

# 2. 代码质量

## 2.1 静态代码分析

```groovy
// SonarQube集成
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQubeScanner'
                    withSonarQubeEnv('sonar') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                waitForQualityGate abortPipeline: true
            }
        }
    }
}
```

## 2.2 测试最佳实践

```groovy
// 单元测试
stage('Unit Tests') {
    steps {
        sh 'mvn test'
    }
    post {
        always {
            junit '**/target/surefire-reports/*.xml'
        }
    }
}

// 集成测试
stage('Integration Tests') {
    steps {
        sh 'mvn verify -Pintegration-tests'
    }
    post {
        always {
            junit '**/target/failsafe-reports/*.xml'
        }
    }
}

// 性能测试
stage('Performance Tests') {
    steps {
        sh 'mvn gatling:execute'
    }
}

// 安全测试
stage('Security Scan') {
    steps {
        sh 'mvn dependency-check:check'
    }
}
```

## 2.3 代码覆盖率

```groovy
// JaCoCo代码覆盖率
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'mvn test jacoco:report'
            }
        }

        stage('Coverage Report') {
            steps {
                publishHTML([
                    reportDir: 'target/site/jacoco',
                    reportFiles: 'index.html',
                    reportName: 'JaCoCo Coverage'
                ])
            }
        }
    }
}
```

---

# 3. 安全最佳实践

## 3.1 凭证管理

```groovy
// 安全使用凭证

// 1. 使用credentialsId而非明文
steps {
    withCredentials([
        usernamePassword(
            credentialsId: 'db-credentials',
            usernameVariable: 'DB_USER',
            passwordVariable: 'DB_PASS'
        )
    ]) {
        sh './deploy.sh'
    }
}

// 2. 不要在日志中输出敏感信息
// 错误示例
echo "密码: ${DB_PASS}"  // 不要这样做

// 3. 最小权限原则
// 只授予完成任务所需的最小权限

// 4. 定期轮换凭证
```

## 3.2 Pipeline安全

```groovy
// 沙箱安全
pipeline {
    agent any
    options {
        // 禁用脚本安全 (谨慎使用)
        // sandbox: false
    }

    stages {
        stage('Build') {
            steps {
                // 使用批准的方法
            }
        }
    }
}

// 防止信息泄露
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    // 不要在steps中直接打印环境变量
                    def secretValue = env.MY_SECRET
                    echo "Secret length: ${secretValue.length()}"
                }
            }
        }
    }
}
```

## 3.3 基础设施安全

```bash
# 1. 使用加密的配置文件
# 加密Jenkins配置
# Manage Jenkins → Configure Global Security
# Enable security: ✓

# 2. 网络隔离
# - Jenkins Master不暴露公网
# - Agent在专用网络
# - 使用VPN访问

# 3. 定期更新
# - 更新Jenkins核心
# - 更新插件
# - 更新Java版本
```

---

# 4. 性能优化

## 4.1 构建加速

```groovy
// 1. 并行执行
stage('Test') {
    parallel {
        stage('Unit Test') {
            steps {
                sh 'mvn test -Dtest=*Test'
            }
        }
        stage('Integration Test') {
            steps {
                sh 'mvn verify -Pintegration-tests'
            }
        }
    }
}

// 2. 使用缓存
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }
    }
}

// 3. 增量构建
stage('Build') {
    steps {
        sh 'mvn package -pl module1,module2 -am'
    }
}
```

## 4.2 Agent优化

```groovy
// 1. 使用合适的Agent
pipeline {
    agent {
        label 'docker'  // 使用有Docker的节点
    }
}

// 2. 限制并发
options {
    disableConcurrentBuilds()
}

// 3. 及时清理
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
}

post {
    always {
        cleanWs()
    }
}
```

## 4.3 分布式构建

```groovy
// 使用更多Agent分散负载
// Manage Jenkins → Manage Nodes → Configure
// # of executors: 4

// 为不同任务配置专门Agent
pipeline {
    agent {
        label 'java'  // Java构建使用专用节点
    }
}

// Kubernetes动态Agent
pipeline {
    agent {
        kubernetes {
            label 'dynamic'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
  - name: builder
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
'''
        }
    }
}
```

---

# 5. 团队协作

## 5.1 代码审查

```groovy
// Pipeline代码审查

// 1. Jenkinsfile纳入版本控制
// 2. 设置代码审查流程
// 3. 限制直接推送main分支

// GitLab合并请求流程
// 1. Fork仓库
// 2. 创建分支
// 3. 提交Pipeline更改
// 4. 创建Merge Request
// 5. 审查通过后合并
```

## 5.2 文档化

```groovy
// Pipeline注释
/*
 * 这个Pipeline用于构建和部署微服务
 * 流程: Build -> Test -> Deploy to Dev -> Deploy to Prod
 * 作者: DevOps Team
 * 维护者: jenkins-admin@example.com
 */
pipeline {
    // ...
}

// 使用description
stage('Build') {
    steps {
        echo '构建阶段: 编译Java代码'
    }
}
```

## 5.3 监控和告警

```groovy
// 构建状态监控
post {
    always {
        emailext(
            subject: "${currentBuild.result ?: 'SUCCESS'}: ${env.JOB_NAME}",
            body: "构建 #${env.BUILD_NUMBER}",
            to: 'team@example.com'
        )
    }
}

// Slack通知
post {
    success {
        slackSend channel: '#ci-cd',
                  color: 'good',
                  message: "构建成功: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
}

// Prometheus监控
// 安装: Prometheus metrics plugin
// 端点: /prometheus/
```

## 5.4 备份策略

```bash
# Jenkins数据备份

# 1. 备份内容
# - JENKINS_HOME (配置、构建历史)
# - 插件
# - 用户数据

# 2. 备份脚本
#!/bin/bash
BACKUP_DIR=/backup/jenkins
JENKINS_HOME=/var/jenkins_home

tar -czf ${BACKUP_DIR}/jenkins-$(date +%Y%m%d).tar.gz \
    ${JENKINS_HOME}

# 3. 恢复
# tar -xzf jenkins-backup.tar.gz -C /var/jenkins_home
```

---

## 本章小结

- **Pipeline设计**: 结构清晰、代码复用、错误处理
- **代码质量**: 静态分析、测试覆盖、安全扫描
- **安全**: 凭证管理、Pipeline安全、基础设施安全
- **性能**: 并行构建、缓存、分布式构建
- **团队协作**: 代码审查、文档化、监控告警

**最佳实践清单:**

```bash
# Pipeline
✓ 使用声明式Pipeline
✓ 代码版本控制
✓ 错误处理和重试
✓ 及时清理

# 安全
✓ 使用credentialsId
✓ 最小权限原则
✓ 定期更新

# 性能
✓ 并行执行
✓ 使用缓存
✓ 分布式构建

# 协作
✓ 代码审查
✓ 文档化
✓ 监控告警
```