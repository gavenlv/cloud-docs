# 常见错误处理

## 本章导学

**学完本章后，你将能够：**

- 诊断和解决常见Jenkins问题
- 处理Pipeline执行错误
- 解决分布式构建问题

**学习方法：**

```
问题现象 → 诊断步骤 → 解决方案
```

---

# 1. Pipeline错误

## 1.1 语法错误

```
┌─────────────────────────────────────────────────────────────────┐
│                    Pipeline语法错误                               │
└─────────────────────────────────────────────────────────────────┘

# 问题1: Groovy语法错误
# 错误信息: org.codehaus.groovy.control.MultipleCompilationErrorsException

# 常见原因:
# - 缺少括号或引号
# - 缩进错误
# - 变量未定义

# 解决方案:
# 1. 检查Groovy语法
# 2. 使用IDE插件验证
# 3. 在Sandbox中测试

# 问题2: 步骤不存在
# 错误信息: No such DSL method 'XXX'

# 解决方案:
# 1. 检查插件是否安装
# 2. 确认步骤名称正确
# 3. 检查DSL方法签名
```

## 1.2 凭证错误

```
# 问题: 凭证不存在
# 错误信息: Credentials 'xxx' does not exist

# 解决方案:
# 1. 确认credentialsId正确
# 2. 检查凭证是否在正确的域
# 3. 重新创建凭证

# 问题: 凭证无法解密
# 错误信息: Failed to decrypt

# 解决方案:
# 1. 检查Jenkins加密密钥
# 2. 重新配置凭证
# 3. 检查Java版本兼容性
```

## 1.3 环境变量错误

```groovy
// 问题: 环境变量未定义
// 错误信息: groovy.lang.MissingPropertyException

// 解决方案:
// 1. 使用env.前缀
echo "${env.BUILD_NUMBER}"

// 2. 检查变量是否存在
if (env.MY_VAR != null) {
    echo env.MY_VAR
}

// 3. 使用??操作符 (Groovy 3+)
echo "${env.MY_VAR ?: 'default'}"

// 问题: 变量作用域错误
// 解决方案:
// 在stages外部定义的变量不能在steps中直接使用
pipeline {
    environment {
        MY_VAR = 'value'  // 这里定义的
    }
    stages {
        stage('Build') {
            steps {
                echo "${env.MY_VAR}"  // 使用env.
            }
        }
    }
}
```

---

# 2. Agent问题

## 2.1 Agent连接失败

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent连接问题                                 │
└─────────────────────────────────────────────────────────────────┘

# 问题1: SSH连接失败
# 错误信息: java.io.IOException: SSH connections

# 诊断:
# 1. 检查SSH服务
ssh agent_ip

# 2. 检查SSH密钥
cat ~/.ssh/jenkins_agent.pub

# 3. 检查Agent日志
# Agent端: java -jar agent.jar -jnlpUrl ... -text

# 解决方案:
# 1. 配置正确的SSH凭证
# 2. 添加Host Key Verification Strategy
# 3. 检查防火墙

# 问题2: JNLP连接失败
# 错误信息: Agent is required to remain connected

# 诊断:
# 1. 检查Master端口
# Manage Jenkins → Configure Global Security → Agents

# 2. 检查防火墙
telnet master 50000

# 解决方案:
# 1. 确保Agent端口可达
# 2. 配置正确的JNLP URL
# 3. 检查代理设置
```

## 2.2 Agent离线

```
# 问题: Agent突然离线

# 诊断:
# 1. 检查Agent进程
ps aux | grep jenkins

# 2. 检查网络连接
ping agent_ip

# 3. 查看Agent日志

# 解决方案:
# 1. 重启Agent服务
# 2. 检查资源使用 (CPU/内存/磁盘)
# 3. 调整超时设置
```

## 2.3 Executor问题

```
# 问题: 没有可用的Executor
# 错误信息: No executors

# 诊断:
# 1. 检查Executor数量
# Manage Jenkins → Manage Nodes → [Node] → Configure

# 2. 检查使用策略

# 解决方案:
# 1. 增加Executor数量
# 2. 修改使用策略
# 3. 添加更多Agent
```

---

# 3. 构建问题

## 3.1 构建失败

```
┌─────────────────────────────────────────────────────────────────┐
│                    构建失败排查                                  │
└─────────────────────────────────────────────────────────────────┘

# 诊断步骤:
# 1. 查看控制台输出
# Job → Build History → [Build] → Console Output

# 2. 查看日志
# Manage Jenkins → System Log

# 3. 检查环境
# 添加调试步骤
steps {
    sh 'env | sort'
    sh 'pwd'
    sh 'ls -la'
}
```

## 3.2 常见构建错误

```bash
# 错误1: Maven构建失败
# 原因: 依赖下载失败/编译错误

# 解决方案:
# 1. 使用本地仓库
# 2. 清理并重试
sh 'mvn clean package'

# 3. 检查Maven设置
cat ~/.m2/settings.xml

# 错误2: Git检出失败
# 原因: 仓库不存在/权限不足/分支不存在

# 解决方案:
# 1. 检查仓库URL
git ls-remote https://github.com/example/repo.git

# 2. 检查凭证
# Manage Jenkins → Credentials

# 3. 检查分支名称
git branch -a

# 错误3: Docker构建失败
# 原因: Dockerfile错误/上下文问题

# 解决方案:
# 1. 检查Dockerfile语法
# 2. 检查.dockerignore
# 3. 使用构建日志
docker build -t myapp . --progress=plain
```

## 3.3 超时问题

```groovy
// 问题: 构建超时
// 错误信息: Execution expired

// 解决方案:
# 1. 增加超时时间
pipeline {
    options {
        timeout(time: 2, unit: 'HOURS')
    }
}

# 2. 步骤级别超时
steps {
    timeout(time: 30, unit: 'MINUTES') {
        sh './long-task.sh'
    }
}

# 3. 检查是否有死锁
```

---

# 4. 插件问题

## 4.1 插件加载失败

```
# 问题: 插件无法加载
# 错误信息: Failed to load plugin

# 诊断:
# 1. 查看插件状态
# Manage Jenkins → Manage Plugins → Installed

# 2. 查看日志
# Manage Jenkins → System Log → All Log Entries

# 解决方案:
# 1. 检查依赖插件
# 2. 升级/降级版本
# 3. 重新安装
```

## 4.2 插件冲突

```
# 问题: 插件冲突导致问题

# 诊断:
# 1. 禁用所有插件
# 2. 逐个启用

# 解决方案:
# 1. 识别冲突插件
# 2. 升级/降级版本
# 3. 替换功能重复的插件
```

---

# 5. 性能问题

## 5.1 Jenkins响应慢

```
┌─────────────────────────────────────────────────────────────────┐
│                    性能问题排查                                  │
└─────────────────────────────────────────────────────────────────┘

# 问题1: Jenkins首页加载慢
# 原因: 构建历史太多/插件问题

# 解决方案:
# 1. 限制构建历史
# Manage Jenkins → Configure System
# Build History Max: 100

# 2. 禁用不需要的插件
# 3. 增加JVM内存

# 问题2: Pipeline执行慢
# 原因: Agent性能不足/网络延迟

# 解决方案:
# 1. 增加Executor
# 2. 使用更好的Agent
# 3. 优化Pipeline
```

## 5.2 磁盘空间问题

```bash
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
```

## 5.3 内存问题

```bash
# 问题: Jenkins OOM
# 原因: JVM内存配置不足

# 解决方案:
# 1. 修改JVM参数
# /etc/default/jenkins
JAVA_ARGS="-Xmx2g -Xms512m"

# 2. Docker方式
docker run -e JAVA_OPTS="-Xmx2g" jenkins/jenkins:lts

# 3. 监控内存使用
jmap -heap <jenkins_pid>
```

---

# 6. 安全问题

## 6.1 认证问题

```
# 问题: 用户无法登录
# 原因: 认证配置错误/LDAP问题

# 诊断:
# 1. 检查安全配置
# Manage Jenkins → Configure Global Security

# 2. 查看日志

# 解决方案:
# 1. 临时禁用安全模式进行排查
# Manage Jenkins → Configure Global Security
# Enable security: ✗

# 2. 恢复默认认证
# 使用Jenkins CLI重置
java -jar jenkins-cli.jar -s http://localhost:8080 reset-admin
```

## 6.2 权限问题

```
# 问题: 用户权限不足
# 错误信息: user is missing the Overall/Read permission

# 解决方案:
# 1. 配置矩阵权限
# Manage Jenkins → Configure Global Security → Authorization
# Matrix-based security

# 2. 添加用户权限
```

---

# 7. 工具和脚本

## 7.1 诊断脚本

```groovy
// Jenkins诊断Pipeline
pipeline {
    agent any
    stages {
        stage('System Info') {
            steps {
                script {
                    echo "=== Jenkins信息 ==="
                    echo "Jenkins版本: ${Jenkins.instance.version}"
                    echo "Java版本: ${System.getProperty('java.version')}"
                    echo "工作目录: ${JENKINS_HOME}"
                }
            }
        }

        stage('Agent Status') {
            steps {
                script {
                    def nodes = Jenkins.instance.nodes
                    echo "Agent数量: ${nodes.size()}"
                    nodes.each { node ->
                        echo "Agent: ${node.displayName}, 状态: ${node.to计算机().online ? '在线' : '离线'}"
                    }
                }
            }
        }

        stage('Disk Space') {
            steps {
                sh '''
                    echo "=== 磁盘空间 ==="
                    df -h
                    echo "=== 工作空间 ==="
                    du -sh ${JENKINS_HOME}/workspace/* 2>/dev/null | head -10
                '''
            }
        }

        stage('Memory') {
            steps {
                sh '''
                    echo "=== 内存使用 ==="
                    free -h
                    echo "=== Java进程 ==="
                    ps aux | grep java | grep -v grep
                '''
            }
        }
    }
}
```

## 7.2 日志查看

```bash
# Jenkins日志位置
# /var/log/jenkins/jenkins.log

# Docker日志
docker logs jenkins

# 实时查看日志
tail -f /var/log/jenkins/jenkins.log

# 日志级别调整
# Manage Jenkins → System Log → Log Levels
# 添加: org.jenkinsci.plugins all

# 使用jenkins-cli查看日志
java -jar jenkins-cli.jar -s http://localhost:8080 system-log
```

---

## 本章小结

- **Pipeline错误**: 语法错误、凭证问题、环境变量
- **Agent问题**: 连接失败、离线、Executor不足
- **构建问题**: 失败排查、超时处理
- **插件问题**: 加载失败、冲突
- **性能问题**: 响应慢、磁盘空间、内存

**诊断命令:**

```bash
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
```