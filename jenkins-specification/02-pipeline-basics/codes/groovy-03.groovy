// stages: 包含多个stage的容器
// stage: 逻辑分组
// steps: 具体的执行命令

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Git检出
                git branch: 'main',
                    url: 'https://github.com/example/app.git'
            }
        }

        stage('Build') {
            steps {
                // 执行shell命令
                sh '''
                    mvn clean package
                '''

                // Windows批处理
                bat 'mvn clean package'

                // 打印信息
                echo "构建完成"
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'

                // 存档测试结果
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Deploy') {
            steps {
                echo '部署到服务器'
            }
        }
    }
}