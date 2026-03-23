// 使用共享库提高复用性

// vars/buildApp.groovy
def call(String appName, String version = 'latest') {
    sh "mvn clean package -Dapp.name=${appName} -Dapp.version=${version}"
}

// vars/deployApp.groovy
def call(String environment) {
    sh "./deploy.sh -e ${environment}"
}

// Pipeline中使用
@Library('my-shared-library') _

pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                buildApp 'myapp', '1.0.0'
            }
        }
        stage('Deploy') {
            steps {
                deployApp 'production'
            }
        }
    }
}