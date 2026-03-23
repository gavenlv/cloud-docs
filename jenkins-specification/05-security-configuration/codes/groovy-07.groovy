// 凭证掩码
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'secret',
                        variable: 'MY_SECRET'
                    )
                ]) {
                    // 在日志中隐藏secret
                    echo "Secret: ${MY_SECRET}"
                }
            }
        }
    }
}

// 禁用凭证序列化警告
// Manage Jenkins → Configure Global Security
// Enable Credentials wrapping?: ✓

// 安全Realm配置
// 防止跨维度攻击