# 查看插件依赖
# Manage Jenkins → Manage Plugins → Installed
# 点击插件查看详情

# 使用jenkins-cli
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     list-plugins

# 查看特定插件信息
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     get-plugin git