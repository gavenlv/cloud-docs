# 集群部署和运维

## 9.1 集群规划

### 9.1.1 集群架构设计

```
集群架构设计：

┌─────────────────────────────────────────────────────────────────┐
│  集群架构设计                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper集群架构设计要点：

1. 节点数量规划
   ├── 最小集群：3节点
   ├── 推荐集群：5节点
   ├── 大型集群：7节点或更多
   └── 节点数量必须是奇数

2. 硬件配置
   ├── CPU：8核+
   ├── 内存：16GB+
   ├── 磁盘：SSD，500GB+
   ├── 网络：千兆网络
   └── 建议使用独立服务器

3. 网络规划
   ├── 内部通信网络
   ├── 客户端访问网络
   ├── 心跳网络（可选）
   └── 跨数据中心部署

4. 高可用设计
   ├── 电源冗余
   ├── 网络冗余
   ├── 服务器冗余
   └── 机房冗余

5. 容量规划
   ├── 评估存储需求
   ├── 评估TPS需求
   ├── 评估连接数需求
   └── 预留扩展空间
```

### 9.1.2 ZooKeeper集群架构

```
ZooKeeper集群架构：

┌─────────────────────────────────────────────────────────────────┐
│  ZooKeeper集群架构                                      │
└─────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │      Client          │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────┴─────────┐     │     ┌─────────┴─────────┐
    │      Server 1      │     │     │      Server 2      │
    │  ┌───────────────┐  │     │     │  ┌───────────────┐  │
    │  │    Leader     │  │     │     │  │   Follower    │  │
    │  │               │  │◄────┼────►│  │               │  │
    │  │  ┌─────────┐  │  │     │     │  │  ┌─────────┐  │  │
    │  │  │Proposal │  │  │     │     │  │  │ Learner │  │  │
    │  │  └─────────┘  │  │     │     │  │  └─────────┘  │  │
    │  │  ┌─────────┐  │  │     │     │  │  ┌─────────┐  │  │
    │  │  │  Commit │  │  │     │     │  │  │  Sync   │  │  │
    │  │  └─────────┘  │  │     │     │  │  └─────────┘  │  │
    │  └───────────────┘  │     │     │  └───────────────┘  │
    └─────────────────────┘     │     └─────────────────────┘
                                │
              ┌─────────────────┴────────────────┐
              │                                   │
    ┌─────────┴─────────┐             ┌─────────┴─────────┐
    │     Server 3      │             │     Server 4      │
    │  ┌─────────────┐  │             │  ┌─────────────┐  │
    │  │   Follower  │  │             │  │   Follower  │  │
    │  │             │  │◄───────────►│  │             │  │
    │  └─────────────┘  │             │  └─────────────┘  │
    └───────────────────┘             └───────────────────┘

    ┌─────────────────────────────────────────────────────┐
    │                    Observer（可选）                   │
    │  ┌───────────────┐  ┌───────────────┐              │
    │  │  Observer 1   │  │  Observer 2   │              │
    │  │               │  │               │              │
    │  └───────────────┘  └───────────────┘              │
    └─────────────────────────────────────────────────────┘
```

---

## 9.2 单机部署

### 9.2.1 环境准备

```bash
# 环境准备

# 1. 系统要求
# Linux (Ubuntu, CentOS, RHEL)
# macOS
# Windows (开发环境)

# 2. Java环境
# JDK 8+ required
# 推荐使用JDK 8或JDK 11

# 检查Java版本
java -version

# 预期输出：
# openjdk version "1.8.0_xxx"
# OpenJDK Runtime Environment (build 1.8.0_xxx)
# OpenJDK 64-Bit Server VM

# 设置JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# 3. 下载Zookeeper
# 下载地址：https://zookeeper.apache.org/releases.html

wget https://archive.apache.org/dist/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz

# 4. 解压
tar -xzf apache-zookeeper-3.8.0-bin.tar.gz

# 5. 目录结构
ls -la apache-zookeeper-3.8.0-bin/

# 预期输出：
# bin/              - 启动脚本
# conf/             - 配置文件
# lib/              - 依赖库
# logs/             - 日志目录
# data/             - 数据目录（需创建）
```

### 9.2.2 配置和启动

```bash
# 配置和启动

# 1. 创建数据目录
mkdir -p /data/zookeeper
mkdir -p /data/zookeeper/log

# 2. 创建myid文件（单机也必须）
echo "1" > /data/zookeeper/myid

# 3. 配置zoo.cfg
cd apache-zookeeper-3.8.0-bin
cat > conf/zoo.cfg << 'EOF'
# 基础配置
tickTime=2000
dataDir=/data/zookeeper
dataLogDir=/data/zookeeper/log
clientPort=2181

# 连接限制
maxClientCnxns=60

# 集群配置（单节点）
initLimit=10
syncLimit=5
# server.1=localhost:2888:3888

# 快照和事务日志
snapCount=100000
autopurge.snapRetainCount=3
autopurge.purgeInterval=1

# 性能配置
preAllocSize=65536
snapSizeLimitInKb=4194304
heapSizeMB=1000
EOF

# 4. 启动Zookeeper
bin/zkServer.sh start

# 预期输出：
# Starting zookeeper ... STARTED

# 5. 检查状态
bin/zkServer.sh status

# 预期输出（单机模式）：
# ZooKeeper JMX enabled by default
# Using config: /path/to/conf/zoo.cfg
# Mode: standalone

# 6. 连接测试
bin/zkCli.sh

# 预期输出：
# [zk: localhost:2181(CONNECTED) 0] ls /
# [zookeeper]

# 7. 停止Zookeeper
bin/zkServer.sh stop

# 预期输出：
# Stopping zookeeper ... STOPPED
```

### 9.2.3 Docker部署

```bash
# Docker部署

# 1. 创建数据目录
mkdir -p /data/zookeeper

# 2. 创建myid文件
echo "1" > /data/zookeeper/myid

# 3. 创建docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  zookeeper:
    image: zookeeper:3.8
    container_name: zookeeper
    restart: unless-stopped
    ports:
      - "2181:2181"
      - "2888:2888"
      - "3888:3888"
    environment:
      ZOO_MY_ID: 1
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_MAX_CLIENT_CNXNS: 60
      ZOO_AUTOPURGE_PURGEINTERVAL: 1
      ZOO_AUTOPURGE_SNAPRETAINCOUNT: 3
    volumes:
      - /data/zookeeper:/data
      - /data/zookeeper/log:/datalog
    networks:
      - zookeeper-net

networks:
  zookeeper-net:
    driver: bridge
EOF

# 4. 启动
docker-compose up -d

# 5. 检查状态
docker-compose ps

# 预期输出：
# NAME        COMMAND                  SERVICE   STATUS
# zookeeper   "/docker-entrypoint.…"   zookeeper  running

# 6. 连接测试
docker exec -it zookeeper zkCli.sh -server localhost:2181

# 7. 查看日志
docker-compose logs -f

# 8. 停止
docker-compose down
```

---

## 9.3 集群部署

### 9.3.1 集群配置

```bash
# 集群配置（3台机器）

# 假设有3台机器：
# server1: 192.168.1.101
# server2: 192.168.1.102
# server3: 192.168.1.103

# 每台机器上执行：

# 1. 创建数据目录
mkdir -p /data/zookeeper
mkdir -p /data/zookeeper/log

# 2. 创建myid文件
# server1
echo "1" > /data/zookeeper/myid

# server2
echo "2" > /data/zookeeper/myid

# server3
echo "3" > /data/zookeeper/myid

# 3. 配置zoo.cfg（所有机器相同）
cat > /opt/zookeeper/conf/zoo.cfg << 'EOF'
# 基础配置
tickTime=2000
dataDir=/data/zookeeper
dataLogDir=/data/zookeeper/log
clientPort=2181

# 连接限制
maxClientCnxns=60

# 集群配置
initLimit=10
syncLimit=5

# 集群节点配置
server.1=192.168.1.101:2888:3888
server.2=192.168.1.102:2888:3888
server.3=192.168.1.103:2888:3888

# 快照和事务日志
snapCount=100000
autopurge.snapRetainCount=3
autopurge.purgeInterval=1

# 性能配置
preAllocSize=65536
snapSizeLimitInKb=4194304
heapSizeMB=1000

# 四字命令白名单
4lw.commands.whitelist=*
EOF

# 4. 分发配置到所有机器
scp /opt/zookeeper/conf/zoo.cfg root@192.168.1.102:/opt/zookeeper/conf/
scp /opt/zookeeper/conf/zoo.cfg root@192.168.1.103:/opt/zookeeper/conf/

# 5. 启动集群（每台机器）
bin/zkServer.sh start

# 6. 检查状态（每台机器）
bin/zkServer.sh status

# 预期输出（server1）：
# ZooKeeper JMX enabled by default
# Using config: /opt/zookeeper/conf/zoo.cfg
# Mode: leader

# 预期输出（server2）：
# Mode: follower

# 预期输出（server3）：
# Mode: follower
```

### 9.3.2 Docker Compose集群部署

```bash
# Docker Compose集群部署

# 1. 创建目录结构
mkdir -p /data/zk1 /data/zk2 /data/zk3

# 2. 创建myid文件
echo "1" > /data/zk1/myid
echo "2" > /data/zk2/myid
echo "3" > /data/zk3/myid

# 3. 创建docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  zk1:
    image: zookeeper:3.8
    container_name: zk1
    restart: unless-stopped
    ports:
      - "2181:2181"
      - "2888:2888"
      - "3888:3888"
    environment:
      ZOO_MY_ID: 1
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888:participant server.2=zk2:2888:3888:participant server.3=zk3:2888:3888:participant
    volumes:
      - /data/zk1:/data
    networks:
      - zk-net

  zk2:
    image: zookeeper:3.8
    container_name: zk2
    restart: unless-stopped
    ports:
      - "2182:2181"
      - "2889:2888"
      - "3889:3888"
    environment:
      ZOO_MY_ID: 2
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_SERVERS: server.1=zk1:2888:3888:participant server.2=0.0.0.0:2888:3888:participant server.3=zk3:2888:3888:participant
    volumes:
      - /data/zk2:/data
    networks:
      - zk-net

  zk3:
    image: zookeeper:3.8
    container_name: zk3
    restart: unless-stopped
    ports:
      - "2183:2181"
      - "2890:2888"
      - "3890:3888"
    environment:
      ZOO_MY_ID: 3
      ZOO_TICK_TIME: 2000
      ZOO_INIT_LIMIT: 10
      ZOO_SYNC_LIMIT: 5
      ZOO_SERVERS: server.1=zk1:2888:3888:participant server.2=zk2:2888:3888:participant server.3=0.0.0.0:2888:3888:participant
    volumes:
      - /data/zk3:/data
    networks:
      - zk-net

networks:
  zk-net:
    driver: bridge
EOF

# 4. 启动集群
docker-compose up -d

# 5. 检查状态
docker exec -it zk1 zkServer.sh status

# 预期输出：
# ZooKeeper JMX enabled by default
# Using config: /conf/zoo.cfg
# Mode: leader

# 6. 连接测试
docker exec -it zk1 zkCli.sh -server zk1:2181,zk2:2181,zk3:2181
```

---

## 9.4 集群运维

### 9.4.1 日常运维命令

```bash
# 日常运维命令

# 1. 启动服务
bin/zkServer.sh start

# 2. 停止服务
bin/zkServer.sh stop

# 3. 重启服务
bin/zkServer.sh restart

# 4. 检查状态
bin/zkServer.sh status

# 5. 启动CLI
bin/zkCli.sh

# 6. 连接指定服务器
bin/zkCli.sh -server 192.168.1.101:2181

# 7. 连接指定服务器集群
bin/zkCli.sh -server 192.168.1.101:2181,192.168.1.102:2181,192.168.1.103:2181

# 8. 查看日志
tail -f logs/zookeeper.out

# 9. 清理快照
bin/zkCleanup.sh -n 3

# 10. 四字命令健康检查
echo "ruok" | nc localhost 2181

# 预期输出：
# imok

# 11. 四字命令状态
echo "stat" | nc localhost 2181

# 12. 四字命令监控指标
echo "mntr" | nc localhost 2181
```

### 9.4.2 集群扩容和缩容

```bash
# 集群扩容和缩容

# 扩容：从3节点扩到5节点

# 1. 新增节点配置
# 在原有zoo.cfg中添加：
# server.4=192.168.1.104:2888:3888
# server.5=192.168.1.105:2888:3888

# 2. 更新所有节点的zoo.cfg
# 分发新配置到所有节点

# 3. 创建myid文件
# 在新节点上执行：
echo "4" > /data/zookeeper/myid
echo "5" > /data/zookeeper/myid

# 4. 重启Leader
bin/zkServer.sh restart

# 5. 启动新节点
bin/zkServer.sh start

# 6. 验证集群状态
bin/zkServer.sh status

# 预期输出：
# ZooKeeper JMX enabled by default
# Using config: /conf/zoo.cfg
# Mode: leader

# 预期输出（集群信息）：
# ZooKeeper version: 3.8.0
# Nodes: 5
# ...

# 缩容：从5节点缩到3节点

# 1. 停止要移除的节点
bin/zkServer.sh stop

# 2. 更新所有节点的zoo.cfg
# 移除对应server配置

# 3. 重启集群
bin/zkServer.sh restart

# 4. 验证集群状态
bin/zkServer.sh status
```

### 9.4.3 Leader切换

```bash
# Leader切换

# 1. 查看当前Leader
echo "stat" | nc localhost 2181

# 预期输出：
# Mode: leader

# 2. 查看集群配置
echo "conf" | nc localhost 2181

# 3. 模拟Leader故障
# 在Leader节点上执行：
bin/zkServer.sh stop

# 4. 观察Follower自动切换
# 在Follower节点上执行：
bin/zkServer.sh status

# 预期输出（新的Leader）：
# Mode: leader

# 5. 验证服务可用性
bin/zkCli.sh -server 192.168.1.102:2181,192.168.1.103:2181

# 6. 恢复原Leader
bin/zkServer.sh start

# 7. 验证原Leader成为Follower
bin/zkServer.sh status

# 预期输出：
# Mode: follower
```

---

## 9.5 监控和日志

### 9.5.1 监控指标

```bash
# 监控指标

# 1. 四字命令监控
echo "mntr" | nc localhost 2181

# 预期输出：
# zk_version                      3.8.0
# zk_server_state                leader
# zk_num_alive_connections       5
# zk_zookeeper_created_total      100
# zk_zookeeper_connected_total    10
# zk_zookeeper_expired_total      0
# zk_zookeeper_-close_count      50
# zk_zookeeper_non_mt_handler_requests    20
# zk_avg_latency                 1
# zk_min_latency                 0
# zk_max_latency                 10
# zk_packets_received             1000
# zk_packets_sent                 1000
# zk_num_stale_requests          0
# zk_stale_replies               0
# zk_unstale_requests            0
# zk_pending_syncs                0
# zk_learners                    2
# zk_learner_count               2
# zk_cluster_requests             50
# zk_server_proposals             100
# zk_server_proposal_latencies   0,0,0,0,0,0,0,0,0,0,0,0
# zk_server_proposal_ack_latencies 0,0,0,0
# zk_server_proposal_commit_latencies 0,0,0,0
# zk_server_proposal_result_latencies 0,0,0,0
# zk_server_proposal_wait_latencies   0,0,0,0
# zk_sync_procedures              0
# zk_interest_list_size           10
# zk_queued_buffer_length         100
# zk_sessionless_connections_ope  5
# zk_connection_drop_probability  0.0
# zk_approximate_data_size        1024
# zk_ephemerals_count             10
# zk_ watches                     50
# zk_additional_details_size      0
# zk_in-memory-trees              100
# zk_large_commits                0
# zk_commit_compression_ratio     1.0
# zk_server_proposal_request_latencies 0,0,0,0,0,0,0,0,0,0
# zk_quorum_size                  3
# zk_multiaddr.size               2

# 2. 监听统计
echo "wchs" | nc localhost 2181

# 预期输出：
# 1: 3 connections, 5 watches

# 3. 连接信息
echo "cons" | nc localhost 2181

# 预期输出：
# /127.0.0.1:58012[0](queued=0,recved=100,sent=100,sid=0x1,lop=...)
```

### 9.5.2 日志管理

```bash
# 日志管理

# 1. Zookeeper日志配置
# 在conf/log4j.properties中配置

# 2. 查看日志
tail -f logs/zookeeper.out

# 3. 滚动日志
# 默认日志在logs/目录下
# 可配置log4j实现日志滚动

# 4. 清理日志
# 手动清理
rm -rf logs/*

# 5. 自动清理快照
# 在zoo.cfg中配置
# autopurge.snapRetainCount=3
# autopurge.purgeInterval=1

# 6. 使用zkCleanup.sh清理
bin/zkCleanup.sh -n 3

# 参数说明：
# -n count：保留最近的count个快照

# 7. 日志级别调整
# 临时调整（通过JMX）
# 永久调整（在conf/log4j.properties中）
```

### 9.5.3 Prometheus监控

```yaml
# Prometheus监控配置

# 1. 安装jolokia-jvm-agent
# 下载地址：https://github.com/jolokia/jolokia

# 2. 启动Zookeeper with JMX
export ZOOCFG="-Dcom.sun.management.jmxremote
  -Dcom.sun.management.jmxremote.port=9010
  -Dcom.sun.management.jmxremote.local.only=true
  -Dcom.sun.management.jmxremote.authenticate=false
  -Dcom.sun.management.jmxremote.ssl=false"

bin/zkServer.sh start

# 3. Prometheus配置
# prometheus.yml
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'zookeeper'
    static_configs:
      - targets: ['localhost:2181']
    metrics_path: /metrics
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
EOF

# 4. 使用四字命令暴露指标
# 在zoo.cfg中启用
# 4lw.commands.whitelist=mntr,ruok,stat
```

---

## 9.6 备份和恢复

### 9.6.1 快照备份

```bash
# 快照备份

# 1. 快照目录
# 默认位置：dataDir/version-2/

# 2. 查看快照文件
ls -la /data/zookeeper/version-2/

# 预期输出：
# snapshot.0000000001
# snapshot.0000000002
# ...

# 3. 手动触发快照
# 通过Zookeeper CLI
echo "snap" | nc localhost 2181

# 4. 备份快照
# 停止Zookeeper
bin/zkServer.sh stop

# 备份数据目录
tar -czf zookeeper-backup-$(date +%Y%m%d).tar.gz /data/zookeeper

# 重启Zookeeper
bin/zkServer.sh start

# 5. 定期备份脚本
cat > /opt/backup-zk.sh << 'EOF'
#!/bin/bash

BACKUP_DIR=/backup/zookeeper
DATA_DIR=/data/zookeeper

# 创建备份目录
mkdir -p $BACKUP_DIR

# 停止Zookeeper
bin/zkServer.sh stop

# 备份数据
tar -czf $BACKUP_DIR/zk-backup-$(date +%Y%m%d-%H%M%S).tar.gz $DATA_DIR

# 重启Zookeeper
bin/zkServer.sh start

# 清理旧备份（保留7天）
find $BACKUP_DIR -name "zk-backup-*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/backup-zk.sh

# 6. 添加定时任务
# crontab -e
# 0 2 * * * /opt/backup-zk.sh
```

### 9.6.2 数据恢复

```bash
# 数据恢复

# 1. 停止Zookeeper
bin/zkServer.sh stop

# 2. 备份当前数据
tar -czf /backup/current-data-$(date +%Y%m%d).tar.gz /data/zookeeper

# 3. 清理数据目录
rm -rf /data/zookeeper/*

# 4. 解压备份
tar -xzf /backup/zookeeper-backup-20240101.tar.gz -C /

# 5. 恢复myid
cat /data/zookeeper/myid

# 6. 启动Zookeeper
bin/zkServer.sh start

# 7. 验证数据
bin/zkCli.sh
ls /

# 8. 恢复Observer节点
# 在Observer节点上：
bin/zkServer.sh start

# 9. 验证集群状态
bin/zkServer.sh status
```

### 9.6.3 数据迁移

```bash
# 数据迁移

# 场景：从单机迁移到集群

# 1. 准备集群环境
# 按照集群部署步骤部署3节点集群

# 2. 确认单机数据
bin/zkCli.sh
ls /
get /zookeeper/config

# 3. 导出单机数据
# 使用Zookeeper CLI导出
# 在单机上：
bin/zkCli.sh -server localhost:2181
getAll /

# 或者使用四字命令dump
echo "dump" | nc localhost 2181

# 4. 导入数据到集群
# 在Leader节点上：
bin/zkCli.sh -server 192.168.1.101:2181

# 重新创建节点
create /config "App Configuration"
create /services "Services"
...

# 5. 验证数据
ls /
get /config

# 6. 切换客户端连接
# 修改客户端配置指向集群地址
```

---

## 本章小结

- 集群规划需要考虑节点数量、硬件配置、网络规划和容量规划
- 单机部署适用于开发测试环境，配置简单
- 集群部署需要配置server列表、initLimit、syncLimit等参数
- Docker Compose可以简化集群部署，需要配置网络和myid
- 日常运维包括启动、停止、重启、状态检查、日志清理等
- 集群扩容和缩容需要更新配置并重启节点
- Leader切换是自动的，Follower会检测并重新选举
- 监控可以使用四字命令或Prometheus
- 备份和恢复是运维的重要部分，需要定期执行

---

**下一章：常见错误处理**
