// Python构建Pipeline
pipeline {
    agent any

    environment {
        VIRTUAL_ENV = '/workspace/venv'
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    python3 -m venv ${VIRTUAL_ENV}
                    . ${VIRTUAL_ENV}/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    pylint src/
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    pytest --junitxml=test-results/junit.xml
                '''
            }
            post {
                always {
                    junit 'test-results/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh '''
                    . ${VIRTUAL_ENV}/bin/activate
                    python setup.py sdist bdist_wheel
                '''
                archiveArtifacts artifacts: 'dist/*', fingerprint: true
            }
        }
    }
}