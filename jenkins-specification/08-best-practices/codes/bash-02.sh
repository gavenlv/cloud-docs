# Jenkins数据备份

# 1. 备份内容
# - JENKINS_HOME (配置、构建历史)
# - 插件
# - 用户数据

# 2. 备份脚本
#!/bin/bash
BACKUP_DIR=/backup/jenkins
JENKINS_HOME=/var/jenkins_home

tar -czf ${BACKUP_DIR}/jenkins-$(date +%Y%m%d).tar.gz \
    ${JENKINS_HOME}

# 3. 恢复
# tar -xzf jenkins-backup.tar.gz -C /var/jenkins_home