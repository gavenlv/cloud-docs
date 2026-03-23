// input步骤实现人工审批
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                input message: '确认部署?',
                      ok: '确认',
                      submitter: 'admin,dev-lead',
                      parameters: [
                          choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: '环境'),
                          string(name: 'VERSION', defaultValue: '', description: '版本号')
                      ]
                echo '已批准，开始部署'
            }
        }
    }
}

// 完整示例
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo '构建完成'
            }
        }

        stage('Deploy to Staging') {
            steps {
                echo '部署到Staging'
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: '是否部署到生产环境?',
                          ok: '部署',
                          submitter: 'admin,production-team'
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                echo '部署到Production'
            }
        }
    }
}