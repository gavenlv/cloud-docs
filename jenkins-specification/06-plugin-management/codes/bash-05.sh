# 回滚步骤:
# 1. 停止Jenkins
systemctl stop jenkins

# 2. 备份当前插件
cp -r ~/.jenkins/plugins ~/.jenkins/plugins.backup

# 3. 删除问题插件
rm -rf ~/.jenkins/plugins/git.hpi
rm -rf ~/.jenkins/plugins/git/

# 4. 安装旧版本
# 下载旧版本.hpi
cp old-version.hpi ~/.jenkins/plugins/git.hpi

# 5. 重启Jenkins
systemctl start jenkins

# 或者使用插件:
# Install: Prev/Next Plugin Version Manager