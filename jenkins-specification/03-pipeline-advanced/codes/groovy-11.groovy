// 跨多个Agent并行执行
pipeline {
    agent none
    stages {
        stage('Deploy to Multiple Servers') {
            steps {
                script {
                    def servers = [
                        [name: 'server1', ip: '192.168.1.10'],
                        [name: 'server2', ip: '192.168.1.11'],
                        [name: 'server3', ip: '192.168.1.12']
                    ]

                    def deployJobs = [:]

                    servers.each { server ->
                        deployJobs[server.name] = {
                            node('deploy') {
                                stage("Deploy to ${server.name}") {
                                    echo "部署到 ${server.name} (${server.ip})"
                                    sh "./deploy.sh -h ${server.ip}"
                                                        }
                            }
                        }
                    }

                    parallel deployJobs
                }
            }
        }
    }
}