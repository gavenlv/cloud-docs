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