// Pipeline注释
/*
 * 这个Pipeline用于构建和部署微服务
 * 流程: Build -> Test -> Deploy to Dev -> Deploy to Prod
 * 作者: DevOps Team
 * 维护者: jenkins-admin@example.com
 */
pipeline {
    // ...
}

// 使用description
stage('Build') {
    steps {
        echo '构建阶段: 编译Java代码'
    }
}