# Pipeline基础和语法

## 本章导学

**学完本章后，你将能够：**

- 理解Jenkins Pipeline的核心概念
- 掌握Declarative Pipeline语法
- 编写基本的CI/CD Pipeline

**学习方法：**

```
Pipeline概念 → 语法结构 → 基础指令 → 实战案例
```

---

# 1. Pipeline概述

## 1.1 什么是Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins Pipeline                              │
└─────────────────────────────────────────────────────────────────┘

# Pipeline (管道) 是Jenkins 2.x的核心特性
# 用于定义CI/CD流程的代码表示

# 两种Pipeline语法:
# 1. Declarative Pipeline (声明式) - 推荐
# 2. Scripted Pipeline (脚本式) - 基于Groovy

# Pipeline优势:
# - 代码化: 版本控制
# - 可审查: 代码审查
# - 可移植: 在不同环境运行
# - 可扩展: 复用和共享
```

## 1.2 Pipeline结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Pipeline结构                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Jenkinsfile (Pipeline定义文件)                                   │
├─────────────────────────────────────────────────────────────────┤
│  pipeline {                                                     │
│      agent any                                                  │
│      stages {                                                   │
│          stage('Build') {                                      │
│              steps {                                           │
│                  // 构建步骤                                   │
│              }                                                  │
│          }                                                      │
│          stage('Test') {                                       │
│              steps {                                           │
│                  // 测试步骤                                   │
│              }                                                  │
│          }                                                      │
│          stage('Deploy') {                                     │
│              steps {                                           │
│                  // 部署步骤                                   │
│              }                                                  │
│          }                                                      │
│      }                                                          │
│  }                                                              │
└─────────────────────────────────────────────────────────────────┘

# 基本组成部分:
# - pipeline: 顶层块
# - agent: 指定执行位置
# - stages: 阶段容器
# - stage: 具体的阶段
# - steps: 步骤容器
```

---

# 2. Declarative Pipeline

## 2.1 基本语法

```groovy
// Jenkinsfile (Declarative Pipeline)
pipeline {
    // 1. agent: 指定在哪里执行
    agent any

    // 2. environment: 环境变量
    environment {
        VERSION = '1.0.0'
    }

    // 3. options: Pipeline选项
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    // 4. parameters: 参数
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Git分支')
    }

    // 5. triggers: 触发器
    triggers {
        cron('H 2 * * *')  // 每天凌晨2点
    }

    // 6. stages: 阶段列表
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'mvn test'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }

    // 7. post: 构建后操作
    post {
        always {
            echo 'Pipeline完成'
        }
        success {
            echo '构建成功'
        }
        failure {
            echo '构建失败'
        }
    }
}
```

## 2.2 agent指令

```groovy
// agent: 指定在哪里执行Pipeline

// 1. any: 任意可用节点
pipeline {
    agent any
}

// 2. none: 不分配节点，在每个stage中单独指定
pipeline {
    agent none
    stages {
        stage('Build') {
            agent { label 'linux' }
            steps {
                echo 'Building on Linux'
            }
        }
    }
}

// 3. label: 指定标签的节点
pipeline {
    agent { label 'docker' }
}

// 4. docker: 使用Docker容器
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            label 'docker'
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

// 5. kubernetes: 使用Kubernetes Pod
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
'''
        }
    }
}
```

## 2.3 stages和steps

```groovy
// stages: 包含多个stage的容器
// stage: 逻辑分组
// steps: 具体的执行命令

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Git检出
                git branch: 'main',
                    url: 'https://github.com/example/app.git'
            }
        }

        stage('Build') {
            steps {
                // 执行shell命令
                sh '''
                    mvn clean package
                '''

                // Windows批处理
                bat 'mvn clean package'

                // 打印信息
                echo "构建完成"
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'

                // 存档测试结果
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Deploy') {
            steps {
                echo '部署到服务器'
            }
        }
    }
}
```

## 2.4 when指令

```groovy
// when: 条件执行stage

pipeline {
    agent any

    stages {
        stage('Build') {
            when {
                expression { env.BRANCH_NAME != 'production' }
            }
            steps {
                echo 'Building...'
            }
        }

        stage('Deploy Production') {
            when {
                expression { env.BRANCH_NAME == 'production' }
                beforeInput true
            }
            steps {
                echo 'Deploying to Production...'
            }
        }

        stage('Deploy') {
            when {
                allOf {
                    branch 'main'
                    environment name: 'DEPLOY_ENABLED', value: 'true'
                }
            }
            steps {
                echo 'Deploying...'
            }
        }
    }
}

// when条件类型:
// - branch: 分支匹配
// - expression: Groovy表达式
// - environment: 环境变量
// - not: 取反
// - allOf: 全部满足
// - anyOf: 任一满足
```

---

# 3. 常用步骤

## 3.1 脚本步骤

```groovy
// sh: 执行Shell命令

stage('Build') {
    steps {
        sh 'echo Hello'
        sh '''
            echo "Multi-line"
            mvn clean package
        '''
        sh label: 'Build', script: '''
            echo "Building ${VERSION}"
            mvn clean package -DskipTests=false
        '''
    }
}

// bat: 执行Windows批处理
stage('Windows Build') {
    steps {
        bat 'dir'
        bat '''
            echo Building
            mvn clean package
        '''
    }
}

// powershell: 执行PowerShell
stage('PowerShell') {
    steps {
        powershell '''
            Write-Host "Hello from PowerShell"
            Get-Process
        '''
    }
}

// error: 抛出异常
stage('Example') {
    steps {
        script {
            if (env.BUILD_NUMBER > 100) {
                error "Build number too high"
            }
        }
    }
}
```

## 3.2 文件操作

```groovy
// writeFile: 写入文件
stage('Create Config') {
    steps {
        script {
            writeFile file: 'config.properties', text: '''
                database.url=jdbc:mysql://localhost:3306
                database.user=admin
                database.password=${DB_PASSWORD}
            '''
        }
    }
}

// readFile: 读取文件
stage('Read Config') {
    steps {
        script {
            def config = readFile file: 'config.properties', encoding: 'UTF-8'
            echo config
        }
    }
}

// archiveArtifacts: 存档构建产物
stage('Archive') {
    steps {
        archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
    }
}

// stash/unstash: 跨stage传递文件
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn package'
                stash name: 'jar', includes: '**/target/*.jar'
            }
        }
        stage('Deploy') {
            steps {
                unstash 'jar'
                sh 'deploy.sh'
            }
        }
    }
}
```

## 3.3 通知步骤

```groovy
// echo: 打印消息
steps {
    echo 'Hello World'
    echo "Building ${env.BRANCH_NAME}"
}

// mail: 发送邮件
steps {
    mail to: 'team@example.com',
         subject: "构建 #${env.BUILD_NUMBER} 结果",
         body: "构建 ${currentBuild.result}: ${env.BUILD_URL}"
}

// slackSend: 发送Slack消息
steps {
    slackSend channel: '#jenkins',
              color: 'good',
              message: "构建成功: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
}

// discordSend: 发送Discord消息
steps {
    discordSend webhookURL: 'YOUR_WEBHOOK_URL',
                 title: 'Build Complete',
                 description: 'Build finished successfully'
}
```

## 3.4 凭证步骤

```groovy
// withCredentials: 使用凭证

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
                    file(
                        credentialsId: 'ssh-key',
                        variable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        echo "Deploying with $DB_USER"
                        db-deploy --user $DB_USER --password $DB_PASS
                    '''
                }
            }
        }
    }
}
```

---

# 4. 环境变量

## 4.1 内置变量

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins内置环境变量                            │
└─────────────────────────────────────────────────────────────────┘

# Pipeline内置变量:
# - WORKSPACE: 工作目录
# - BUILD_NUMBER: 构建编号
# - BUILD_URL: 构建URL
# - JOB_NAME: 任务名称
# - JOB_BASE_NAME: 任务基础名称
# - BUILD_TAG: 构建标签
# - NODE_NAME: 节点名称
# - JENKINS_URL: Jenkins URL
# - GIT_BRANCH: Git分支
# - GIT_COMMIT: Git提交hash
# - GIT_URL: Git仓库URL

# 使用方式:
steps {
    echo "工作目录: ${env.WORKSPACE}"
    echo "构建编号: ${env.BUILD_NUMBER}"
    echo "分支: ${env.GIT_BRANCH}"
}
```

## 4.2 自定义环境变量

```groovy
// environment指令定义
pipeline {
    agent any
    environment {
        APP_NAME = 'my-app'
        VERSION = '1.0.0'
    }
    stages {
        stage('Build') {
            steps {
                echo "构建 ${env.APP_NAME} v${env.VERSION}"
            }
        }
    }
}

// steps中使用environment
pipeline {
    agent any
    stages {
        stage('Build') {
            environment {
                MY_VAR = 'value'
            }
            steps {
                echo "MY_VAR = ${env.MY_VAR}"
            }
        }
    }
}

// setEnvironmentVariable (Scripted Pipeline)
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    env.MY_CUSTOM_VAR = 'custom-value'
                    echo env.MY_CUSTOM_VAR
                }
            }
        }
    }
}
```

---

# 5. 实战案例

## 5.1 Java Maven项目

```groovy
// Java Maven项目CI/CD Pipeline
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }

    environment {
        APP_NAME = 'java-app'
        DB_HOST = 'localhost'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/java-app.git',
                    credentialsId: 'git-credentials'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests=false'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Code Analysis') {
            steps {
                sh 'mvn sonar:sonar'
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }

        stage('Deploy to Dev') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "部署到Dev环境"
                    kubectl apply -f k8s/dev/
                '''
            }
        }

        stage('Deploy to Prod') {
            when {
                expression { env.BUILD_NUMBER > 10 }
                beforeInput true
            }
            input message: '确认部署到生产环境?'
            steps {
                sh '''
                    echo "部署到Production环境"
                    kubectl apply -f k8s/prod/
                '''
            }
        }
    }

    post {
        always {
            echo '清理工作空间'
            cleanWs()
        }
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
```

## 5.2 Node.js项目

```groovy
// Node.js项目CI/CD Pipeline
pipeline {
    agent {
        docker {
            image 'node:16-alpine'
        }
    }

    environment {
        APP_NAME = 'node-app'
        NODE_ENV = 'production'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/node-app.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def imageTag = "myregistry.io/${env.APP_NAME}:${env.BUILD_NUMBER}"
                    docker.withRegistry('https://myregistry.io', 'docker-hub-credentials') {
                        def image = docker.build(imageTag, '-f Dockerfile .')
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    kubectl set image deployment/${APP_NAME} app=${imageTag}
                '''
            }
        }
    }
}
```

## 5.3 多分支Pipeline

```groovy
// Jenkinsfile for Multi-branch Pipeline

pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
        }
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '**/target/*.jar'
        }
    }
}

// Jenkinsfile for GitHub Organization
// 自动扫描组织下的所有仓库
organizationFolder {
    name("Example Organization")
    displayName("Example Organization")

    buildStrategies {
        eventTrigger {
            actionType("CREATED")
            actionType("MODIFIED")
        }
    }

    pipelines {
        standard {
            JenkinsfileProvider {
                amongBranches {
                    defaultVersion("master")
                }
            }
        }
    }
}
```

---

## 本章小结

- **Pipeline**是Jenkins 2.x的核心特性，支持代码化定义CI/CD流程
- **Declarative Pipeline**是推荐的语法，使用pipeline/stages/stage/steps结构
- **agent**指令指定Pipeline执行位置
- **when**指令实现条件执行
- **environment**定义环境变量
- **post**定义构建后操作

**关键语法回顾:**

```groovy
pipeline {
    agent any
    environment { }
    options { }
    parameters { }
    triggers { }
    stages {
        stage('name') {
            when { }
            steps { }
        }
    }
    post { }
}
```