# Pipeline高级特性

## 本章导学

**学完本章后，你将能够：**

- 掌握Scripted Pipeline和共享库
- 理解并行执行和矩阵构建
- 掌握高级语法和技巧

**学习方法：**

```
Scripted Pipeline → 共享库 → 并行执行 → 高级技巧
```

---

# 1. Scripted Pipeline

## 1.1 基本语法

```groovy
// Scripted Pipeline vs Declarative Pipeline
// Scripted更灵活，基于Groovy脚本

node('docker') {
    // stage等价于Declarative的stages
    stage('Checkout') {
        echo "检出代码"
        git branch: 'main',
            url: 'https://github.com/example/app.git'
    }

    stage('Build') {
        echo "构建应用"
        sh 'mvn clean package'
    }

    stage('Test') {
        echo "运行测试"
        sh 'mvn test'
    }

    stage('Deploy') {
        echo "部署应用"
        sh './deploy.sh'
    }
}
```

## 1.2 条件语句

```groovy
// if-else条件
node {
    stage('Build') {
        if (env.BRANCH_NAME == 'main') {
            echo "主分支构建"
            sh 'mvn clean package'
        } else if (env.BRANCH_NAME.startsWith('release/')) {
            echo "发布分支构建"
            sh 'mvn clean release:prepare release:perform'
        } else {
            echo "其他分支构建"
            sh 'mvn clean package -DskipTests'
        }
    }
}

// switch语句
node {
    stage('Deploy') {
        def targetEnv = params.ENVIRONMENT
        switch (targetEnv) {
            case 'dev':
                echo "部署到Dev"
                break
            case 'staging':
                echo "部署到Staging"
                break
            case 'prod':
                echo "部署到Production"
                break
            default:
                error "未知环境: ${targetEnv}"
        }
    }
}
```

## 1.3 循环

```groovy
// for循环
node {
    stage('Deploy') {
        def servers = ['dev-server', 'staging-server', 'prod-server']
        for (server in servers) {
            echo "部署到 ${server}"
            sh "./deploy.sh ${server}"
        }
    }
}

// each循环
node {
    stage('Multi-Container Deploy') {
        ['web', 'api', 'worker'].each { service ->
            echo "部署 ${service}"
            sh "./deploy-service.sh ${service}"
        }
    }
}

// while循环
node {
    stage('Retry Loop') {
        def attempts = 0
        while (attempts < 3) {
            try {
                echo "尝试 #${attempts + 1}"
                sh './fragile-script.sh'
                break
            } catch (Exception e) {
                attempts++
                if (attempts >= 3) {
                    throw e
                }
                echo "失败，等待重试..."
                sleep 10
            }
        }
    }
}
```

## 1.4 异常处理

```groovy
// try-catch-finally
node {
    stage('Deploy') {
        try {
            echo "执行部署"
            sh './deploy.sh'

        } catch (Exception e) {
            echo "部署失败: ${e.message}"
            currentBuild.result = 'FAILURE'
            throw e

        } finally {
            echo "清理工作"
            sh './cleanup.sh'
        }
    }
}

// timeout超时处理
node {
    stage('Long Running') {
        timeout(time: 30, unit: 'MINUTES') {
            echo "执行长时间任务"
            sh './long-running-task.sh'
        }
    }
}
```

---

# 2. 共享库

## 2.1 共享库结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins共享库结构                             │
└─────────────────────────────────────────────────────────────────┘

shared-library/
├── src/                          # 源代码目录
│   └── com/
│       └── example/
│           ├── Utils.groovy      # 工具类
│           └── Deploy.groovy    # 部署类
├── vars/                         # 全局变量 (步骤)
│   ├── buildApp.groovy          # buildApp step
│   ├── deployApp.groovy        # deployApp step
│   └── notifySlack.groovy       # notifySlack step
├── resources/                    # 资源文件
│   └── templates/
│       └── report.html
└── README.md

# vars/下的groovy文件会自动暴露为pipeline步骤
```

## 2.2 定义全局变量

```groovy
// vars/buildApp.groovy
// 文件名即步骤名

def call(String appName, String version = 'latest') {
    echo "构建应用: ${appName} v${version}"
    sh "mvn clean package -Dapp.name=${appName} -Dapp.version=${version}"
    return true
}

// 使用参数映射
def call(Map config) {
    echo "构建应用: ${config.appName} v${config.version}"
    sh "mvn clean package -Dapp.name=${config.appName}"
    if (config.skipTests) {
        sh "mvn package -DskipTests"
    }
    return true
}
```

```groovy
// vars/deployApp.groovy

def call(String environment, String appName) {
    pipeline {
        agent any
        stages {
            stage("Deploy to ${environment}") {
                steps {
                    script {
                        echo "部署 ${appName} 到 ${environment}"
                        sh "./deploy.sh -e ${environment} -a ${appName}"
                    }
                }
            }
        }
    }
}
```

## 2.3 工具类

```groovy
// src/com/example/Utils.groovy
package com.example

class Utils implements Serializable {
    def steps

    Utils(steps) {
        this.steps = steps
    }

    def runMaven(String goals) {
        steps.sh "mvn ${goals}"
    }

    def notify(String message) {
        steps.echo "通知: ${message}"
    }

    def retry(int maxRetries, Closure action) {
        for (int i = 0; i < maxRetries; i++) {
            try {
                return action()
            } catch (Exception e) {
                if (i == maxRetries - 1) {
                    throw e
                }
                steps.echo "重试 ${i + 1}/${maxRetries}"
                steps.sleep 5
            }
        }
    }
}
```

## 2.4 使用共享库

```groovy
// 在Jenkinsfile中使用共享库

// 方式1: 在Jenkins配置中全局添加

// 方式2: 在Pipeline中声明
@Library('my-shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    def utils = new com.example.Utils(this)
                    utils.runMaven('clean package')
                }
            }
        }

        stage('Deploy') {
            steps {
                // 直接使用vars中定义的步骤
                buildApp 'my-app', '1.0.0'
                deployApp 'production', 'my-app'
            }
        }
    }
}

// 方式3: 导入特定版本
@Library('my-library@v1.2.0') _
```

---

# 3. 并行执行

## 3.1 stage内并行

```groovy
// stage级别并行
pipeline {
    agent any
    stages {
        stage('Parallel Build') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo "构建前端"
                        sh 'npm run build'
                    }
                }
                stage('Build Backend') {
                    steps {
                        echo "构建后端"
                        sh './gradlew build'
                    }
                }
                stage('Build Docs') {
                    steps {
                        echo "构建文档"
                        sh 'mkdocs build'
                    }
                }
            }
        }
    }
}
```

## 3.2 矩阵构建

```groovy
// Multi-configuration Pipeline (矩阵构建)
pipeline {
    agent none
    parameters {
        choice(name: 'PLATFORM', choices: ['linux', 'windows', 'mac'], description: '选择平台')
    }
    stages {
        stage('Build') {
            steps {
                script {
                    def platform = params.PLATFORM
                    echo "在 ${platform} 上构建"
                    if (platform == 'linux') {
                        sh './build-linux.sh'
                    } else if (platform == 'windows') {
                        bat 'build-windows.bat'
                    } else {
                        sh './build-mac.sh'
                    }
                }
            }
        }
    }
}

// 使用matrix
pipeline {
    agent none
    stages {
        stage('Test') {
            matrix {
                axes {
                    axis {
                        name 'PLATFORM'
                        values 'linux', 'windows', 'mac'
                    }
                    axis {
                        name 'BROWSER'
                        values 'chrome', 'firefox', 'safari'
                    }
                }
                agent { label "${PLATFORM}" }
                stages {
                    stage('Test') {
                        steps {
                            echo "在 ${PLATFORM} 上测试 ${BROWSER}"
                        }
                    }
                }
            }
        }
    }
}
```

## 3.3 跨节点并行

```groovy
// 跨多个Agent并行执行
pipeline {
    agent none
    stages {
        stage('Deploy to Multiple Servers') {
            steps {
                script {
                    def servers = [
                        [name: 'server1', ip: '192.168.1.10'],
                        [name: 'server2', ip: '192.168.1.11'],
                        [name: 'server3', ip: '192.168.1.12']
                    ]

                    def deployJobs = [:]

                    servers.each { server ->
                        deployJobs[server.name] = {
                            node('deploy') {
                                stage("Deploy to ${server.name}") {
                                    echo "部署到 ${server.name} (${server.ip})"
                                    sh "./deploy.sh -h ${server.ip}"
                                                        }
                            }
                        }
                    }

                    parallel deployJobs
                }
            }
        }
    }
}
```

---

# 4. 高级语法

## 4.1 脚本块

```groovy
// script块中使用Groovy代码
pipeline {
    agent any
    stages {
        stage('Script') {
            steps {
                script {
                    // 定义变量
                    def name = "Jenkins"
                    def version = 2.0

                    // 字符串操作
                    def upperName = name.toUpperCase()

                    // JSON处理
                    def json = readJSON text: '{"app": "jenkins"}'
                    echo json.app

                    // 文件操作
                    def content = readFile file: 'config.txt'
                    writeFile file: 'output.txt', text: 'result'

                    // 日期处理
                    def date = new Date()
                    def formatted = date.format('yyyy-MM-dd')

                    echo "Hello ${upperName} v${version} at ${formatted}"
                }
            }
        }
    }
}
```

## 4.2 动态指令

```groovy
// 动态stage
pipeline {
    agent any
    parameters {
        text(name: 'STAGES', defaultValue: 'build,test,deploy', description: '要执行的阶段')
    }
    stages {
        stage('Dynamic Stages') {
            steps {
                script {
                    def stagesList = params.STAGES.split(',')
                    stagesList.each { stageName ->
                        stage(stageName.trim()) {
                            echo "执行阶段: ${stageName}"
                            // 执行对应命令
                        }
                    }
                }
            }
        }
    }
}
```

## 4.3 触发器

```groovy
// 定时触发
pipeline {
    agent any
    triggers {
        cron('H H(0-8) * * 1-5')  // 工作日0-8点每小时
        cron('H H9 * * *')        // 每天9点
        cron('H/15 * * * *')      // 每15分钟
    }
    stages {
        stage('Daily Build') {
            steps {
                echo '执行每日构建'
            }
        }
    }
}

// GitHub webhook触发
pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Build') {
            steps {
                echo '代码有更新，开始构建'
            }
        }
    }
}
```

## 4.4 输入和审批

```groovy
// input步骤实现人工审批
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                input message: '确认部署?',
                      ok: '确认',
                      submitter: 'admin,dev-lead',
                      parameters: [
                          choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: '环境'),
                          string(name: 'VERSION', defaultValue: '', description: '版本号')
                      ]
                echo '已批准，开始部署'
            }
        }
    }
}

// 完整示例
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo '构建完成'
            }
        }

        stage('Deploy to Staging') {
            steps {
                echo '部署到Staging'
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: '是否部署到生产环境?',
                          ok: '部署',
                          submitter: 'admin,production-team'
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                echo '部署到Production'
            }
        }
    }
}
```

---

# 5. 常用插件

## 5.1 Docker插件

```groovy
// docker插件使用
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            label 'docker'
            args '-v /root/.m2:/root/.m2'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

// docker.build
stage('Build Image') {
    steps {
        script {
            def image = docker.build("myapp:${env.BUILD_NUMBER}", "-f Dockerfile .")
            docker.withRegistry('https://registry.example.com', 'docker-registry') {
                image.push()
            }
        }
    }
}

// docker.withRegistry
docker.withRegistry('https://registry.example.com', 'docker-credentials') {
    def image = docker.image("myapp:latest")
    image.push()
}
```

## 5.2 Kubernetes插件

```groovy
// kubernetes插件
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-pvc
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn --version'
                }
            }
        }
    }
}
```

## 5.3 通知插件

```groovy
// Slack通知
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
    post {
        success {
            slackSend channel: '#ci-cd',
                      color: 'good',
                      message: "构建成功: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            slackSend channel: '#ci-cd',
                      color: 'danger',
                      message: "构建失败: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}

// Email通知
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
    post {
        always {
            emailext(
                subject: "构建 ${currentBuild.result}: ${env.JOB_NAME}",
                body: """
                    构建结果: ${currentBuild.result}
                    构建编号: ${env.BUILD_NUMBER}
                    构建URL: ${env.BUILD_URL}
                """,
                to: 'team@example.com'
            )
        }
    }
}
```

---

## 本章小结

- **Scripted Pipeline**基于Groovy，提供更灵活的编程能力
- **共享库**实现代码复用，支持在vars/和src/下定义
- **并行执行**通过parallel块实现多任务并发
- **矩阵构建**实现多维度组合构建
- **input**步骤实现人工审批和交互
- **脚本块**中可以使用Groovy的全部特性

**高级特性使用:**

```groovy
// 并行执行
parallel {
    stage('A') { ... }
    stage('B') { ... }
}

// 共享库
@Library('my-lib') _
buildApp 'app', '1.0'

// 人工审批
input message: '确认?', submitter: 'admin'

// 重试
retry(3) {
    sh './fragile.sh'
}
```