// 检出多个仓库
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                dir('frontend') {
                    git branch: 'main',
                        url: 'https://github.com/example/frontend.git',
                        credentialsId: 'git-credentials'
                }
                dir('backend') {
                    git branch: 'main',
                        url: 'https://github.com/example/backend.git',
                        credentialsId: 'git-credentials'
                }
            }
        }
    }
}

// 使用checkout代替git
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/example/app.git',
                        credentialsId: 'git-credentials'
                    ]],
                    submoduleCfg: [],
                    extensions: [
                        [$class: 'RelativeTargetDirectory', relativeTargetDir: 'app'],
                        [$class: 'SubmoduleOption', depth: 1, recursive: true]
                    ]
                ])
            }
        }
    }
}