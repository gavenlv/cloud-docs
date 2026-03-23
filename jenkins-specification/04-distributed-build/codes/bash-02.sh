#!/bin/bash
# agent-startup.sh
java -jar /usr/share/jenkins/agent.jar \
    -jnlpUrl $JNLP_URL \
    -secret $JNLP_SECRET \
    -workDir "/home/jenkins/agent"