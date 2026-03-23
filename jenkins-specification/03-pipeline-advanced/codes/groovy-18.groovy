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