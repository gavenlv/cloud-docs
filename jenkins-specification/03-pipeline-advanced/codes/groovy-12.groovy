// script块中使用Groovy代码
pipeline {
    agent any
    stages {
        stage('Script') {
            steps {
                script {
                    // 定义变量
                    def name = "Jenkins"
                    def version = 2.0

                    // 字符串操作
                    def upperName = name.toUpperCase()

                    // JSON处理
                    def json = readJSON text: '{"app": "jenkins"}'
                    echo json.app

                    // 文件操作
                    def content = readFile file: 'config.txt'
                    writeFile file: 'output.txt', text: 'result'

                    // 日期处理
                    def date = new Date()
                    def formatted = date.format('yyyy-MM-dd')

                    echo "Hello ${upperName} v${version} at ${formatted}"
                }
            }
        }
    }
}