// JaCoCo代码覆盖率
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'mvn test jacoco:report'
            }
        }

        stage('Coverage Report') {
            steps {
                publishHTML([
                    reportDir: 'target/site/jacoco',
                    reportFiles: 'index.html',
                    reportName: 'JaCoCo Coverage'
                ])
            }
        }
    }
}