// 启用Webhook触发
// 方式1: 在Pipeline中配置
pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Build') {
            steps {
                echo '收到GitHub推送，开始构建'
            }
        }
    }
}

// 方式2: Generic Webhook Trigger插件
pipeline {
    agent any
    triggers {
        genericTrigger {
            genericVariables {
                genericVariable {
                    value("ref")
                    expression("refs")
                    variable("GIT_BRANCH")
                }
            }
            causeString('Generic Cause')
            token('my-secret-token')
        }
    }
    stages {
        stage('Build') {
            steps {
                echo "分支: ${GIT_BRANCH}"
            }
        }
    }
}

// GitLab配置
triggers {
    gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
}