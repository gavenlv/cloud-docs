// when: 条件执行stage

pipeline {
    agent any

    stages {
        stage('Build') {
            when {
                expression { env.BRANCH_NAME != 'production' }
            }
            steps {
                echo 'Building...'
            }
        }

        stage('Deploy Production') {
            when {
                expression { env.BRANCH_NAME == 'production' }
                beforeInput true
            }
            steps {
                echo 'Deploying to Production...'
            }
        }

        stage('Deploy') {
            when {
                allOf {
                    branch 'main'
                    environment name: 'DEPLOY_ENABLED', value: 'true'
                }
            }
            steps {
                echo 'Deploying...'
            }
        }
    }
}

// when条件类型:
// - branch: 分支匹配
// - expression: Groovy表达式
// - environment: 环境变量
// - not: 取反
// - allOf: 全部满足
// - anyOf: 任一满足