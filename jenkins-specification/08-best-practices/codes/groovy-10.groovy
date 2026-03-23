// 1. 使用合适的Agent
pipeline {
    agent {
        label 'docker'  // 使用有Docker的节点
    }
}

// 2. 限制并发
options {
    disableConcurrentBuilds()
}

// 3. 及时清理
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
}

post {
    always {
        cleanWs()
    }
}