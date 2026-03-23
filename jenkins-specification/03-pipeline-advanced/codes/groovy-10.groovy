// Multi-configuration Pipeline (矩阵构建)
pipeline {
    agent none
    parameters {
        choice(name: 'PLATFORM', choices: ['linux', 'windows', 'mac'], description: '选择平台')
    }
    stages {
        stage('Build') {
            steps {
                script {
                    def platform = params.PLATFORM
                    echo "在 ${platform} 上构建"
                    if (platform == 'linux') {
                        sh './build-linux.sh'
                    } else if (platform == 'windows') {
                        bat 'build-windows.bat'
                    } else {
                        sh './build-mac.sh'
                    }
                }
            }
        }
    }
}

// 使用matrix
pipeline {
    agent none
    stages {
        stage('Test') {
            matrix {
                axes {
                    axis {
                        name 'PLATFORM'
                        values 'linux', 'windows', 'mac'
                    }
                    axis {
                        name 'BROWSER'
                        values 'chrome', 'firefox', 'safari'
                    }
                }
                agent { label "${PLATFORM}" }
                stages {
                    stage('Test') {
                        steps {
                            echo "在 ${PLATFORM} 上测试 ${BROWSER}"
                        }
                    }
                }
            }
        }
    }
}