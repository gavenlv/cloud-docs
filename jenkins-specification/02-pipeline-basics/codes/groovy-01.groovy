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