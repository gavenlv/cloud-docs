# 问题: 磁盘空间不足
# 原因: 构建产物过多/日志太大

# 诊断:
du -sh ~/.jenkins/workspace/*
du -sh ~/.jenkins/builds/*

# 解决方案:
# 1. 配置构建丢弃策略
pipeline {
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
}

# 2. 清理旧构建
# Manage Jenkins → Manage Nodes → [Node] → Workspace

# 3. 配置日志轮转
# /etc/jenkins/jenkins.model.JenkinsLocation.xml

# 4. 清理插件缓存
rm -rf ~/.jenkins/plugins/*.bak