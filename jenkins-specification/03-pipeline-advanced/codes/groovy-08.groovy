// 在Jenkinsfile中使用共享库

// 方式1: 在Jenkins配置中全局添加

// 方式2: 在Pipeline中声明
@Library('my-shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    def utils = new com.example.Utils(this)
                    utils.runMaven('clean package')
                }
            }
        }

        stage('Deploy') {
            steps {
                // 直接使用vars中定义的步骤
                buildApp 'my-app', '1.0.0'
                deployApp 'production', 'my-app'
            }
        }
    }
}

// 方式3: 导入特定版本
@Library('my-library@v1.2.0') _