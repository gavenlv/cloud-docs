# Zookeeper数据模型

## 3.1 数据模型概述

### 3.1.1 层次化命名空间

```
Zookeeper数据模型：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper数据模型                                      │
└─────────────────────────────────────────────────────────────────┘

Zookeeper数据模型是一个层次化命名空间，类似于文件系统：

1. 树形结构
   ├── 根节点（/）
   ├── 一级节点（/zookeeper）
   ├── 二级节点（/zookeeper/config）
   └── 多级节点（/app/cluster/node1）

2. 节点路径规则
   ├── 路径必须以/开头
   ├── 路径不能包含..（父目录）
   ├── 路径不能包含单个.当前目录
   ├── 路径中可以有多个/
   └── 路径长度有限制（最大1MB）

3. 数据存储限制
   ├── 每个ZNode最多存储1MB数据
   ├── 数据可以是任意二进制数据
   └── 建议存储少量数据（KB级别）

4. 示例结构
   /
   ├── zookeeper/
   │   └── config/
   ├── services/
   │   ├── kafka/
   │   │   └── brokers/
   │   │       ├── 192.168.1.1:9092
   │   │       └── 192.168.1.2:9092
   │   └── zookeeper/
   │       └── servers/
   │           ├── localhost:2181
   │           └── localhost:2182
   └── config/
       ├── app/
       │   └── database
       └── feature-flags/
```

### 3.1.2 数据模型特点

```
数据模型特点：

┌─────────────────────────────────────────────────────────────────┐
│  数据模型特点                                              │
└─────────────────────────────────────────────────────────────────┘

1. 简单数据模型
   ├── 键值对存储
   ├── 树形结构
   ├── 无复杂查询
   └── 无关联查询

2. 高性能
   ├── 内存存储
   ├── 顺序读写
   ├── 低延迟
   └── 高吞吐量

3. 强一致性
   ├── 原子性操作
   ├── 顺序一致性
   ├── 线性一致性
   └── 最终一致性

4. 可靠性
   ├── 事务日志
   ├── 数据快照
   ├── 崩溃恢复
   └── 高可用
```

---

## 3.2 ZNode路径规则

### 3.2.1 路径命名规则

```
路径命名规则：

┌─────────────────────────────────────────────────────────────────┐
│  路径命名规则                                              │
└─────────────────────────────────────────────────────────────────┘

1. 基本规则
   ├── 必须以/开头
   ├── 路径分隔符为/
   ├── 节点名称不能包含/
   ├── 节点名称区分大小写
   └── 路径最大长度1MB

2. 节点名称规则
   ├── 长度：1-65535字节
   ├── 字符：Unicode字符
   ├── 特殊字符：. _ - :
   └── 保留名称：zookeeper

3. 路径示例
   /
   ├── node1
   ├── node_1
   ├── node-1
   ├── Node:1
   └── 节点名称可以是中文

4. 路径操作
   ├── 创建：create /path/node value
   ├── 读取：get /path/node
   ├── 更新：set /path/node value
   ├── 删除：delete /path/node
   └── 列出：ls /path
```

### 3.2.2 路径操作

```bash
# 路径操作示例

# 启动Zookeeper
bin/zkCli.sh

# 创建根节点（默认已存在）
create /test "test"

# 创建多级路径
create /app/cluster/node1 "node1"
# 错误：父节点不存在
# 解决方法：先创建父节点
create /app "app"
create /app/cluster "cluster"
create /app/cluster/node1 "node1"

# 使用mkpath创建多级路径
create -s /app/services/kafka/broker1 "broker1"
# -s表示创建顺序节点

# 读取路径
get /app/cluster/node1

# 获取路径状态
stat /app/cluster/node1

# 列出子节点
ls /app

# 列出根节点子节点
ls /

# 删除路径
delete /app/cluster/node1

# 递归删除
deleteall /app

# 验证删除
ls /
```

---

## 3.3 数据存储结构

### 3.3.1 内存数据存储

```
内存数据存储：

┌─────────────────────────────────────────────────────────────────┐
│  内存数据存储                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper使用内存存储数据，保证高性能：

1. DataTree
   ├── 核心数据结构
   ├── 存储所有ZNode
   ├── 内存结构
   └── 线程安全

2. DataNode
   ├── ZNode的数据结构
   ├── 存储节点数据
   ├── 存储节点属性
   └── 存储子节点列表

3. 内存结构
   DataTree
   ├── /
   │   ├── zookeeper/
   │   │   └── config/
   │   ├── services/
   │   │   └── kafka/
   │   └── config/
   └── ...

4. 内存管理
   ├── 堆内存存储
   ├── 定期快照
   ├── 事务日志
   └── 内存限制

5. 性能指标
   ├── 读性能：微妙级
   ├── 写性能：毫秒级
   ├── 内存占用：约1KB/节点
   └── 最大节点数：约100万
```

### 3.3.2 磁盘数据存储

```
磁盘数据存储：

┌─────────────────────────────────────────────────────────────────┐
│  磁盘数据存储                                              │
└─────────────────────────────────────────────────────────────────┘

磁盘存储用于持久化和恢复数据：

1. 数据目录（dataDir）
   ├── 快照文件（snapshot）
   ├── 事务日志（log）
   └── 文件命名：snapshot.ZXID

2. 快照文件
   ├── 内存数据的全量快照
   ├── 命名格式：snapshot.ZXID
   ├── 存储路径：dataDir/version-2/
   └── 快照频率：snapCount次事务

3. 事务日志
   ├── 所有写请求的日志
   ├── 预分配文件：64MB
   ├── 命名格式：log.ZXID
   ├── 存储路径：dataDir/version-2/
   └── 用于崩溃恢复

4. 存储目录结构
   dataDir/
   ├── version-2/
   │   ├── snapshot.0
   │   ├── snapshot.1
   │   ├── log.100
   │   ├── log.101
   │   └── myid
   └── zookeeper_server.pid

5. 存储流程
   写请求 -> 事务日志 -> 内存DataTree -> 快照
```

### 3.3.3 存储机制原理

```
存储机制原理：

┌─────────────────────────────────────────────────────────────────┐
│  存储机制原理                                              │
└─────────────────────────────────────────────────────────────────┘

1. 写请求流程
   接收请求
   -> 生成Proposal
   -> 写入事务日志
   -> 广播给Follower
   -> 等待ACK
   -> 提交事务
   -> 更新内存DataTree
   -> 快照（条件触发）

2. 事务日志
   ├── 顺序写入磁盘
   ├── 预分配64MB空间
   ├── 包含所有事务
   ├── 用于崩溃恢复
   └── 定期清理

3. 快照机制
   ├── 全量内存快照
   ├── 触发条件：snapCount次事务
   ├── 后台线程执行
   ├── 不阻塞请求
   └── 保留最近N个快照

4. 数据恢复
   ├── 读取最新快照
   ├── 重放快照之后的事务日志
   └── 恢复到最新状态

5. 存储优化
   ├── 事务日志顺序写
   ├── 快照后台生成
   ├── 定期清理旧文件
   └── 磁盘空间监控
```

---

## 3.4 事务ID（ZXID）

### 3.4.1 ZXID结构

```
ZXID结构：

┌─────────────────────────────────────────────────────────────────┐
│  ZXID结构                                              │
└─────────────────────────────────────────────────────────────────┘

ZXID（Zookeeper Transaction ID）是Zookeeper中事务的唯一标识：

1. ZXID结构
   ├── 高32位：Epoch（朝代/选举轮次）
   ├── 低32位：Counter（事务计数器）
   └── 总共64位

2. ZXID格式
   ┌────────────────────┬────────────────────┐
   │   Epoch (32位)    │  Counter (32位)    │
   └────────────────────┴────────────────────┘
   示例：0x0000010000000001
   Epoch: 0x00000001 = 1
   Counter: 0x00000001 = 1

3. Epoch变化
   ├── Leader选举时+1
   ├── 每次Leader变更
   ├── 用于区分不同Leader的任期
   └── 保证全局唯一性

4. Counter变化
   ├── 每个事务+1
   ├── Leader重启后从0开始
   ├── 同一个Leader内递增
   └── 保证事务顺序

5. ZXID比较规则
   ├── 先比较Epoch
   ├── Epoch大的更新
   ├── Epoch相等时比较Counter
   ├── Counter大的更新
   └── 用于Leader选举
```

### 3.4.2 ZXID的作用

```
ZXID的作用：

┌─────────────────────────────────────────────────────────────────┐
│  ZXID的作用                                              │
└─────────────────────────────────────────────────────────────────┘

1. 事务排序
   ├── 全局有序
   ├── 每个事务有唯一ZXID
   ├── 用于保证操作顺序
   └── 用于数据同步

2. Leader选举
   ├── 比较Epoch确定优先级
   ├── Epoch越大优先级越高
   ├── Epoch相等时比较ZXID
   ├── ZXID越大优先级越高
   └── 用于选择最新数据的Leader

3. 数据同步
   ├── 比较ZXID确定同步点
   ├── Follower需要同步缺失的事务
   ├── Leader发送缺失的事务
   └── 用于保证数据一致性

4. 故障恢复
   ├── 确定最后提交的事务
   ├── 确定需要重放的事务
   ├── 确定需要回滚的事务
   └── 用于崩溃恢复

5. ZXID使用场景
   ├── 写请求：生成新ZXID
   ├── 读请求：比较ZXID
   ├── 同步请求：比较ZXID
   └── 选举请求：比较ZXID
```

---

## 3.5 实战：理解数据模型

### 3.5.1 基本操作

```bash
# 基本操作示例

# 启动Zookeeper CLI
bin/zkCli.sh

# 查看根节点
ls /

# 预期输出：
# [zookeeper, test, app]

# 创建节点
create /test "Hello Zookeeper"

# 读取节点
get /test

# 预期输出：
# Hello Zookeeper
# cZxid = 0x2
# ctime = ...
# mZxid = 0x2
# mtime = ...
# pZxid = 0x2
# cversion = 0
# dataVersion = 0
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 16
# numChildren = 0

# 更新节点
set /test "Updated Value"

# 验证更新
get /test

# 预期输出：
# Updated Value

# 创建子节点
create /test/child1 "Child 1"
create /test/child2 "Child 2"

# 查看子节点
ls /test

# 预期输出：
# [child1, child2]

# 删除节点
delete /test/child1

# 验证删除
ls /test

# 预期输出：
# [child2]
```

### 3.5.2 路径操作

```bash
# 路径操作示例

# 启动Zookeeper CLI
bin/zkCli.sh

# 创建多级路径（方法1：逐层创建）
create /app "app"
create /app/cluster "cluster"
create /app/cluster/node1 "Node 1"
create /app/cluster/node2 "Node 2"

# 创建多级路径（方法2：使用create -p）
create -p /services/kafka/broker1 "Broker 1"
create -p /services/kafka/broker2 "Broker 2"

# 查看路径结构
ls /app
ls /app/cluster
ls /services
ls /services/kafka

# 获取路径状态
stat /app/cluster/node1

# 预期输出：
# cZxid = 0x5
# ctime = ...
# mZxid = 0x5
# mtime = ...
# pZxid = 0x7
# cversion = 2
# dataVersion = 0
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 8
# numChildren = 2

# 递归列出所有节点
ls -R /app

# 预期输出：
# /app
# /app/cluster
# /app/cluster/node1
# /app/cluster/node2

# 递归删除
deleteall /app

# 验证删除
ls /

# 预期输出：
# [zookeeper, services]
```

### 3.5.3 数据操作

```bash
# 数据操作示例

# 启动Zookeeper CLI
bin/zkCli.sh

# 创建带数据的节点
create /config "Database Config"
create /config/host "localhost"
create /config/port "3306"
create /config/user "root"
create /config/password "secret"

# 读取数据
get /config
get /config/host
get /config/port

# 更新数据
set /config/port "3307"
set /config/password "newsecret"

# 查看版本变化
get /config/port

# 预期输出：
# 3307
# dataVersion = 1

# 多版本数据（使用get带版本号）
get -s /config/port

# 预期输出：
# 3307
# cZxid = 0x10
# ...
# dataVersion = 1

# 乐观锁（版本不匹配时失败）
set /config/port "3308" -v 0

# 预期输出：
# version No is not correct : 0

# 使用正确版本更新
set /config/port "3308" -v 1

# 预期输出：
# WatchedEvent state:SyncConnected type:NodeDataChanged path:/config/port

# 验证更新
get /config/port

# 预期输出：
# 3308
# dataVersion = 2

# 获取子节点数据
get /config/host
get /config/port
get /config/user
get /config/password
```

---

## 本章小结

- Zookeeper数据模型是一个层次化命名空间，类似于文件系统
- 路径必须以/开头，节点名称区分大小写，每个ZNode最多存储1MB数据
- Zookeeper使用内存存储数据，保证高性能，同时使用磁盘存储事务日志和快照保证持久化
- 快照文件是内存数据的全量副本，事务日志记录所有写请求
- ZXID是事务的唯一标识，高32位是Epoch（选举轮次），低32位是Counter（事务计数器）
- ZXID用于事务排序、Leader选举、数据同步和故障恢复
- 路径操作包括创建、读取、更新、删除、列出子节点
- 数据操作支持版本控制，可以使用乐观锁机制

---

**下一章：ZNode类型和属性**
