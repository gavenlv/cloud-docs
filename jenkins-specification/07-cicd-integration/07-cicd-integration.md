# CI/CD集成

## 本章导学

**学完本章后，你将能够：**

- 掌握Git与Jenkins集成
- 实现自动化构建和部署
- 集成容器化和Kubernetes

**学习方法：**

```
Git集成 → 自动化构建 → 容器化 → K8s部署
```

---

# 1. Git集成

## 1.1 Git插件配置

```groovy
// 基础Git配置
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git',
                    credentialsId: 'git-credentials'
            }
        }
    }
}

// 完整配置
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git',
                    credentialsId: 'git-credentials',
                    changelog: true,
                    poll: true
            }
        }
    }
}
```

## 1.2 多仓库配置

```groovy
// 检出多个仓库
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                dir('frontend') {
                    git branch: 'main',
                        url: 'https://github.com/example/frontend.git',
                        credentialsId: 'git-credentials'
                }
                dir('backend') {
                    git branch: 'main',
                        url: 'https://github.com/example/backend.git',
                        credentialsId: 'git-credentials'
                }
            }
        }
    }
}

// 使用checkout代替git
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/example/app.git',
                        credentialsId: 'git-credentials'
                    ]],
                    submoduleCfg: [],
                    extensions: [
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: 'app'],
                        [$class: 'SubmoduleOption', depth: 1, recursive: true]
                    ]
                ])
            }
        }
    }
}
```

---

# 2. Webhook触发

## 2.1 GitHub Webhook

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Webhook配置                             │
└─────────────────────────────────────────────────────────────────┘

# 触发流程:
# 1. 代码提交到GitHub
# 2. GitHub发送POST请求到Jenkins
# 3. Jenkins触发构建

# 配置步骤:
# 1. Jenkins安装GitHub插件
# 2. GitHub设置Webhook:
#    - Payload URL: http://jenkins:8080/github-webhook/
#    - Content type: application/json
#    - Events: Push, Pull request
```

## 2.2 Pipeline配置

```groovy
// 启用Webhook触发
// 方式1: 在Pipeline中配置
pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Build') {
            steps {
                echo '收到GitHub推送，开始构建'
            }
        }
    }
}

// 方式2: Generic Webhook Trigger插件
pipeline {
    agent any
    triggers {
        genericTrigger {
            genericVariables {
                genericVariable {
                    value("ref")
                    expression("refs")
                    variable("GIT_BRANCH")
                }
            }
            causeString('Generic Cause')
            token('my-secret-token')
        }
    }
    stages {
        stage('Build') {
            steps {
                echo "分支: ${GIT_BRANCH}"
            }
        }
    }
}

// GitLab配置
triggers {
    gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
}
```

---

# 3. 自动化构建

## 3.1 Maven项目

```groovy
// Maven构建Pipeline
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }

    environment {
        MAVEN_OPTS = '-Dmaven.repo.local=/root/.m2/repository'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/java-app.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Code Analysis') {
            steps {
                sh 'mvn sonar:sonar -Dsonar.host.url=http://sonarqube:9000'
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            emailext(
                subject: "构建成功: ${env.JOB_NAME}",
                body: "构建 #${env.BUILD_NUMBER} 成功",
                to: 'team@example.com'
            )
        }
    }
}
```

## 3.2 Node.js项目

```groovy
// Node.js构建Pipeline
pipeline {
    agent {
        docker {
            image 'node:16-alpine'
        }
    }

    environment {
        CI = 'true'
    }

    stages {
        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint || true'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
            post {
                always {
                    junit '**/test-results/*.xml'
                    cobertura coberturaReportFile: '**/coverage/cobertura-coverage.xml'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageName = "myregistry.io/app:${env.BUILD_NUMBER}"
                    def image = docker.build(imageName, "-f Dockerfile .")
                    docker.withRegistry('https://myregistry.io', 'docker-registry') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
    }
}
```

## 3.3 Python项目

```groovy
// Python构建Pipeline
pipeline {
    agent any

    environment {
        VIRTUAL_ENV = '/workspace/venv'
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    python3 -m venv ${VIRTUAL_ENV}
                    . ${VIRTUAL_ENV}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    pylint src/
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    pytest --junitxml=test-results/junit.xml
                '''
            }
            post {
                always {
                    junit 'test-results/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    python setup.py sdist bdist_wheel
                '''
                archiveArtifacts artifacts: 'dist/*', fingerprint: true
            }
        }
    }
}
```

---

# 4. 容器化集成

## 4.1 Docker Pipeline

```groovy
// Docker构建和推送
pipeline {
    agent {
        label 'docker'
    }

    environment {
        REGISTRY = 'myregistry.io'
        IMAGE_NAME = 'myapp'
    }

    stages {
        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "${env.REGISTRY}/${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
                    def image = docker.build(imageTag, "-f Dockerfile .")
                    docker.withRegistry("https://${env.REGISTRY}", 'docker-registry') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${env.REGISTRY}/${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
            }
        }
    }
}
```

## 4.2 Docker配置

```groovy
// Docker配置文件示例
// Dockerfile
FROM openjdk:11-jdk-slim

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

```dockerfile
# Multi-stage Dockerfile
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM openjdk:11-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## 4.3 Docker Registry

```groovy
// 多种Registry配置

// 1. Docker Hub
docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
    def image = docker.build("myusername/myapp:${env.BUILD_NUMBER}")
    image.push()
}

// 2. AWS ECR
pipeline {
    stages {
        stage('Login to ECR') {
            steps {
                script {
                    def ecr = evaluate new Groovy slurper().parseText('{"region":"us-east-1"}')
                    docker.withRegistry("https://${ecr.region}.dkr.ecr.amazonaws.com", 'aws-ecr') {
                        // build and push
                    }
                }
            }
        }
    }
}

// 3. GCR (Google Container Registry)
docker.withRegistry('https://gcr.io', 'gcr-credentials') {
    def image = docker.build("gcr.io/my-project/myapp:${env.BUILD_NUMBER}")
    image.push()
}
```

---

# 5. Kubernetes集成

## 5.1 kubectl配置

```groovy
// Kubernetes部署Pipeline
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
  - name: kubectl
    image: bitnami/kubectl:1.24
    command: sleep
    args: infinity
    volumeMounts:
    - name: kube-config
      mountPath: /root/.kube
  volumes:
  - name: kube-config
    secret:
      secretName: kube-config
'''
        }
    }
    stages {
        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context dev
                        kubectl apply -f k8s/dev/
                        kubectl rollout status deployment/myapp -n dev
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            when {
                expression { env.BUILD_NUMBER > 100 }
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context prod
                        kubectl set image deployment/myapp app=myregistry.io/myapp:${env.BUILD_NUMBER}
                        kubectl rollout status deployment/myapp -n production
                    '''
                }
            }
        }
    }
}
```

## 5.2 Helm部署

```groovy
// Helm部署Pipeline
pipeline {
    agent any

    stages {
        stage('Prepare') {
            steps {
                sh '''
                    helm repo update
                    helm dependency build
                '''
            }
        }

        stage('Lint') {
            steps {
                sh 'helm lint ./chart'
            }
        }

        stage('Template') {
            steps {
                sh '''
                    helm template release ./chart \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --output-dir ./output
                '''
            }
        }

        stage('Deploy to Dev') {
            steps {
                sh '''
                    helm upgrade --install myapp ./chart \
                        --namespace dev \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --wait --timeout 5m
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    kubectl exec -n dev deployment/myapp -- curl -s http://localhost:8080/health
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                input message: '确认部署到生产环境?', ok: '确认'
                sh '''
                    helm upgrade --install myapp ./chart \
                        --namespace production \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --wait --timeout 10m
                '''
            }
        }
    }
}
```

## 5.3 完整CI/CD流程

```groovy
// 完整的CI/CD Pipeline
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
  - name: kubectl
    image: bitnami/kubectl:1.24
    command: sleep
    args: infinity
  - name: docker
    image: docker:20.10-dind
    command: sleep
    args: infinity
    securityContext:
      privileged: true
'''
        }
    }

    environment {
        REGISTRY = 'myregistry.io'
        APP_NAME = 'myapp'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git'
            }
        }

        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Test') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    script {
                        def image = docker.build("${env.REGISTRY}/${env.APP_NAME}:${env.BUILD_NUMBER}")
                        docker.withRegistry("https://${env.REGISTRY}", 'docker-registry') {
                            image.push()
                        }
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context dev
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context staging
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    sleep 30
                    kubectl exec -n staging deployment/${APP_NAME} -- curl -s http://localhost:8080/health
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context prod
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                        kubectl rollout status deployment/${APP_NAME} -n production
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend channel: '#ci-cd',
                      color: 'good',
                      message: "部署成功: ${env.APP_NAME} v${env.BUILD_NUMBER}"
        }
        failure {
            slackSend channel: '#ci-cd',
                      color: 'danger',
                      message: "部署失败: ${env.APP_NAME}"
        }
    }
}
```

---

## 本章小结

- **Git集成**通过Git插件实现代码检出和多仓库管理
- **Webhook**实现代码提交自动触发构建
- **容器化**通过Docker Pipeline实现镜像构建和推送
- **Kubernetes集成**使用kubectl/Helm实现自动化部署
- **完整CI/CD**覆盖从代码提交到生产部署的全流程

**CI/CD流程:**

```
代码提交 → Git触发 → 构建 → 测试 → 镜像构建 → 扫描 → 部署Dev → 部署Staging → 人工审批 → 部署Production
```