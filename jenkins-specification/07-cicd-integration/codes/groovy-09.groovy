// 多种Registry配置

// 1. Docker Hub
docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
    def image = docker.build("myusername/myapp:${env.BUILD_NUMBER}")
    image.push()
}

// 2. AWS ECR
pipeline {
    stages {
        stage('Login to ECR') {
            steps {
                script {
                    def ecr = evaluate new Groovy slurper().parseText('{"region":"us-east-1"}')
                    docker.withRegistry("https://${ecr.region}.dkr.ecr.amazonaws.com", 'aws-ecr') {
                        // build and push
                    }
                }
            }
        }
    }
}

// 3. GCR (Google Container Registry)
docker.withRegistry('https://gcr.io', 'gcr-credentials') {
    def image = docker.build("gcr.io/my-project/myapp:${env.BUILD_NUMBER}")
    image.push()
}