// sh: 执行Shell命令

stage('Build') {
    steps {
        sh 'echo Hello'
        sh '''
            echo "Multi-line"
            mvn clean package
        '''
        sh label: 'Build', script: '''
            echo "Building ${VERSION}"
            mvn clean package -DskipTests=false
        '''
    }
}

// bat: 执行Windows批处理
stage('Windows Build') {
    steps {
        bat 'dir'
        bat '''
            echo Building
            mvn clean package
        '''
    }
}

// powershell: 执行PowerShell
stage('PowerShell') {
    steps {
        powershell '''
            Write-Host "Hello from PowerShell"
            Get-Process
        '''
    }
}

// error: 抛出异常
stage('Example') {
    steps {
        script {
            if (env.BUILD_NUMBER > 100) {
                error "Build number too high"
            }
        }
    }
}