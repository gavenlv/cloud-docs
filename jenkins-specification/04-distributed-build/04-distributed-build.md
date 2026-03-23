# 分布式构建

## 本章导学

**学完本章后，你将能够：**

- 理解Jenkins分布式架构原理
- 掌握Agent配置和管理
- 理解云原生Agent部署

**学习方法：**

```
架构原理 → Agent配置 → 云部署 → 最佳实践
```

---

# 1. 分布式架构原理

## 1.1 Master-Agent架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins分布式架构                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Master                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Jenkins Core                              ││
│  │  - Web Server (8080)                                        ││
│  │  - Build Scheduler                                          ││
│  │  - Plugin Manager                                           ││
│  │  - Security (认证/授权)                                      ││
│  │  - Agent Management                                         ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│                    JNLP / SSH / Kubernetes                      │
└──────────────────────────────┼───────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     Agent 1     │  │     Agent 2     │  │     Agent 3     │
│   (Linux)       │  │   (Windows)     │  │  (Kubernetes)   │
│   标签: linux   │  │   标签: windows │  │   标签: k8s     │
│   Executor: 4   │  │   Executor: 2   │  │   Executor: 10 │
└─────────────────┘  └─────────────────┘  └─────────────────┘

# Master职责:
# - 接收用户请求 (Web UI, API, CLI)
# - 调度构建任务
# - 管理Agent连接
# - 存储构建历史和配置

# Agent职责:
# - 实际执行构建任务
# - 报告执行结果
# - 保持与Master的心跳
```

## 1.2 通信机制

```
┌─────────────────────────────────────────────────────────────────┐
│                    Master-Agent通信机制                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  通信方式对比                                                    │
├─────────────────────────────────────────────────────────────────┤
│ 方式          │ 原理              │ 适用场景                     │
├───────────────┼───────────────────┼────────────────────────────┤
│ JNLP          │ Agent主动连接Master│ 防火墙内, 临时Agent         │
│ SSH           │ Master主动连接Agent│ 有SSH访问权限的服务器       │
│ Kubernetes    │ K8s API创建Pod    │ 云原生环境                  │
│ Docker        │ Docker API创建容器│ 容器化环境                  │
└───────────────┴───────────────────┴────────────────────────────┘

# JNLP通信流程:
# 1. Master生成JNLP文件 (包含连接信息)
# 2. Agent下载并执行jnlp文件
# 3. Agent通过TCP连接到Master的agent端口
# 4. 建立长连接，Agent接收指令

# SSH通信流程:
# 1. Master配置Agent的SSH连接信息
# 2. Master通过SSH连接到Agent
# 3. Master发送构建命令
# 4. Agent执行并返回结果
```

---

# 2. Agent配置

## 2.1 添加Linux Agent (SSH)

```bash
# 1. 在Agent上安装Java
sudo apt update
sudo apt install openjdk-11-jdk

# 2. 创建jenkins用户
sudo useradd -m -s /bin/bash jenkins
sudo mkdir -p /home/jenkins
sudo chown jenkins:jenkins /home/jenkins

# 3. 生成SSH密钥对 (在Master上)
ssh-keygen -t rsa -b 4096 -C "jenkins@master" -f ~/.ssh/jenkins_agent
ssh-copy-id -i ~/.ssh/jenkins_agent.pub jenkins@agent-ip

# 4. 测试SSH连接
ssh -i ~/.ssh/jenkins_agent jenkins@agent-ip
```

```
# 5. 在Jenkins Web界面添加Agent
# Manage Jenkins → Manage Nodes → New Node

# 配置:
# Node Name: linux-agent-1
# Permanent Agent: ✓

# 启动方式:
# Launch agent via SSH
#   Host: agent-ip
#   Credentials: jenkins (SSH with private key)
#   Host Key Verification Strategy: Non verifying Verification Strategy
# Labels: linux docker
# # of executors: 4
# Remote root directory: /home/jenkins/agent
# Usage: Only build jobs with label expressions matching this node
```

## 2.2 添加Windows Agent (JNLP)

```powershell
# 1. 下载Agent jar
# 访问 http://master:8080/jnlpJars/agent.jar

# 2. 创建启动脚本 (agent.bat)
@echo off
java -jar agent.jar ^
    -jnlpUrl http://master:8080/computer/windows-agent01/slave-agent.jnlp ^
    -secret <agent-secret-key> ^
    -workDir "C:\Jenkins\Agent"
```

```powershell
# 3. 作为Windows服务运行
# 下载winsw (Windows Service Wrapper)
# https://github.com/winsw/winsw/releases

# 创建agent.xml
<service>
  <id>jenkins-agent</id>
  <name>Jenkins Agent</name>
  <description>Jenkins Build Agent</description>
  <executable>java.exe</executable>
  <arguments>-jar agent.jar -jnlpUrl http://master:8080/computer/windows-agent01/slave-agent.jnlp -secret <secret></arguments>
  <logmode>rotate</logmode>
</service>

# 安装服务
agent.exe install
agent.exe start
```

## 2.3 Docker Agent

```dockerfile
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
```

```bash
#!/bin/bash
# agent-startup.sh
java -jar /usr/share/jenkins/agent.jar \
    -jnlpUrl $JNLP_URL \
    -secret $JNLP_SECRET \
    -workDir "/home/jenkins/agent"
```

```bash
# 运行Docker Agent
docker run -d \
  --name jenkins-agent \
  -e JNLP_URL=http://master:8080/computer/docker-agent/slave-agent.jnlp \
  -e JNLP_SECRET=<secret> \
  jenkins/agent:latest
```

---

# 3. Kubernetes Agent

## 3.1 Kubernetes插件配置

```groovy
// Kubernetes插件配置
pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://jenkins:8080"
  - name: maven
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: node
    image: node:16-alpine
    command: sleep
    args: infinity
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-cache-pvc
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn --version'
                }
            }
        }
        stage('Build Node') {
            steps {
                container('node') {
                    sh 'node --version'
                }
            }
        }
    }
}
```

## 3.2 Kubernetes Agent配置

```yaml
# Jenkins Master的Kubernetes配置
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins
  namespace: jenkins
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec", "services"]
  verbs: ["*"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins
  namespace: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 10Gi
```

## 3.3 动态Agent配置

```groovy
// 动态创建和销毁Agent
pipeline {
    agent {
        kubernetes {
            label 'dynamic-agent'
            defaultContainer 'jnlp'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
  - name: builder
    image: maven:3.8-openjdk-11
    command: sleep
    args: infinity
'''
        }
    }
    stages {
        stage('Build') {
            steps {
                container('builder') {
                    sh 'mvn clean package'
                }
            }
        }
    }
    // 构建完成后自动销毁Pod
    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
}
```

---

# 4. Agent管理

## 4.1 标签和用法

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent标签和使用策略                           │
└─────────────────────────────────────────────────────────────────┘

# 标签 (Label):
# - 用于标识Agent特性
# - 在Pipeline中指定执行位置

# 标签示例:
# - linux, windows, mac
# - docker, kubernetes
# - java, nodejs, python
# - high-memory, gpu

# 使用策略:
┌─────────────────────────────────────────────────────────────────┐
│ 策略                          │ 说明                            │
├───────────────────────────────┼─────────────────────────────────┤
│ 尽可能使用此节点               │ 默认策略，可以使用任何节点      │
│ 只允许绑定到此节点的任务        │ 仅当明确指定时才使用            │
│ 只运行绑定到此节点的任务        │ 更严格的限制                    │
└───────────────────────────────┴─────────────────────────────────┘

# 配置:
# Manage Jenkins → Manage Nodes → [Node] → Configure

# 配置选项:
# Labels: linux docker java
# # of executors: 4
# Usage: Only build jobs with label expressions matching this node
```

## 4.2 节点配置参数

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent配置参数                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 配置项                  │ 说明                                    │
├─────────────────────────┼───────────────────────────────────────┤
│ # of executors          │ 并行执行数                             │
│ Remote root directory   │ Agent工作目录                         │
│ Labels                  │ 标签列表                               │
│ Usage                   │ 使用策略                               │
│ Launch method           │ 启动方式 (SSH/JNLP/Kubernetes)         │
│ Availability            │ 可用性 (在线/保持离线/按需)            │
└─────────────────────────┴───────────────────────────────────────┘

# Launch method:
# - Launch agent by connecting to the master (JNLP)
# - Launch agent via SSH
# - Launch agents by connecting it to the master via Java Web Start
# - Let Jenkins control this Windows agent as a Windows service

# Availability:
# - Keep this agent online as much as possible
# - Take this agent online when in demand, and offline when idle
# - Bring this agent online when there's work, and leave it offline when it's idle
```

## 4.3 动态 Provisioning

```groovy
// Cloud配置实现动态伸缩
// Manage Jenkins → Manage Nodes → Configure Clouds

// Amazon EC2配置示例:
cloud {
    amazonEC2 {
        region('us-east-1')
        instanceCapStr('10')
        iamCredentialId('aws-credentials')
        templates {
            amazonEC2 {
                label('ec2-linux')
                ami('ami-12345678')
                zone('us-east-1a')
                instanceType('t3.medium')
                sshCredentialId('ssh-credentials')
                numExecutors(2)
                remoteFS('/home/jenkins')
                initScript('''
                    #!/bin/bash
                    apt-get update
                    apt-get install -y openjdk-11-jdk maven git
                ''')
            }
        }
    }
}
```

---

# 5. 负载均衡

## 5.1 调度策略

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins调度策略                               │
└─────────────────────────────────────────────────────────────────┘

# Jenkins调度流程:
# 1. 任务入队
# 2. 选择合适的Agent (标签匹配)
# 3. 分配Executor
# 4. 执行构建

# 调度考虑因素:
# - 标签匹配
# - Executor可用性
# - 负载均衡
# - 亲和性/反亲和性

# 负载均衡算法:
# - Least Recently Used (默认)
# - Round Robin
# - Request Idle Count
```

## 5.2 亲和性配置

```groovy
// Node亲和性
pipeline {
    agent {
        label 'docker' && !'windows'
    }
    stages {
        stage('Build') {
            steps {
                echo '在Linux Docker节点上构建'
            }
        }
    }
}

// 多标签要求
pipeline {
    agent {
        label 'linux && docker && (java || nodejs)'
    }
    stages {
        stage('Build') {
            steps {
                echo '在满足条件的节点上构建'
            }
        }
    }
}
```

## 5.3 资源隔离

```groovy
// 使用workspace实现隔离
pipeline {
    agent none
    stages {
        stage('Build') {
            agent {
                label 'linux'
                customWorkspace '/home/jenkins/workspace/${JOB_NAME}'
            }
            steps {
                echo "工作空间: ${env.WORKSPACE}"
            }
        }
    }
}

// 并行构建隔离
pipeline {
    agent any
    stages {
        stage('Parallel Build') {
            parallel {
                stage('App1') {
                    agent { label 'linux' }
                    steps {
                        dir('app1') {
                            sh 'mvn package'
                        }
                    }
                }
                stage('App2') {
                    agent { label 'linux' }
                    steps {
                        dir('app2') {
                            sh 'mvn package'
                        }
                    }
                }
            }
        }
    }
}
```

---

## 本章小结

- **Master-Agent架构**实现构建任务的分布式执行
- **通信方式**: SSH、JNLP、Kubernetes、Docker
- **标签**用于标识Agent特性，实现任务分配
- **Kubernetes插件**支持在K8s集群中动态创建Agent
- **负载均衡**通过标签匹配和调度策略实现

**关键配置:**

```bash
# Agent启动方式
# SSH: Master主动连接Agent
# JNLP: Agent主动连接Master
# Kubernetes: 通过K8s API创建Pod
```