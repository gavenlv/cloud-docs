// vars/buildApp.groovy
// 文件名即步骤名

def call(String appName, String version = 'latest') {
    echo "构建应用: ${appName} v${version}"
    sh "mvn clean package -Dapp.name=${appName} -Dapp.version=${version}"
    return true
}

// 使用参数映射
def call(Map config) {
    echo "构建应用: ${config.appName} v${config.version}"
    sh "mvn clean package -Dapp.name=${config.appName}"
    if (config.skipTests) {
        sh "mvn package -DskipTests"
    }
    return true
}