// Docker构建和推送
pipeline {
    agent {
        label 'docker'
    }

    environment {
        REGISTRY = 'myregistry.io'
        IMAGE_NAME = 'myapp'
    }

    stages {
        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    def imageTag = "${env.REGISTRY}/${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
                    def image = docker.build(imageTag, "-f Dockerfile .")
                    docker.withRegistry("https://${env.REGISTRY}", 'docker-registry') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh "trivy image ${env.REGISTRY}/${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
            }
        }
    }
}