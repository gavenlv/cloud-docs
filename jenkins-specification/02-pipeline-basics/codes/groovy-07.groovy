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