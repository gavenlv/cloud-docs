// 动态创建和销毁Agent
pipeline {
    agent {
        kubernetes {
            label 'dynamic-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
  - name: builder
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('builder') {
                    sh 'mvn clean package'
                }
            }
        }
    }
    // 构建完成后自动销毁Pod
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
}