// Jenkinsfile for Multi-branch Pipeline

pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
        }
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '**/target/*.jar'
        }
    }
}

// Jenkinsfile for GitHub Organization
// 自动扫描组织下的所有仓库
organizationFolder {
    name("Example Organization")
    displayName("Example Organization")

    buildStrategies {
        eventTrigger {
            actionType("CREATED")
            actionType("MODIFIED")
        }
    }

    pipelines {
        standard {
            JenkinsfileProvider {
                amongBranches {
                    defaultVersion("master")
                }
            }
        }
    }
}