// 使用workspace实现隔离
pipeline {
    agent none
    stages {
        stage('Build') {
            agent {
                label 'linux'
                customWorkspace '/home/jenkins/workspace/${JOB_NAME}'
            }
            steps {
                echo "工作空间: ${env.WORKSPACE}"
            }
        }
    }
}

// 并行构建隔离
pipeline {
    agent any
    stages {
        stage('Parallel Build') {
            parallel {
                stage('App1') {
                    agent { label 'linux' }
                    steps {
                        dir('app1') {
                            sh 'mvn package'
                        }
                    }
                }
                stage('App2') {
                    agent { label 'linux' }
                    steps {
                        dir('app2') {
                            sh 'mvn package'
                        }
                    }
                }
            }
        }
    }
}