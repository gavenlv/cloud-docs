// Node.js项目CI/CD Pipeline
pipeline {
    agent {
        docker {
            image 'node:16-alpine'
        }
    }

    environment {
        APP_NAME = 'node-app'
        NODE_ENV = 'production'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/node-app.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def imageTag = "myregistry.io/${env.APP_NAME}:${env.BUILD_NUMBER}"
                    docker.withRegistry('https://myregistry.io', 'docker-hub-credentials') {
                        def image = docker.build(imageTag, '-f Dockerfile .')
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    kubectl set image deployment/${APP_NAME} app=${imageTag}
                '''
            }
        }
    }
}