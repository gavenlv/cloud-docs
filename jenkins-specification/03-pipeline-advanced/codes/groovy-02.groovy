// if-else条件
node {
    stage('Build') {
        if (env.BRANCH_NAME == 'main') {
            echo "主分支构建"
            sh 'mvn clean package'
        } else if (env.BRANCH_NAME.startsWith('release/')) {
            echo "发布分支构建"
            sh 'mvn clean release:prepare release:perform'
        } else {
            echo "其他分支构建"
            sh 'mvn clean package -DskipTests'
        }
    }
}

// switch语句
node {
    stage('Deploy') {
        def targetEnv = params.ENVIRONMENT
        switch (targetEnv) {
            case 'dev':
                echo "部署到Dev"
                break
            case 'staging':
                echo "部署到Staging"
                break
            case 'prod':
                echo "部署到Production"
                break
            default:
                error "未知环境: ${targetEnv}"
        }
    }
}