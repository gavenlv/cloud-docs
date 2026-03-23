// Kubernetes插件配置
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://jenkins:8080"
  - name: maven
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: node
    image: node:16-alpine
    command: sleep
    args: infinity
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-cache-pvc
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
        stage('Build Node') {
            steps {
                container('node') {
                    sh 'node --version'
                }
            }
        }
    }
}