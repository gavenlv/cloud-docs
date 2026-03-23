// environment指令定义
pipeline {
    agent any
    environment {
        APP_NAME = 'my-app'
        VERSION = '1.0.0'
    }
    stages {
        stage('Build') {
            steps {
                echo "构建 ${env.APP_NAME} v${env.VERSION}"
            }
        }
    }
}

// steps中使用environment
pipeline {
    agent any
    stages {
        stage('Build') {
            environment {
                MY_VAR = 'value'
            }
            steps {
                echo "MY_VAR = ${env.MY_VAR}"
            }
        }
    }
}

// setEnvironmentVariable (Scripted Pipeline)
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    env.MY_CUSTOM_VAR = 'custom-value'
                    echo env.MY_CUSTOM_VAR
                }
            }
        }
    }
}