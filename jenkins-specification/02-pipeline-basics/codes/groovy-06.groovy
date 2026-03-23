// writeFile: 写入文件
stage('Create Config') {
    steps {
        script {
            writeFile file: 'config.properties', text: '''
                database.url=jdbc:mysql://localhost:3306
                database.user=admin
                database.password=${DB_PASSWORD}
            '''
        }
    }
}

// readFile: 读取文件
stage('Read Config') {
    steps {
        script {
            def config = readFile file: 'config.properties', encoding: 'UTF-8'
            echo config
        }
    }
}

// archiveArtifacts: 存档构建产物
stage('Archive') {
    steps {
        archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
    }
}

// stash/unstash: 跨stage传递文件
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'mvn package'
                stash name: 'jar', includes: '**/target/*.jar'
            }
        }
        stage('Deploy') {
            steps {
                unstash 'jar'
                sh 'deploy.sh'
            }
        }
    }
}