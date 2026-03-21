# Zookeeper基础和核心原理

## 1.1 Zookeeper简介

### 1.1.1 Zookeeper的核心概念

```
Zookeeper的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper是什么？                                        │
└─────────────────────────────────────────────────────────────────┘

Zookeeper是一个分布式协调服务，主要用于：

1. 核心定位
   ├── 分布式协调服务
   ├── 配置管理
   ├── 命名服务
   ├── 分布式锁
   ├── 服务发现
   └── 集群管理

2. 主要特点
   ├── 简单：简单的数据模型
   ├── 高可用：基于Zab协议保证一致性
   ├── 顺序访问：提供全局有序的请求处理
   ├── 高性能：内存存储，低延迟
   └── 可靠：支持事务，快速故障恢复

3. 应用场景
   ├── Hadoop：NameNode高可用
   ├── Kafka：Broker元数据管理
   ├── Dubbo：服务注册与发现
   ├── Solr：Leader选举
   └── 分布式锁实现
```

### 1.1.2 Zookeeper的基本概念

```
Zookeeper的基本概念：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper基本概念                                    │
└─────────────────────────────────────────────────────────────────┘

1. 集群角色
   ├── Leader：处理所有写请求，事务提案发起者
   ├── Follower：处理读请求，参与投票和Leader选举
   ├── Observer：不参与投票，只处理读请求，用于扩展集群
   └── Learner：Follower和Observer的统称

2. 数据模型
   ├── 层次化命名空间：类似文件系统的树形结构
   ├── ZNode：数据节点，每个ZNode可以存储少量数据
   ├── Session：客户端会话，基于TCP长连接
   └── Watch：事件监听机制，一次性触发

3. Zab协议
   ├── Zookeeper Atomic Broadcast
   ├── 保证分布式环境中操作的原子性
   ├── 两种模式：恢复模式（Leader选举）和广播模式（同步）
   └── 保障强一致性

4. 请求类型
   ├── 读请求：任意Server直接处理
   ├── 写请求：转发给Leader处理
   ├── 连接请求：建立Session
   └── 监听请求：设置Watch
```

---

## 1.2 Zookeeper底层原理

### 1.2.1 Zab协议原理

```
Zab协议原理：

┌─────────────────────────────────────────────────────────────────┐
│  Zab协议原理                                            │
└─────────────────────────────────────────────────────────────────┘

Zab协议是Zookeeper的核心协议，包括两种模式：

1. 恢复模式（Leader选举）
   ├── 触发条件：Leader崩溃或网络分区
   ├── 选举算法：FastLeaderElection
   ├── 选举原则：
   │   ├── 优先比较Epoch（选举轮次）
   │   ├── 其次比较ZXID（事务ID）
   │   └── 最后比较ServerID（服务器ID）
   └── 选举过程：
       ├── Server状态变为Looking
       ├── 发送投票（Epoch, ZXID, ServerID）
       ├── 接收投票并比较
       └── 更新自己的投票

2. 广播模式（消息同步）
   ├── Leader接收客户端请求
   ├── 生成Proposal（提案）
   ├── 发送给所有Follower
   ├── Follower发送ACK
   ├── Leader收到过半ACK后提交
   └── 通知Follower提交

3. Zab协议保证
   ├── 可靠提交：只要Leader提交了，所有Server最终都会提交
   ├── 全局有序：所有请求按照发起顺序处理
   ├── 因果有序：来自同一个Leader的请求按顺序处理
   └── 领导优先：Leader宕机恢复后可以追上最新的事务
```

### 1.2.2 Leader选举原理

```
Leader选举原理：

┌─────────────────────────────────────────────────────────────────┐
│  Leader选举原理                                        │
└─────────────────────────────────────────────────────────────────┘

Leader选举是Zookeeper保证高可用的核心机制：

1. 选举触发条件
   ├── 服务启动时
   ├── Leader崩溃时
   ├── Follower无法连接Leader时
   └── Observer无法连接Leader时

2. 投票内容
   ├── Epoch：选举轮次，每选举一次+1
   ├── ZXID：事务ID，高32位为Epoch，低32位为事务计数器
   ├── ServerID：服务器ID，配置文件中的myid
   └── Server状态：LOOKING, LEADING, FOLLOWING

3. 选举算法（FastLeaderElection）
   步骤1：Server状态变为LOOKING
   步骤2：生成投票（Epoch, ZXID, ServerID, 0）
   步骤3：发送投票给所有其他Server
   步骤4：接收其他Server的投票
   步骤5：比较投票
   步骤6：更新自己的投票（如果收到的投票更优）
   步骤7：再次发送投票
   步骤8：统计投票，当过半Server投票相同时选举完成

4. 选举规则
   规则1：Epoch大的优先
   规则2：Epoch相等时，ZXID大的优先
   规则3：Epoch和ZXID都相等时，ServerID大的优先

5. 选举示例
   场景：3台Server（S1, S2, S3）启动
   S1启动：投票给自己，状态LOOKING
   S2启动：投票给自己，收到S1的投票
   比较：S2的Epoch和ZXID与S1相同，ServerID S2>S1
   结果：S2赢得选举，成为Leader
   S3启动：收到S2的投票，S2已经是Leader
   结果：S3成为Follower
```

### 1.2.3 数据同步原理

```
数据同步原理：

┌─────────────────────────────────────────────────────────────────┐
│  数据同步原理                                        │
└─────────────────────────────────────────────────────────────────┘

Leader和Follower之间的数据同步机制：

1. 同步类型
   ├── DIFF同步：差异同步，只需同步差异部分
   ├── TRUNC同步：回滚同步，删除多余的事务
   ├── SNAP同步：快照同步，全量同步数据
   └── UPTODATE同步：确认同步，表示同步完成

2. 同步时机
   ├── Follower连接Leader时
   ├── Leader选举完成后
   ├── Follower处理完所有事务后

3. 同步流程
   步骤1：Follower连接Leader，注册LearnerCnxAcceptor
   步骤2：Leader注册Follower，获取Follower的ZXID
   步骤3：Leader发送数据包（DIFF/SNAP）
   步骤4：Follower接收并处理数据包
   步骤5：Follower发送ACK
   步骤6：Leader发送UPTODATE
   步骤7：Follower切换到正常状态

4. 同步优化
   ├── 采用TCP协议传输
   ├── 采用队列异步处理
   ├── 支持批量传输
   └── 支持压缩传输

5. 数据一致性保证
   ├── Leader提交的事务一定被所有Server接受
   ├── 未提交的事务不会被任何Server应用
   ├── 读请求可以直接在任意Server处理
   └── 写请求必须通过Leader处理
```

---

## 1.3 Zookeeper安装和配置

### 1.3.1 单机安装

```bash
# 单机安装Zookeeper

# 1. 下载Zookeeper
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz

# 2. 解压
tar -xzf apache-zookeeper-3.8.0-bin.tar.gz

# 3. 进入目录
cd apache-zookeeper-3.8.0-bin

# 4. 复制配置文件
cp conf/zoo_sample.cfg conf/zoo.cfg

# 5. 创建数据目录
mkdir -p /tmp/zookeeper

# 6. 修改配置文件
cat > conf/zoo.cfg << 'EOF'
tickTime=2000
dataDir=/tmp/zookeeper
clientPort=2181
initLimit=10
syncLimit=5
EOF

# 7. 启动Zookeeper
bin/zkServer.sh start

# 8. 检查状态
bin/zkServer.sh status

# 预期输出：
# Using config: /path/to/apache-zookeeper-3.8.0-bin/bin/../conf/zoo.cfg
# Starting zookeeper ... STARTED
# Mode: standalone

# 9. 连接Zookeeper
bin/zkCli.sh

# 预期输出：
# Connecting to localhost:2181
# Welcome to ZooKeeper!
# JLine support is enabled
# [zk: localhost:2181(CONNECTED) 0]
```

### 1.3.2 配置文件详解

```bash
# 配置文件详解

# zoo.cfg配置项说明
cat > conf/zoo.cfg << 'EOF'
# tickTime：通信心跳时间（毫秒）
# 用于Leader-Follower之间的心跳检测
tickTime=2000

# dataDir：数据快照目录
# 存储内存数据快照和事务日志
dataDir=/tmp/zookeeper

# clientPort：客户端连接端口
clientPort=2181

# initLimit：初始化连接超时（tickTime倍数）
# Follower连接Leader并同步数据的最大等待时间
initLimit=10

# syncLimit：同步超时（tickTime倍数）
# Follower与Leader同步的最大等待时间
syncLimit=5

# maxClientCnxns：单个客户端最大连接数
# 防止单个客户端占用过多连接
maxClientCnxns=60

# autopurge.snapRetainCount：保留的快照数量
# 自动清理时保留的快照文件数量
autopurge.snapRetainCount=3

# autopurge.purgeInterval：自动清理间隔（小时）
# 定时清理任务执行间隔
autopurge.purgeInterval=1

# admin.enableServer：是否启用Admin服务
admin.enableServer=true
admin.serverPort=8080
EOF

# myid配置（集群必需）
# 在dataDir目录下创建myid文件
# myid文件内容为ServerID（数字）
echo "1" > /tmp/zookeeper/myid
```

### 1.3.3 启动和停止

```bash
# 启动和停止Zookeeper

# 启动Zookeeper
bin/zkServer.sh start

# 预期输出：
# Starting zookeeper ... STARTED

# 停止Zookeeper
bin/zkServer.sh stop

# 预期输出：
# Stopping zookeeper ... STOPPED

# 重启Zookeeper
bin/zkServer.sh restart

# 检查状态
bin/zkServer.sh status

# 预期输出（单机）：
# Mode: standalone

# 预期输出（集群）：
# Mode: leader 或 Mode: follower

# 前台启动（调试用）
bin/zkServer.sh start-foreground

# 查看日志
tail -f /tmp/zookeeper/zookeeper.log

# 使用JMX管理
bin/zkServer.sh start \
  -Djmx.remoting.authenticator.disabled=true \
  -Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.authenticate=false
```

---

## 1.4 实战：配置Zookeeper

### 1.4.1 配置参数调优

```bash
# 配置参数调优

# 创建优化的配置文件
cat > conf/zoo.cfg << 'EOF'
# 基本配置
tickTime=2000
dataDir=/tmp/zookeeper
clientPort=2181

# 集群配置
initLimit=10
syncLimit=5

# 连接配置
maxClientCnxns=60

# 自动清理配置
autopurge.snapRetainCount=3
autopurge.purgeInterval=1

# 预分配日志配置
autopurge.snapRetainCount=10
preAllocSize=65536

# 快照配置
snapCount=100000

# 日志文件大小配置
maxLogFiles=20
maxLogFileSize=100MB

# 性能优化配置
dynamicConfigFile=/path/to/zoo.cfg.dynamic

# Admin服务配置
admin.enableServer=true
admin.serverPort=8080
EOF

# JVM配置
cat > conf/java.env << 'EOF'
export JVMFLAGS="-Xms1024m -Xmx1024m -Dcom.sun.management.jmxremote"
export SERVER_JVMFLAGS="-Xms1024m -Xmx1024m"
export CLIENT_JVMFLAGS="-Xms256m -Xmx256m"
EOF
```

### 1.4.2 环境变量配置

```bash
# 环境变量配置

# 创建zookeeper-env.sh
cat > conf/zookeeper-env.sh << 'EOF'
#!/bin/bash

# Zookeeper JMX配置
JMXAUTH=false
JMXDISABLE=false
JMXPORT=9999
JMXHOSTNAME=localhost

# Zookeeper日志配置
ZOO_LOG_DIR=/var/log/zookeeper
ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"

# Zookeeper JVM配置
ZOO_OPTS="-Xms1024m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=20"
ZOO_ADMINSERVER_OPTS="-Xms256m -Xmx256m"
EOF

# 创建log4j配置
cat > conf/log4j.properties << 'EOF'
# Zookeeper日志配置
log4j.rootLogger=INFO, CONSOLE, ROLLINGFILE

# 控制台输出
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=INFO
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# 文件输出
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=INFO
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}
log4j.appender.ROLLINGFILE.MaxFileSize=100MB
log4j.appender.ROLLINGFILE.MaxBackupIndex=10
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
```

### 1.4.3 四字命令配置

```bash
# 四字命令配置

# 在zoo.cfg中添加四字命令配置
cat >> conf/zoo.cfg << 'EOF'

# 四字命令配置
4lw.commands.whitelist=*

# 或指定允许的命令
4lw.commands.whitelist=conf,cons,crst,dirs,dump,envi,ruok,stat,srst,trck,mntr,wchs
EOF

# 四字命令示例

# 连接Zookeeper
echo "ruok" | nc localhost 2181

# 预期输出：
# imok

# 查看服务器状态
echo "stat" | nc localhost 2181

# 预期输出：
# ZooKeeper version: 3.8.0
# Latency min/avg/max: 0/0/0
# Received: 1
# Sent: 0
# Connections: 1
# Outstanding: 0
# Zxid: 0x0
# Mode: standalone
# Node count: 5

# 查看服务器配置
echo "conf" | nc localhost 2181

# 预期输出：
# clientPort=2181
# dataDir=/tmp/zookeeper/version-2
# dataLogDir=/tmp/zookeeper/version-2
# tickTime=2000
# maxClientCnxns=60
# minSessionTimeout=4000
# maxSessionTimeout=40000
# serverId=1

# 查看连接信息
echo "cons" | nc localhost 2181

# 查看dump信息
echo "dump" | nc localhost 2181

# 查看环境信息
echo "envi" | nc localhost 2181
```

---

## 本章小结

- Zookeeper是一个分布式协调服务，用于配置管理、命名服务、分布式锁、服务发现等
- Zookeeper基于Zab协议保证分布式环境中操作的原子性和一致性
- Leader选举使用FastLeaderElection算法，基于Epoch、ZXID、ServerID进行优先级比较
- 数据同步包括DIFF同步、TRUNC同步、SNAP同步三种类型
- Zookeeper配置包括基本配置、集群配置、连接配置、自动清理配置等
- Zookeeper四字命令用于监控和调试服务器状态

---

**下一章：Zookeeper架构原理**
