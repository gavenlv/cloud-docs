// 方式1: Web界面创建
// Manage Jenkins → Security → Credentials → System → Add Credentials

// 方式2: Pipeline中使用
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'db-credentials',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    ),
                    string(
                        credentialsId: 'api-key',
                        variable: 'API_KEY'
                    ),
                    sshUserPrivateKey(
                        credentialsId: 'ssh-key',
                        usernameVariable: 'SSH_USER',
                        privateKeyVariable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        echo "用户: $DB_USER"
                        db-deploy --user $DB_USER --password $DB_PASS
                    '''
                }
            }
        }
    }
}