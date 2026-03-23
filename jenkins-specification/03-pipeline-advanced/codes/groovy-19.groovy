// 并行执行
parallel {
    stage('A') { ... }
    stage('B') { ... }
}

// 共享库
@Library('my-lib') _
buildApp 'app', '1.0'

// 人工审批
input message: '确认?', submitter: 'admin'

// 重试
retry(3) {
    sh './fragile.sh'
}