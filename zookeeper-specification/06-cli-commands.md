# CLI命令详解

## 6.1 Zookeeper CLI概述

### 6.1.1 CLI基本介绍

```
Zookeeper CLI基本介绍：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper CLI概述                                        │
└─────────────────────────────────────────────────────────────────┘

Zookeeper CLI是Zookeeper的命令行客户端工具：

1. CLI位置
   ├── bin/zkCli.sh（Linux/macOS）
   ├── bin/zkCli.cmd（Windows）
   └── 位于Zookeeper安装目录

2. 连接方式
   ├── 本地连接：bin/zkCli.sh
   ├── 远程连接：bin/zkCli.sh -server host:port
   └── 指定根节点：bin/zkCli.sh -r /namespace

3. 基本用法
   bin/zkCli.sh [options]
   bin/zkCli.sh -server localhost:2181
   bin/zkCli.sh -timeout 5000
   bin/zkCli.sh -r /app

4. 退出CLI
   quit
   close

5. 帮助命令
   help
```

### 6.1.2 CLI命令分类

```
CLI命令分类：

┌─────────────────────────────────────────────────────────────────┐
│  CLI命令分类                                              │
└─────────────────────────────────────────────────────────────────┘

1. 连接命令
   ├── connect host:port - 连接服务器
   ├── close - 关闭连接
   └── quit - 退出CLI

2. 创建命令
   ├── create [-s] [-e] path data [acl] - 创建节点
   ├── create -c path data [acl] - 创建容器节点
   ├── create -t TTL path data [acl] - 创建TTL节点

3. 读取命令
   ├── get [-s] [-w] path - 获取节点数据
   ├── ls [-s] [-w] [-R] path - 列出子节点
   ├── stat [-w] path - 获取节点状态
   ├── getAcl [-s] path - 获取ACL

4. 更新命令
   ├── set [-s] [-v version] path data - 设置节点数据
   ├── setAcl [-s] [-v version] path acl - 设置ACL
   ├── addauth scheme auth - 添加认证信息

5. 删除命令
   ├── delete [-v version] path - 删除节点
   ├── deleteall path [-b batch size] - 递归删除
   └── rmr path - 递归删除（已废弃）

6. 其他命令
   ├── sync path - 同步节点
   ├── history - 显示历史命令
   ├── redo cmdno - 重做命令
   ├── printwatches on|off - 打印监听状态
   ├── setquota -n|-b path - 设置配额
   ├── listquota path - 列出配额
   └── delquota [-n|-b] path - 删除配额
```

---

## 6.2 连接命令

### 6.2.1 连接和退出

```bash
# 连接和退出命令

# 启动CLI（默认连接localhost:2181）
bin/zkCli.sh

# 预期输出：
# Connecting to localhost:2181
# Welcome to ZooKeeper!
# JLine support is enabled
# [zk: localhost:2181(CONNECTED) 0]

# 连接指定服务器
bin/zkCli.sh -server localhost:2181

# 连接指定服务器（带端口）
bin/zkCli.sh -server 192.168.1.1:2181,192.168.1.2:2181

# 连接带超时时间（毫秒）
bin/zkCli.sh -server localhost:2181 -timeout 10000

# 连接带根节点
bin/zkCli.sh -r /app

# 退出CLI
quit

# 预期输出：
# INFO: Session ending, the session will be removed from the store

# 关闭连接（不断开CLI）
close

# 重新连接
connect localhost:2181
```

### 6.2.2 帮助命令

```bash
# 帮助命令

# 启动CLI
bin/zkCli.sh

# 显示所有命令
help

# 预期输出：
# ZooKeeper -server host:port cmd args
#     connect host:port - connect to a zookeeper server
#     close - close this session
#     quit - quit
#     ls [-s] [-w] [-R] path - list children
#     stat [-w] path - list status
#     get [-s] [-w] path - get data
#     create [-s] [-e] [-c] [-t TTL] path data [acl] - create a node
#     set [-s] [-v version] path data - set data
#     delete [-v version] path - delete a node
#     deleteall path - delete all nodes
#     setquota -n|-b val path - set quota
#     listquota path - list quotas
#     delquota [-n|-b] path - delete quota
#     history - show recent command history
#     redo cmdno - run a command by its number
#     printwatches on|off - print watches
#     getAcl [-s] path - get ACL
#     setAcl [-s] [-v version] path acl - set ACL
#     addauth scheme auth - add authentication
#     sync path - sync data

# 显示特定命令帮助
help ls
help create
help get
help set
```

---

## 6.3 ZNode操作命令

### 6.3.1 创建命令

```bash
# 创建命令

# 启动CLI
bin/zkCli.sh

# 创建持久节点
create /config "Configuration Data"

# 创建临时节点（-e）
create -e /service/node1 "192.168.1.1:8080"

# 创建顺序节点（-s）
create -s /queue/task "Task 1"
# 结果：/queue/task0000000001

create -s /queue/task "Task 2"
# 结果：/queue/task0000000002

# 创建临时顺序节点（-s -e）
create -s -e /lock/lock "Lock 1"
# 结果：/lock/lock0000000001

# 创建容器节点（-c，3.5+）
create -c /container "Container"

# 创建TTL节点（-t，3.5+）
create -t 10000 /ttl "TTL Data"
# 10秒后自动删除

# 创建带ACL的节点
create /protected "Protected Data" world:anyone:cdrwa

# 创建多级路径
create -p /app/cluster/node1 "Node 1"

# 查看创建结果
ls /
get /config
get /service/node1
get /queue/task0000000001
```

### 6.3.2 读取命令

```bash
# 读取命令

# 启动CLI
bin/zkCli.sh

# 创建测试节点
create /test "Hello Zookeeper"
create /test/child1 "Child 1"
create /test/child2 "Child 2"

# 获取节点数据
get /test

# 预期输出：
# Hello Zookeeper
# cZxid = 0x2
# ctime = ...
# mZxid = 0x2
# mtime = ...
# ...

# 获取节点数据（带状态）
get -s /test

# 预期输出：
# Hello Zookeeper
# cZxid = 0x2
# ctime = 1234567890000
# mZxid = 0x2
# mtime = 1234567890000
# pZxid = 0x5
# cversion = 2
# dataVersion = 0
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 16
# numChildren = 2

# 获取节点数据（带监听）
get -w /test

# 预期输出：
# Hello Zookeeper
# WatchedEvent state:SyncConnected type:NodeDataChanged path:/test

# 列出子节点
ls /test

# 预期输出：
# [child1, child2]

# 列出子节点（带状态）
ls -s /test

# 预期输出：
# [child1, child2]
# cZxid = 0x2
# ctime = ...
# mZxid = 0x2
# ...

# 列出子节点（带监听）
ls -w /test

# 列出子节点（递归）
ls -R /test

# 预期输出：
# /test
# /test/child1
# /test/child2

# 获取节点状态
stat /test

# 预期输出：
# cZxid = 0x2
# ctime = ...
# mZxid = 0x2
# ...

# 获取节点状态（带监听）
stat -w /test
```

### 6.3.3 更新和删除命令

```bash
# 更新和删除命令

# 启动CLI
bin/zkCli.sh

# 创建测试节点
create /test "Initial Data"
create /test/child1 "Child 1"
create /test/child2 "Child 2"
create /test/child3 "Child 3"

# 更新节点数据
set /test "Updated Data"

# 更新节点数据（带版本检查）
set -v 1 /test "Versioned Update"

# 预期输出（版本匹配）：
# cZxid = 0x2
# ...

# 预期输出（版本不匹配）：
# version No is not correct : 0

# 获取更新后的数据
get -s /test

# 预期输出：
# Updated Data
# dataVersion = 1

# 删除子节点
delete /test/child1

# 验证删除
ls /test

# 预期输出：
# [child2, child3]

# 删除节点（带版本检查）
delete -v 1 /test/child2

# 预期输出（版本匹配）：
# 删除成功

# 预期输出（版本不匹配）：
# version No is not correct : 0

# 递归删除所有节点
deleteall /test

# 验证删除
ls /

# 预期输出：
# [zookeeper]

# 旧命令：递归删除（已废弃）
rmr /test
```

---

## 6.4 高级命令

### 6.4.1 ACL命令

```bash
# ACL命令

# 启动CLI
bin/zkCli.sh

# 创建测试节点
create /acl-test "ACL Test"

# 获取ACL
getAcl /acl-test

# 预期输出：
# 'world,'anyone
# : cdrwa

# world权限示例
# world:anyone:cdrwa - 所有人所有权限
# world:anyone:crda - 所有人读和删除权限

# 设置ACL
setAcl /acl-test world:anyone:crda

# 验证ACL
getAcl /acl-test

# 预期输出：
# 'world,'anyone
# : crda

# auth权限示例
# 创建用户认证
addauth digest user1:password1

# 使用auth创建节点
create /auth-test "Auth Test" auth:user1:password1:cdrwa

# 验证auth节点
getAcl /auth-test

# 预期输出：
# 'digest,'user1:password1
# : cdrwa

# ip权限示例
# 创建IP限制节点
create /ip-test "IP Test" ip:192.168.1.1:cdrwa

# 验证IP节点
getAcl /ip-test

# 预期输出：
# 'ip,'192.168.1.1
# : cdrwa

# super权限示例（启动时配置）
# bin/zkServer.sh start -Dzookeeper.DigestAuthenticationProvider.superDigest=admin:password
```

### 6.4.2配额命令

```bash
# 配额命令

# 启动CLI
bin/zkCli.sh

# 创建测试节点
create /quota-test "Quota Test"

# 设置节点数量配额（-n）
setquota -n 10 /quota-test

# 预期输出：
# Comment: this value has been set, we can now enforce it

# 设置数据长度配额（-b，单位字节）
setquota -b 1024 /quota-test

# 列出配额
listquota /quota-test

# 预期输出：
# Outputted quota for /quota-test stats for this znode:
# count:2, bytes:0
# subdirectories count is 0

# 删除节点数量配额
delquota -n /quota-test

# 删除数据长度配额
delquota -b /quota-test

# 验证删除
listquota /quota-test

# 预期输出：
#quota for /quota-test does not exist
```

### 6.4.3 其他高级命令

```bash
# 其他高级命令

# 启动CLI
bin/zkCli.sh

# 创建测试节点
create /test "Hello"
create /test/child "World"

# 同步命令（强制同步）
sync /test

# 预期输出：
# Sync returned

# 打印监听状态
printwatches on

# 预期输出：
# printwatches is on

# 历史命令
history

# 预期输出：
# 0 - help
# 1 - ls /
# 2 - create /test "Hello"
# 3 - history

# 重做命令
redo 2

# 预期输出：
# [zookeeper]

# addauth命令（添加认证）
addauth digest user1:password1

# 预期输出：
# 添加认证成功

# 设置认证后访问受保护节点
get /auth-node

# 预期输出（已认证）：
# Auth Test

# 预期输出（未认证）：
# Authentication is not valid : /auth-node
```

---

## 6.5 四字命令

### 6.5.1 四字命令概述

```
四字命令概述：

┌─────────────────────────────────────────────────────────────────┐
│  四字命令概述                                              │
└─────────────────────────────────────────────────────────────────┘

四字命令是Zookeeper的监控命令：

1. 命令格式
   ├── 使用nc或echo发送
   ├── echo "cmd" | nc host port
   ├── 返回纯文本或四字输出
   └── 简单快速

2. 命令列表
   ├── conf：服务器配置
   ├── cons：连接信息
   ├── crst：连接统计重置
   ├── dump：会话和临时节点
   ├── envi：环境信息
   ├── ruok：服务器健康检查
   ├── srst：统计重置
   ├── stat：服务器状态
   ├── wchs：监听统计
   ├── wchc：监听详情（按连接）
   ├── wchp：监听详情（按路径）
   └── mntr：监控指标

3. 启用四字命令
   # 在zoo.cfg中添加
   4lw.commands.whitelist=*
   # 或指定命令
   4lw.commands.whitelist=conf,stat,ruok,mntr
```

### 6.5.2 四字命令示例

```bash
# 四字命令示例

# 健康检查（ruok）
echo "ruok" | nc localhost 2181

# 预期输出：
# imok

# 服务器状态（stat）
echo "stat" | nc localhost 2181

# 预期输出：
# ZooKeeper version: 3.8.0
# Latency min/avg/max: 0/0/0
# Received: 10
# Sent: 10
# Connections: 1
# Outstanding: 0
# Zxid: 0x2
# Mode: standalone
# Node count: 5

# 服务器配置（conf）
echo "conf" | nc localhost 2181

# 预期输出：
# clientPort=2181
# dataDir=/tmp/zookeeper
# dataLogDir=/tmp/zookeeper
# tickTime=2000
# maxClientCnxns=60
# minSessionTimeout=4000
# maxSessionTimeout=40000
# serverId=1

# 环境信息（envi）
echo "envi" | nc localhost 2181

# 预期输出：
# Environment:
# zookeeper.version=3.8.0
# host.name=localhost
# java.version=11.0.1
# java.vendor=Oracle Corporation
# ...

# 连接信息（cons）
echo "cons" | nc localhost 2181

# 预期输出：
# /127.0.0.1:58012[0](queued=0,recved=10,sent=10,sid=0x1,lop=NA,est=...)
# ...

# 监控指标（mntr）
echo "mntr" | nc localhost 2181

# 预期输出：
# zk_version 3.8.0
# zk_server_state standalone
# zk_num_alive_connections 1
# zk_zookeeper_created_total 5
# zk_zookeeper_connected_total 1
# ...

# 监听统计（wchs）
echo "wchs" | nc localhost 2181

# 预期输出：
# 1: 3 connections, 3 watches

# 监听详情按连接（wchc）
echo "wchc" | nc localhost 2181

# 预期输出：
# 0x1: subs=3
#     /path1
#     /path2
#     /path3

# 监听详情按路径（wchp）
echo "wchp" | nc localhost 2181

# 预期输出：
# /path1: 1 connections
#     0x1
# /path2: 1 connections
#     0x1
# ...

# 会话和临时节点（dump）
echo "dump" | nc localhost 2181

# 预期输出：
# SessionTracker dump:
# Session Sets (0):
# ephemeral nodes:
# /path: sessionid=0x1,num=1
```

---

## 6.6 实战：CLI命令使用

### 6.6.1 基本CRUD操作

```bash
# 基本CRUD操作

# 启动Zookeeper
bin/zkServer.sh start

# 启动CLI
bin/zkCli.sh

# 创建配置节点
create /config "App Configuration"
create /config/database "mysql://localhost:3306"
create /config/cache "redis://localhost:6379"
create /config/server "8080"

# 读取配置
get /config
get /config/database
get /config/cache
get /config/server

# 更新配置
set /config/database "mysql://remote:3306"
set /config/server "9090"

# 验证更新
get -s /config/server

# 删除配置
delete /config/server

# 验证删除
ls /config

# 清理
deleteall /config
```

### 6.6.2 服务注册和发现

```bash
# 服务注册和发现

# 启动CLI
bin/zkCli.sh

# 创建服务根节点
create /services "Services" -c

# 注册Kafka服务
create -e /services/kafka/broker1 "192.168.1.101:9092"
create -e /services/kafka/broker2 "192.168.1.102:9092"

# 注册Zookeeper服务
create -e /services/zookeeper/server1 "192.168.1.101:2181"
create -e /services/zookeeper/server2 "192.168.1.102:2181"

# 查看所有服务
ls -R /services

# 获取服务地址
get /services/kafka/broker1
get /services/kafka/broker2

# 服务下线（模拟）
delete /services/kafka/broker1

# 验证服务注销
ls /services/kafka

# 清理
deleteall /services
```

### 6.6.3 分布式锁

```bash
# 分布式锁

# 启动CLI（两个终端）

# 终端1：获取锁
bin/zkCli.sh

# 创建锁节点
create -e -s /locks/task "Task Lock"

# 预期输出：
# Created -e -s /locks/task0000000001

# 终端2：获取锁
bin/zkCli.sh

# 查看锁
ls /locks

# 预期输出：
# [task0000000001]

# 尝试获取锁（如果task0000000001存在，等待）
# 在实际应用中，应该监听task0000000001的删除事件

# 终端1：释放锁
delete /locks/task0000000001

# 终端2：收到删除事件，可以获取锁
# 重新创建锁节点
create -e -s /locks/task "Task Lock"

# 预期输出：
# Created -e -s /locks/task0000000002

# 清理
deleteall /locks
```

---

## 本章小结

- Zookeeper CLI是Zookeeper的命令行客户端工具，支持连接、创建、读取、更新、删除等操作
- 创建命令包括create [-s] [-e] [-c] [-t TTL] path data [acl]
- 读取命令包括get [-s] [-w] path、ls [-s] [-w] [-R] path、stat [-w] path、getAcl [-s] path
- 更新命令包括set [-s] [-v version] path data、setAcl [-s] [-v version] path acl、addauth scheme auth
- 删除命令包括delete [-v version] path、deleteall path、rmr path（已废弃）
- ACL权限包括crdwa（创建、读取、删除、写、管理）
- 配额命令包括setquota、listquota、delquota
- 四字命令是Zookeeper的监控命令，包括conf、stat、ruok、mntr、wchs等
- CLI命令可以用于基本CRUD操作、服务注册和发现、分布式锁等场景

---

**下一章：API编程**
