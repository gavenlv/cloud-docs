# 方式1: Web界面更新
# Manage Jenkins → Manage Plugins → Updates
# 选择插件，点击 "Download now and install after restart"

# 方式2: 手动上传
# 下载新版.hpi
# Manage Jenkins → Manage Plugins → Advanced → Upload plugin

# 方式3: 命令行
java -jar jenkins-cli.jar \
     -s http://jenkins:8080 \
     -auth user:token \
     install-plugin git -deploy