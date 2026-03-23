// Maven构建Pipeline
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            args '-v /root/.m2:/root/.m2'
        }
    }

    environment {
        MAVEN_OPTS = '-Dmaven.repo.local=/root/.m2/repository'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/java-app.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Code Analysis') {
            steps {
                sh 'mvn sonar:sonar -Dsonar.host.url=http://sonarqube:9000'
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            emailext(
                subject: "构建成功: ${env.JOB_NAME}",
                body: "构建 #${env.BUILD_NUMBER} 成功",
                to: 'team@example.com'
            )
        }
    }
}