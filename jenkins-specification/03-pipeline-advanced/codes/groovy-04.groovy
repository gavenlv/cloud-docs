// try-catch-finally
node {
    stage('Deploy') {
        try {
            echo "执行部署"
            sh './deploy.sh'

        } catch (Exception e) {
            echo "部署失败: ${e.message}"
            currentBuild.result = 'FAILURE'
            throw e

        } finally {
            echo "清理工作"
            sh './cleanup.sh'
        }
    }
}

// timeout超时处理
node {
    stage('Long Running') {
        timeout(time: 30, unit: 'MINUTES') {
            echo "执行长时间任务"
            sh './long-running-task.sh'
        }
    }
}