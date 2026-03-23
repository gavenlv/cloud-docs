// 安全使用凭证

// 1. 使用credentialsId而非明文
steps {
    withCredentials([
        usernamePassword(
            credentialsId: 'db-credentials',
            usernameVariable: 'DB_USER',
            passwordVariable: 'DB_PASS'
        )
    ]) {
        sh './deploy.sh'
    }
}

// 2. 不要在日志中输出敏感信息
// 错误示例
echo "密码: ${DB_PASS}"  // 不要这样做

// 3. 最小权限原则
// 只授予完成任务所需的最小权限

// 4. 定期轮换凭证