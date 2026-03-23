# 问题: Jenkins OOM
# 原因: JVM内存配置不足

# 解决方案:
# 1. 修改JVM参数
# /etc/default/jenkins
JAVA_ARGS="-Xmx2g -Xms512m"

# 2. Docker方式
docker run -e JAVA_OPTS="-Xmx2g" jenkins/jenkins:lts

# 3. 监控内存使用
jmap -heap <jenkins_pid>