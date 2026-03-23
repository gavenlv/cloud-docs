// kubernetes插件
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
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-pvc
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn --version'
                }
            }
        }
    }
}