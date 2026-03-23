// 定时触发
pipeline {
    agent any
    triggers {
        cron('H H(0-8) * * 1-5')  // 工作日0-8点每小时
        cron('H H9 * * *')        // 每天9点
        cron('H/15 * * * *')      // 每15分钟
    }
    stages {
        stage('Daily Build') {
            steps {
                echo '执行每日构建'
            }
        }
    }
}

// GitHub webhook触发
pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Build') {
            steps {
                echo '代码有更新，开始构建'
            }
        }
    }
}