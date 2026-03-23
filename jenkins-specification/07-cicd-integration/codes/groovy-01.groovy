// 基础Git配置
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git',
                    credentialsId: 'git-credentials'
            }
        }
    }
}

// 完整配置
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git',
                    credentialsId: 'git-credentials',
                    changelog: true,
                    poll: true
            }
        }
    }
}