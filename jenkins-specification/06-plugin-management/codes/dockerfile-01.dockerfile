FROM jenkins/jenkins:lts

# 使用jenkins-plugin-cli安装插件
RUN jenkins-plugin-cli \
    --plugins \
    git \
    docker-workflow \
    pipeline-stage-view \
    blueocean \
    slack \
    email-ext

# 或使用plugins.txt
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt