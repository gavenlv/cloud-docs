// 沙箱安全
pipeline {
    agent any
    options {
        // 禁用脚本安全 (谨慎使用)
        // sandbox: false
    }

    stages {
        stage('Build') {
            steps {
                // 使用批准的方法
            }
        }
    }
}

// 防止信息泄露
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    // 不要在steps中直接打印环境变量
                    def secretValue = env.MY_SECRET
                    echo "Secret length: ${secretValue.length()}"
                }
            }
        }
    }
}