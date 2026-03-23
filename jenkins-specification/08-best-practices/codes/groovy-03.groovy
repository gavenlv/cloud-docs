// 建议的错误处理方式

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    try {
                        sh 'mvn clean package'
                    } catch (Exception e) {
                        echo "构建失败: ${e.message}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
    }
}

// 重试机制
stage('Deploy') {
    steps {
        retry(3) {
            sh './deploy.sh'
        }
    }
}

// 超时设置
stage('Long Running') {
    steps {
        timeout(time: 30, unit: 'MINUTES') {
            sh './long-task.sh'
        }
    }
}