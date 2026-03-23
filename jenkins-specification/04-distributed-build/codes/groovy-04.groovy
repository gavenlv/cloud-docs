// Node亲和性
pipeline {
    agent {
        label 'docker' && !'windows'
    }
    stages {
        stage('Build') {
            steps {
                echo '在Linux Docker节点上构建'
            }
        }
    }
}

// 多标签要求
pipeline {
    agent {
        label 'linux && docker && (java || nodejs)'
    }
    stages {
        stage('Build') {
            steps {
                echo '在满足条件的节点上构建'
            }
        }
    }
}