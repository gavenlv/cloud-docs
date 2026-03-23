// 完整的CI/CD Pipeline
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
  - name: kubectl
    image: bitnami/kubectl:1.24
    command: sleep
    args: infinity
  - name: docker
    image: docker:20.10-dind
    command: sleep
    args: infinity
    securityContext:
      privileged: true
'''
        }
    }

    environment {
        REGISTRY = 'myregistry.io'
        APP_NAME = 'myapp'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/example/app.git'
            }
        }

        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Test') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    script {
                        def image = docker.build("${env.REGISTRY}/${env.APP_NAME}:${env.BUILD_NUMBER}")
                        docker.withRegistry("https://${env.REGISTRY}", 'docker-registry') {
                            image.push()
                        }
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context dev
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context staging
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    sleep 30
                    kubectl exec -n staging deployment/${APP_NAME} -- curl -s http://localhost:8080/health
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context prod
                        kubectl set image deployment/${APP_NAME} app=${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
                        kubectl rollout status deployment/${APP_NAME} -n production
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend channel: '#ci-cd',
                      color: 'good',
                      message: "部署成功: ${env.APP_NAME} v${env.BUILD_NUMBER}"
        }
        failure {
            slackSend channel: '#ci-cd',
                      color: 'danger',
                      message: "部署失败: ${env.APP_NAME}"
        }
    }
}