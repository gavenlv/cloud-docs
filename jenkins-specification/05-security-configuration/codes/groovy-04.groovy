// 项目级别权限配置
// 在Job配置中启用: Enable project-based security

// Pipeline中配置
pipeline {
    agent any

    options {
        buildAuthorizationMatrix {
            permissions([
                'hudson.model.Item.Build:jane',
                'hudson.model.Item.Configure:jane',
                'hudson.model.Item.Read:john'
            ])
        }
    }

    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}