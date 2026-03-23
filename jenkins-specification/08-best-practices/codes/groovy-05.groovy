// 单元测试
stage('Unit Tests') {
    steps {
        sh 'mvn test'
    }
    post {
        always {
            junit '**/target/surefire-reports/*.xml'
        }
    }
}

// 集成测试
stage('Integration Tests') {
    steps {
        sh 'mvn verify -Pintegration-tests'
    }
    post {
        always {
            junit '**/target/failsafe-reports/*.xml'
        }
    }
}

// 性能测试
stage('Performance Tests') {
    steps {
        sh 'mvn gatling:execute'
    }
}

// 安全测试
stage('Security Scan') {
    steps {
        sh 'mvn dependency-check:check'
    }
}