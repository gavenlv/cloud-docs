// Scripted Pipeline vs Declarative Pipeline
// Scripted更灵活，基于Groovy脚本

node('docker') {
    // stage等价于Declarative的stages
    stage('Checkout') {
        echo "检出代码"
        git branch: 'main',
            url: 'https://github.com/example/app.git'
    }

    stage('Build') {
        echo "构建应用"
        sh 'mvn clean package'
    }

    stage('Test') {
        echo "运行测试"
        sh 'mvn test'
    }

    stage('Deploy') {
        echo "部署应用"
        sh './deploy.sh'
    }
}