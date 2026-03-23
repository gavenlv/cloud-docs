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