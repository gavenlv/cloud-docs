# 常用通知插件

# 1. Slack
# 安装: slack
steps {
    slackSend channel: '#ci-cd',
              color: 'good',
              message: "构建成功: ${env.JOB_NAME}"
}

# 2. Email Extension
# 安装: email-ext
steps {
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

# 3. Discord
# 安装: discord
steps {
    discordSend webhookURL: 'YOUR_WEBHOOK_URL',
                 title: 'Build Complete',
                 description: 'Build finished'
}