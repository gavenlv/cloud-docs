// 1. 并行执行
stage('Test') {
    parallel {
        stage('Unit Test') {
            steps {
                sh 'mvn test -Dtest=*Test'
            }
        }
        stage('Integration Test') {
            steps {
                sh 'mvn verify -Pintegration-tests'
            }
        }
    }
}

// 2. 使用缓存
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn package'
            }
        }
    }
}

// 3. 增量构建
stage('Build') {
    steps {
        sh 'mvn package -pl module1,module2 -am'
    }
}