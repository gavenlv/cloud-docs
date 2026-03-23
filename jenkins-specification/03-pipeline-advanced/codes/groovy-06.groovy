// vars/deployApp.groovy

def call(String environment, String appName) {
    pipeline {
        agent any
        stages {
            stage("Deploy to ${environment}") {
                steps {
                    script {
                        echo "部署 ${appName} 到 ${environment}"
                        sh "./deploy.sh -e ${environment} -a ${appName}"
                    }
                }
            }
        }
    }
}