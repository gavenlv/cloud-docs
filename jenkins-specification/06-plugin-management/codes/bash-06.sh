# 版本锁定
# 在Docker中
FROM jenkins/jenkins:lts

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# 定期更新脚本
#!/bin/bash
# update-plugins.sh

JENKINS_URL="http://jenkins:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="your-token"

PLUGINS=("git" "pipeline-stage-view" "blueocean")

for plugin in "${PLUGINS[@]}"; do
    echo "更新插件: $plugin"
    java -jar jenkins-cli.jar \
        -s $JENKINS_URL \
        -auth $JENKINS_USER:$JENKINS_TOKEN \
        install-plugin $plugin
done

echo "重启Jenkins..."
java -jar jenkins-cli.jar \
    -s $JENKINS_URL \
    -auth $JENKINS_USER:$JENKINS_TOKEN \
    safe-restart