# ZNode类型和属性

## 4.1 ZNode类型概述

### 4.1.1 ZNode类型分类

```
ZNode类型：

┌─────────────────────────────────────────────────────────────────┐
│  ZNode类型分类                                          │
└─────────────────────────────────────────────────────────────────┘

Zookeeper中的ZNode有四种类型：

1. 持久节点（Persistent）
   ├── 创建后一直存在
   ├── 直到被显式删除
   ├── 可以有子节点
   └── 示例：配置持久化

2. 临时节点（Ephemeral）
   ├── 与创建它的Session绑定
   ├── Session断开后自动删除
   ├── 不能有子节点
   └── 示例：服务注册

3. 持久顺序节点（Persistent Sequential）
   ├── 持久节点特性
   ├── 自动添加递增序号
   └── 示例：分布式队列

4. 临时顺序节点（Ephemeral Sequential）
   ├── 临时节点特性
   ├── 自动添加递增序号
   └── 示例：分布式锁

类型组合：
┌───────────────────┬────────────┬──────────┬─────────┐
│       类型        │   持久性   │  顺序性  │  序号   │
├───────────────────┼────────────┼──────────┼─────────┤
│ 持久节点          │     ✓      │    ✗     │    -    │
│ 临时节点          │     ✗      │    ✗     │    -    │
│ 持久顺序节点      │     ✓      │    ✓     │  递增   │
│ 临时顺序节点      │     ✗      │    ✓     │  递增   │
└───────────────────┴────────────┴──────────┴─────────┘
```

### 4.1.2 创建类型的命令

```
创建类型的命令：

┌─────────────────────────────────────────────────────────────────┐
│  创建类型的命令                                          │
└─────────────────────────────────────────────────────────────────┘

1. 持久节点（默认）
   命令：create /path data
   示例：create /config "value"
   结果：创建持久节点

2. 临时节点
   命令：create -e /path data
   示例：create -e /service/node1 "host:port"
   结果：创建临时节点

3. 持久顺序节点
   命令：create -s /path data
   示例：create -s /queue/task "task1"
   结果：创建持久顺序节点，路径变为/queue/task0000000001

4. 临时顺序节点
   命令：create -e -s /path data
   示例：create -e -s /lock/task "task1"
   结果：创建临时顺序节点，路径变为/lock/task0000000001

5. 容器节点（3.5+）
   命令：create -c /path data
   示例：create -c /container "container"
   结果：创建容器节点

6. TTL节点（3.5+，需配置）
   命令：create -t TTL /path data
   示例：create -t 10000 /ttl "value"
   结果：创建TTL节点，10秒后自动删除
```

---

## 4.2 持久节点

### 4.2.1 持久节点特性

```
持久节点特性：

┌─────────────────────────────────────────────────────────────────┐
│  持久节点特性                                              │
└─────────────────────────────────────────────────────────────────┘

持久节点是最基本的ZNode类型：

1. 生命周期
   ├── 创建后一直存在
   ├── 直到被显式删除
   ├── 不依赖Session
   └── Session断开不影响

2. 数据存储
   ├── 可以存储最多1MB数据
   ├── 支持任意二进制数据
   └── 建议存储KB级别数据

3. 子节点
   ├── 可以有子节点
   ├── 子节点可以是任意类型
   └── 删除时需先删除子节点

4. 使用场景
   ├── 配置存储
   ├── 持久化状态
   ├── 命名服务
   └── 根节点

5. 示例
   /
   ├── config/                    # 持久节点
   │   ├── database              # 持久节点
   │   │   ├── host              # 持久节点
   │   │   └── port              # 持久节点
   │   └── cache                 # 持久节点
   └── services/                 # 持久节点
       └── kafka/                # 持久节点
           └── brokers/           # 持久节点
```

### 4.2.2 持久节点操作

```bash
# 持久节点操作

# 启动Zookeeper
bin/zkCli.sh

# 创建持久节点
create /config "Configuration"

# 读取持久节点
get /config

# 更新持久节点
set /config "Updated Configuration"

# 创建子持久节点
create /config/database "Database Config"
create /config/database/host "localhost"
create /config/database/port "3306"

# 列出子节点
ls /config

# 列出子节点详情
ls -s /config/database

# 验证持久性（断开Session后仍然存在）
quit

# 重新连接
bin/zkCli.sh

# 验证节点仍然存在
get /config
ls /config/database

# 删除子节点
delete /config/database/host
delete /config/database/port

# 删除父节点
delete /config/database
delete /config
```

---

## 4.3 临时节点

### 4.3.1 临时节点特性

```
临时节点特性：

┌─────────────────────────────────────────────────────────────────┐
│  临时节点特性                                              │
└─────────────────────────────────────────────────────────────────┘

临时节点与Session绑定：

1. 生命周期
   ├── 与创建它的Session绑定
   ├── Session断开后自动删除
   ├── 不支持子节点
   └── 删除前会触发Watch

2. Session绑定
   ├── 依赖Session存在
   ├── Session超时自动删除
   ├── 显式关闭Session删除
   └── Session迁移后删除

3. 自动删除
   ├── 客户端断开连接
   ├── 服务端检测Session超时
   ├── 删除临时节点
   └── 触发Watch通知

4. 使用场景
   ├── 服务注册
   ├── 心跳检测
   ├── 分布式锁
   └── Leader选举

5. 示例
   服务注册：
   Server1启动 -> 创建临时节点 /services/kafka/192.168.1.1:9092
   Server2启动 -> 创建临时节点 /services/kafka/192.168.1.2:9092
   Server1宕机 -> Session断开 -> 节点自动删除

6. 限制
   ├── 不能创建子节点
   ├── 只能创建一级临时节点
   └── 临时节点名称不能包含/$
```

### 4.3.2 临时节点操作

```bash
# 临时节点操作

# 启动Zookeeper
bin/zkCli.sh

# 创建临时节点
create -e /service/node1 "192.168.1.1:8080"

# 读取临时节点
get /service/node1

# 预期输出：
# 192.168.1.1:8080
# ephemeralOwner = 0x1234567890abcdef

# 查看节点属性（ephemeralOwner不为0）
stat -s /service/node1

# 预期输出：
# cZxid = 0x100000002
# ...
# ephemeralOwner = 0x1234567890abcdef

# 创建子节点（会失败）
create /service/node1/child "child"

# 预期输出：
# Ephemeral nodes cannot have children: /service/node1/child

# 断开Session
close

# 或者quit退出
quit

# 重新连接另一个客户端
bin/zkCli.sh

# 检查临时节点是否已删除
get /service/node1

# 预期输出：
# Node does not exist: /service/node1
```

---

## 4.4 顺序节点

### 4.4.1 顺序节点特性

```
顺序节点特性：

┌─────────────────────────────────────────────────────────────────┐
│  顺序节点特性                                              │
└─────────────────────────────────────────────────────────────────┘

顺序节点自动添加递增序号：

1. 序号规则
   ├── 10位数字序号
   ├── 从0000000000开始
   ├── 递增方式：原子递增
   ├── 最大值：9999999999
   └── 序号不重复

2. 序号格式
   ├── 固定10位数字
   ├── 不足10位前补0
   └── 示例：0000000001

3. 持久顺序节点
   ├── 持久节点特性
   ├── 添加递增序号
   └── 示例：/queue/task0000000001

4. 临时顺序节点
   ├── 临时节点特性
   ├── 添加递增序号
   └── 示例：/lock/lock0000000001

5. 使用场景
   ├── 分布式队列
   ├── 分布式锁
   ├── 任务调度
   └── 唯一命名

6. 序号共享
   ├── 不同父节点的序号独立
   ├── /queue/node1 -> /queue/node10000000001
   └── /queue/node2 -> /queue/node20000000001
```

### 4.4.2 顺序节点操作

```bash
# 顺序节点操作

# 启动Zookeeper
bin/zkCli.sh

# 创建持久顺序节点
create -s /queue/task "Task 1"
# 结果：/queue/task0000000001

create -s /queue/task "Task 2"
# 结果：/queue/task0000000002

create -s /queue/task "Task 3"
# 结果：/queue/task0000000003

# 查看顺序节点
ls /queue

# 预期输出：
# [task0000000001, task0000000002, task0000000003]

# 读取顺序节点
get /queue/task0000000001

# 创建临时顺序节点
create -e -s /lock/client "Client 1"
# 结果：/lock/client0000000001

create -e -s /lock/client "Client 2"
# 结果：/lock/client0000000002

create -e -s /lock/client "Client 3"
# 结果：/lock/client0000000003

# 查看临时顺序节点
ls /lock

# 预期输出：
# [client0000000001, client0000000002, client0000000003]

# 查看节点详情
stat /lock/client0000000001

# 预期输出：
# ephemeralOwner = 0x1234567890abcdef

# 断开Session后，临时顺序节点自动删除
quit

# 重新连接
bin/zkCli.sh

# 验证临时顺序节点已删除
ls /lock

# 预期输出：
# []

# 验证持久顺序节点仍存在
ls /queue

# 预期输出：
# [task0000000001, task0000000002, task0000000003]
```

---

## 4.5 ZNode属性详解

### 4.5.1 ZNode属性列表

```
ZNode属性列表：

┌─────────────────────────────────────────────────────────────────┐
│  ZNode属性详解                                          │
└─────────────────────────────────────────────────────────────────┘

1. czxid：创建节点的事务ID
   ├── 格式：ZXID
   ├── 说明：创建节点时的ZXID
   └── 用途：追踪节点创建历史

2. ctime：创建时间
   ├── 格式：时间戳（毫秒）
   ├── 说明：节点创建时间
   └── 用途：审计和监控

3. mzxid：最后修改节点的事务ID
   ├── 格式：ZXID
   ├── 说明：最后一次修改节点的ZXID
   └── 用途：追踪节点修改历史

4. mtime：最后修改时间
   ├── 格式：时间戳（毫秒）
   ├── 说明：节点最后修改时间
   └── 用途：审计和监控

5. pzxid：最后修改子节点列表的事务ID
   ├── 格式：ZXID
   ├── 说明：最后一次修改子节点列表的ZXID
   ├── 用途：追踪子节点变化
   └── 注意：修改子节点数据不更新pzxid

6. cversion：子节点版本号
   ├── 格式：整数
   ├── 说明：子节点数量变化次数
   └── 用途：乐观锁

7. dataVersion：数据版本号
   ├── 格式：整数
   ├── 说明：数据修改次数
   ├── 用途：乐观锁
   └── 注意：从0开始递增

8. aclVersion：ACL版本号
   ├── 格式：整数
   ├── 说明：ACL修改次数
   └── 用途：权限管理

9. ephemeralOwner：临时节点所有者
   ├── 格式：Session ID
   ├── 说明：如果是临时节点，为Session ID
   ├── 说明：如果是持久节点，为0
   └── 用途：识别临时节点所有者

10. dataLength：数据长度
    ├── 格式：整数（字节）
    ├── 说明：节点数据长度
    └── 限制：最大1MB

11. numChildren：子节点数量
    ├── 格式：整数
    ├── 说明：直接子节点数量
    └── 用途：统计节点
```

### 4.5.2 ZNode属性操作

```bash
# ZNode属性操作

# 启动Zookeeper
bin/zkCli.sh

# 创建节点
create /test "Hello" -s

# 查看所有属性
get -s /test

# 预期输出：
# Hello
# cZxid = 0x5
# ctime = 1234567890000
# mZxid = 0x5
# mtime = 1234567890000
# pZxid = 0x5
# cversion = 0
# dataVersion = 0
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 5
# numChildren = 0

# 修改数据，观察属性变化
set /test "World"

# 查看变化后的属性
get -s /test

# 预期输出：
# World
# cZxid = 0x5
# ctime = 1234567890000
# mZxid = 0x6          <- 变化
# mtime = 1234567890001 <- 变化
# pZxid = 0x5
# cversion = 0
# dataVersion = 1          <- 变化（0->1）
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 5
# numChildren = 0

# 添加子节点，观察属性变化
create /test/child1 "Child 1"
create /test/child2 "Child 2"

# 查看变化后的属性
get -s /test

# 预期输出：
# World
# cZxid = 0x5
# ctime = 1234567890000
# mZxid = 0x6
# mtime = 1234567890001
# pZxid = 0x8              <- 变化（最后修改子节点列表的ZXID）
# cversion = 2              <- 变化（子节点版本：0->2）
# dataVersion = 1
# aclVersion = 0
# ephemeralOwner = 0x0
# dataLength = 5
# numChildren = 2           <- 变化（0->2）
```

---

## 4.6 实战：使用不同类型的ZNode

### 4.6.1 配置管理

```bash
# 配置管理示例

# 启动Zookeeper
bin/zkCli.sh

# 创建配置节点
create /app/config "App Configuration"
create /app/config/database "mysql://localhost:3306"
create /app/config/cache "redis://localhost:6379"
create /app/config/server "8080"

# 查看配置
get /app/config
get /app/config/database
get /app/config/cache
get /app/config/server

# 更新配置
set /app/config/database "mysql://remote:3306"
set /app/config/cache "redis://remote:6379"
set /app/config/server "9090"

# 验证更新
get -s /app/config/database

# 预期输出：
# mysql://remote:3306
# dataVersion = 1

# 使用版本号进行原子更新（乐观锁）
set /app/config/server "8081" -v 1

# 预期输出：
# 成功更新

# 使用错误版本号更新（乐观锁失败）
set /app/config/server "8082" -v 0

# 预期输出：
# version No is not correct : 0
```

### 4.6.2 服务注册

```bash
# 服务注册示例

# 启动Zookeeper
bin/zkCli.sh

# 创建服务根节点
create /services "Services" -c

# 预期输出：
# Created -c container: /services
# Warning: ./services can only have children 0, 256, 1000, 10000 or an increased amount

# 创建服务类型节点
create /services/kafka "Kafka Brokers"
create /services/zookeeper "Zookeeper Servers"

# 模拟服务注册（创建临时节点）
# Session 1: Kafka Broker 1 注册
create -e /services/kafka/broker1 "192.168.1.101:9092"

# Session 2: Kafka Broker 2 注册
# （在另一个终端或连接中执行）
create -e /services/kafka/broker2 "192.168.1.102:9092"

# 查看注册的服务
ls /services/kafka

# 预期输出：
# [broker1, broker2]

# 获取服务地址
get /services/kafka/broker1
get /services/kafka/broker2

# 模拟服务下线
# 在创建临时节点的Session中执行
delete /services/kafka/broker1

# 或Session断开后自动删除

# 验证服务注销
ls /services/kafka

# 预期输出：
# [broker2]
```

### 4.6.3 分布式队列

```bash
# 分布式队列示例

# 启动Zookeeper
bin/zkCli.sh

# 创建队列根节点
create /queue "Task Queue"

# 生产者：添加任务
create -s /queue/task "Task 1"
create -s /queue/task "Task 2"
create -s /queue/task "Task 3"

# 查看队列
ls /queue

# 预期输出：
# [task0000000001, task0000000002, task0000000003]

# 获取任务（按顺序）
get /queue/task0000000001
get /queue/task0000000002
get /queue/task0000000003

# 消费任务（删除）
delete /queue/task0000000001
delete /queue/task0000000002
delete /queue/task0000000003

# 验证队列为空
ls /queue

# 预期输出：
# []
```

---

## 本章小结

- ZNode有四种类型：持久节点、临时节点、持久顺序节点、临时顺序节点
- 持久节点一直存在直到被显式删除，适合配置存储
- 临时节点与Session绑定，Session断开后自动删除，适合服务注册
- 顺序节点自动添加10位递增序号，从0000000000开始
- ZNode属性包括czxid、ctime、mzxid、mtime、pzxid、cversion、dataVersion、aclVersion、ephemeralOwner、dataLength、numChildren
- dataVersion用于乐观锁，ephemeralOwner用于识别临时节点所有者
- cversion记录子节点列表变化次数，pzxid记录最后修改子节点列表的ZXID
- 不同类型的ZNode适用于不同的场景：配置管理用持久节点，服务注册用临时节点，分布式队列用持久顺序节点，分布式锁用临时顺序节点

---

**下一章：Watch机制原理**
