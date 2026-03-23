# Dockerfile for Jenkins Agent
FROM openjdk:11-jdk

RUN apt-get update && apt-get install -y \
    git \
    maven \
    gradle \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# 创建jenkins用户
RUN useradd -m -s /bin/bash jenkins && \
    usermod -aG docker jenkins

# 下载jenkins-agent.jar
RUN mkdir -p /usr/share/jenkins && \
    curl -L -o /usr/share/jenkins/agent.jar \
    https://github.com/jenkinsci/remoting/releases/download/agent-4.11/agent.jar

WORKDIR /home/jenkins/agent

# 启动脚本
COPY agent-startup.sh /usr/local/bin/agent-startup.sh
RUN chmod +x /usr/local/bin/agent-startup.sh

ENTRYPOINT ["/usr/local/bin/agent-startup.sh"]