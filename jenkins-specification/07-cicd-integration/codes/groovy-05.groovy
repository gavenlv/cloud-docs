// Node.js构建Pipeline
pipeline {
    agent {
        docker {
            image 'node:16-alpine'
        }
    }

    environment {
        CI = 'true'
    }

    stages {
        stage('Install') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint || true'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
            post {
                always {
                    junit '**/test-results/*.xml'
                    cobertura coberturaReportFile: '**/coverage/cobertura-coverage.xml'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageName = "myregistry.io/app:${env.BUILD_NUMBER}"
                    def image = docker.build(imageName, "-f Dockerfile .")
                    docker.withRegistry('https://myregistry.io', 'docker-registry') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
    }
}