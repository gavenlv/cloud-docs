// 动态stage
pipeline {
    agent any
    parameters {
        text(name: 'STAGES', defaultValue: 'build,test,deploy', description: '要执行的阶段')
    }
    stages {
        stage('Dynamic Stages') {
            steps {
                script {
                    def stagesList = params.STAGES.split(',')
                    stagesList.each { stageName ->
                        stage(stageName.trim()) {
                            echo "执行阶段: ${stageName}"
                            // 执行对应命令
                        }
                    }
                }
            }
        }
    }
}