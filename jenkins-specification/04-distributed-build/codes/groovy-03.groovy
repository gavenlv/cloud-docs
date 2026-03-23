// Cloud配置实现动态伸缩
// Manage Jenkins → Manage Nodes → Configure Clouds

// Amazon EC2配置示例:
cloud {
    amazonEC2 {
        region('us-east-1')
        instanceCapStr('10')
        iamCredentialId('aws-credentials')
        templates {
            amazonEC2 {
                label('ec2-linux')
                ami('ami-12345678')
                zone('us-east-1a')
                instanceType('t3.medium')
                sshCredentialId('ssh-credentials')
                numExecutors(2)
                remoteFS('/home/jenkins')
                initScript('''
                    #!/bin/bash
                    apt-get update
                    apt-get install -y openjdk-11-jdk maven git
                ''')
            }
        }
    }
}