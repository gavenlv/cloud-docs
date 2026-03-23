# 常用Pipeline插件

# 1. Pipeline: 核心Pipeline支持
# 内置，无需安装

# 2. Workflow Aggregator: Pipeline聚合
# 内置，无需安装

# 3. Pipeline: Stage View
# 可视化Pipeline执行

# 4. Blue Ocean
# 新一代Pipeline UI
# 安装: blueocean

# 5. Docker Pipeline
# 在Pipeline中使用Docker
# 安装: docker-workflow
pipeline {
    agent {
        docker { image 'maven:3.8-openjdk-11' }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

# 6. Kubernetes Pipeline
# Kubernetes集成
# 安装: kubernetes