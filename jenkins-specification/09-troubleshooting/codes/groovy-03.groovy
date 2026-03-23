// Jenkins诊断Pipeline
pipeline {
    agent any
    stages {
        stage('System Info') {
            steps {
                script {
                    echo "=== Jenkins信息 ==="
                    echo "Jenkins版本: ${Jenkins.instance.version}"
                    echo "Java版本: ${System.getProperty('java.version')}"
                    echo "工作目录: ${JENKINS_HOME}"
                }
            }
        }

        stage('Agent Status') {
            steps {
                script {
                    def nodes = Jenkins.instance.nodes
                    echo "Agent数量: ${nodes.size()}"
                    nodes.each { node ->
                        echo "Agent: ${node.displayName}, 状态: ${node.to计算机().online ? '在线' : '离线'}"
                    }
                }
            }
        }

        stage('Disk Space') {
            steps {
                sh '''
                    echo "=== 磁盘空间 ==="
                    df -h
                    echo "=== 工作空间 ==="
                    du -sh ${JENKINS_HOME}/workspace/* 2>/dev/null | head -10
                '''
            }
        }

        stage('Memory') {
            steps {
                sh '''
                    echo "=== 内存使用 ==="
                    free -h
                    echo "=== Java进程 ==="
                    ps aux | grep java | grep -v grep
                '''
            }
        }
    }
}