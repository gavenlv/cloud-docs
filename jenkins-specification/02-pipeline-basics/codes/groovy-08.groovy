// withCredentials: 使用凭证

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
                    file(
                        credentialsId: 'ssh-key',
                        variable: 'SSH_KEY'
                    )
                ]) {
                    sh '''
                        echo "Deploying with $DB_USER"
                        db-deploy --user $DB_USER --password $DB_PASS
                    '''
                }
            }
        }
    }
}