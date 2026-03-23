# Jenkins日志位置
# /var/log/jenkins/jenkins.log

# Docker日志
docker logs jenkins

# 实时查看日志
tail -f /var/log/jenkins/jenkins.log

# 日志级别调整
# Manage Jenkins → System Log → Log Levels
# 添加: org.jenkinsci.plugins all

# 使用jenkins-cli查看日志
java -jar jenkins-cli.jar -s http://localhost:8080 system-log