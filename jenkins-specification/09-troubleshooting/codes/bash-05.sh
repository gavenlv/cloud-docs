# 日志
docker logs jenkins
tail -f /var/log/jenkins/jenkins.log

# Agent测试
ssh -i key agent_ip
telnet master 50000

# 磁盘
du -sh ~/.jenkins/workspace/*
df -h

# 内存
free -h
ps aux | grep java