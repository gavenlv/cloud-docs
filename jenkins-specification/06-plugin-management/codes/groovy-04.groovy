# 常用报告插件

# 1. JUnit
# 测试报告
# 内置
steps {
    junit '**/target/surefire-reports/*.xml'
}

# 2. Cobertura
# 代码覆盖率
# 安装: cobertura
steps {
    cobertura coberturaReportFile: '**/coverage.xml'
}

# 3. JaCoCo
# 代码覆盖率
# 安装: jacoco
steps {
    jacoco execPattern: '**/target/*.exec'
}

# 4. SonarQube
# 代码质量
# 安装: sonar
steps {
    withSonarQubeEnv('sonar') {
        sh 'mvn sonar:sonar'
    }
}