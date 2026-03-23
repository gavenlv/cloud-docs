# 方式1: 使用jenkins-cli.jar
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     install-plugin git pipeline-stage-view blueocean

# 方式2: 复制插件文件
# 下载.hpi文件
cp git.hpi ~/.jenkins/plugins/
systemctl restart jenkins

# 方式3: Docker方式
# 在Dockerfile中
RUN jenkins-plugin-cli --plugins git pipeline-stage-view blueocean