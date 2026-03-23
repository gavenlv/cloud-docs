// Kubernetes部署Pipeline
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
  - name: kubectl
    image: bitnami/kubectl:1.24
    command: sleep
    args: infinity
    volumeMounts:
    - name: kube-config
      mountPath: /root/.kube
  volumes:
  - name: kube-config
    secret:
      secretName: kube-config
'''
        }
    }
    stages {
        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context dev
                        kubectl apply -f k8s/dev/
                        kubectl rollout status deployment/myapp -n dev
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            when {
                expression { env.BUILD_NUMBER > 100 }
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl config use-context prod
                        kubectl set image deployment/myapp app=myregistry.io/myapp:${env.BUILD_NUMBER}
                        kubectl rollout status deployment/myapp -n production
                    '''
                }
            }
        }
    }
}