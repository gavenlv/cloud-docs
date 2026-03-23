# 运行Docker Agent
docker run -d \
  --name jenkins-agent \
  -e JNLP_URL=http://master:8080/computer/docker-agent/slave-agent.jnlp \
  -e JNLP_SECRET=<secret> \
  jenkins/agent:latest