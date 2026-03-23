// docker插件使用
pipeline {
    agent {
        docker {
            image 'maven:3.8-openjdk-11'
            label 'docker'
            args '-v /root/.m2:/root/.m2'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

// docker.build
stage('Build Image') {
    steps {
        script {
            def image = docker.build("myapp:${env.BUILD_NUMBER}", "-f Dockerfile .")
            docker.withRegistry('https://registry.example.com', 'docker-registry') {
                image.push()
            }
        }
    }
}

// docker.withRegistry
docker.withRegistry('https://registry.example.com', 'docker-credentials') {
    def image = docker.image("myapp:latest")
    image.push()
}