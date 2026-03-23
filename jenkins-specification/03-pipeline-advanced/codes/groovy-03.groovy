// for循环
node {
    stage('Deploy') {
        def servers = ['dev-server', 'staging-server', 'prod-server']
        for (server in servers) {
            echo "部署到 ${server}"
            sh "./deploy.sh ${server}"
        }
    }
}

// each循环
node {
    stage('Multi-Container Deploy') {
        ['web', 'api', 'worker'].each { service ->
            echo "部署 ${service}"
            sh "./deploy-service.sh ${service}"
        }
    }
}

// while循环
node {
    stage('Retry Loop') {
        def attempts = 0
        while (attempts < 3) {
            try {
                echo "尝试 #${attempts + 1}"
                sh './fragile-script.sh'
                break
            } catch (Exception e) {
                attempts++
                if (attempts >= 3) {
                    throw e
                }
                echo "失败，等待重试..."
                sleep 10
            }
        }
    }
}