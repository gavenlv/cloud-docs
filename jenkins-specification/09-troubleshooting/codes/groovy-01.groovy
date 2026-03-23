// 问题: 环境变量未定义
// 错误信息: groovy.lang.MissingPropertyException

// 解决方案:
// 1. 使用env.前缀
echo "${env.BUILD_NUMBER}"

// 2. 检查变量是否存在
if (env.MY_VAR != null) {
    echo env.MY_VAR
}

// 3. 使用??操作符 (Groovy 3+)
echo "${env.MY_VAR ?: 'default'}"

// 问题: 变量作用域错误
// 解决方案:
// 在stages外部定义的变量不能在steps中直接使用
pipeline {
    environment {
        MY_VAR = 'value'  // 这里定义的
    }
    stages {
        stage('Build') {
            steps {
                echo "${env.MY_VAR}"  // 使用env.
            }
        }
    }
}