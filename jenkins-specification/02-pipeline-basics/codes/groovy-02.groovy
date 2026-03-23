// agent: 指定在哪里执行Pipeline

// 1. any: 任意可用节点
pipeline {
    agent any
}

// 2. none: 不分配节点，在每个stage中单独指定
pipeline {
    agent none
    stages {
        stage('Build') {
            agent { label 'linux' }
            steps {
                echo 'Building on Linux'
            }
        }
    }
}

// 3. label: 指定标签的节点
pipeline {
    agent { label 'docker' }
}

// 4. docker: 使用Docker容器
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            label 'docker'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

// 5. kubernetes: 使用Kubernetes Pod
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
'''
        }
    }
}