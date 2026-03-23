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