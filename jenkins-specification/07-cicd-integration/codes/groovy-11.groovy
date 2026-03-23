// Helm部署Pipeline
pipeline {
    agent any

    stages {
        stage('Prepare') {
            steps {
                sh '''
                    helm repo update
                    helm dependency build
                '''
            }
        }

        stage('Lint') {
            steps {
                sh 'helm lint ./chart'
            }
        }

        stage('Template') {
            steps {
                sh '''
                    helm template release ./chart \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --output-dir ./output
                '''
            }
        }

        stage('Deploy to Dev') {
            steps {
                sh '''
                    helm upgrade --install myapp ./chart \
                        --namespace dev \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --wait --timeout 5m
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    kubectl exec -n dev deployment/myapp -- curl -s http://localhost:8080/health
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                input message: '确认部署到生产环境?', ok: '确认'
                sh '''
                    helm upgrade --install myapp ./chart \
                        --namespace production \
                        --set image.tag=${env.BUILD_NUMBER} \
                        --wait --timeout 10m
                '''
            }
        }
    }
}