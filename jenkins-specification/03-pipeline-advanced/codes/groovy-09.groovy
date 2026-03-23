// stage级别并行
pipeline {
    agent any
    stages {
        stage('Parallel Build') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo "构建前端"
                        sh 'npm run build'
                    }
                }
                stage('Build Backend') {
                    steps {
                        echo "构建后端"
                        sh './gradlew build'
                    }
                }
                stage('Build Docs') {
                    steps {
                        echo "构建文档"
                        sh 'mkdocs build'
                    }
                }
            }
        }
    }
}