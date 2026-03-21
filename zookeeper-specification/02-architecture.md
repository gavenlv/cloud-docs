# Zookeeper架构原理

## 2.1 Zookeeper架构概述

### 2.1.1 整体架构

```
Zookeeper架构：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper架构                                              │
└─────────────────────────────────────────────────────────────────┘

                        ┌─────────────────┐
                        │     Client      │
                        │   (任意数量)    │
                        └────────┬────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
             ┌──────┴──────┐     │     ┌──────┴──────┐
             │   Server1   │     │     │   Server2   │
             │  (Leader)   │◄────┼────►│  (Follower) │
             └──────┬──────┘     │     └──────┬──────┘
                    │            │            │
                    │      ┌─────┴─────┐      │
                    └──────┤  Learner  ├──────┘
                           │   Channel  │
                           └─────┬─────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
             ┌──────┴──────┐     │     ┌──────┴──────┐
             │   Server3   │     │     │   ServerN   │
             │(Observer)   │     │     │(Observer)   │
             └─────────────┘     │     └─────────────┘
                                 │
                        ┌────────┴────────┐
                        │  Zookeeper     │
                        │  Cluster       │
                        └─────────────────┘

架构说明：
1. Client：客户端应用，可以是任意数量
2. Server：Zookeeper服务器节点，包含Leader、Follower、Observer三种角色
3. Leader：集群领导者，处理所有写请求
4. Follower：集群跟随者，处理读请求，参与投票和选举
5. Observer：观察者，不参与投票，只处理读请求
6. Learner Channel：Leader和Learner之间的通信通道
```

### 2.1.2 核心组件

```
核心组件：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper核心组件                                      │
└─────────────────────────────────────────────────────────────────┘

1. Leader组件
   ├── Leader：集群领导者
   ├── Proposal stats：提案统计
   ├── Pending requests：待处理请求
   ├── LearnerCnxAcceptor：Learner连接接收器
   └── Writer：写请求处理器

2. Follower组件
   ├── Follower：集群跟随者
   ├── Learner：学习者
   ├── PeerPacketProcessor：数据包处理器
   └── FollowerRequestProcessor：请求处理器

3. Observer组件
   ├── Observer：观察者
   ├── Learner：学习者
   ├── ObserverRequestProcessor：请求处理器
   └── ObserverMaster：观察者管理器

4. 共享组件
   ├── RequestProcessor：请求处理器（链式）
   ├── ZKDatabase：数据库
   ├── SessionTracker：会话追踪器
   ├── WatchManager：监听管理器
   └── QuorumPeer：仲裁-peer
```

---

## 2.2 Leader-Follower模式

### 2.2.1 角色职责

```
角色职责：

┌─────────────────────────────────────────────────────────────────┐
│  Leader-Follower角色职责                               │
└─────────────────────────────────────────────────────────────────┘

1. Leader职责
   ├── 处理所有写请求
   ├── 发起事务提案（Proposal）
   ├── 管理集群配置
   ├── 分配事务ID（ZXID）
   ├── 协调数据同步
   └── 故障恢复

2. Follower职责
   ├── 处理读请求
   ├── 参与Leader选举投票
   ├── 同步Leader数据
   ├── 接收并处理Leader的Proposal
   ├── 向Leader发送ACK
   └── 故障时重新选举

3. Observer职责
   ├── 处理读请求
   ├── 同步Leader数据
   ├── 不参与投票
   └── 扩展集群读性能

4. 角色对比
   ┌──────────┬────────┬────────┬────────┐
   │   职责   │ Leader │Follower│Observer│
   ├──────────┼────────┼────────┼────────┤
   │ 处理写请求│   ✓    │   ✗    │   ✗    │
   │ 处理读请求│   ✓    │   ✓    │   ✓    │
   │ 参与投票  │   ✓    │   ✓    │   ✗    │
   │ 数据同步  │   ✓    │   ✓    │   ✓    │
   │ 发起提案  │   ✓    │   ✗    │   ✗    │
   └──────────┴────────┴────────┴────────┘
```

### 2.2.2 请求处理流程

```
请求处理流程：

┌─────────────────────────────────────────────────────────────────┐
│  写请求处理流程                                        │
└─────────────────────────────────────────────────────────────────┘

1. 客户端发起写请求
   Client -> Follower/Observer: create /test "value"

2. 转发给Leader
   Follower/Observer -> Leader: 请求（包含事务）

3. Leader处理请求
   ├── 生成事务Proposal
   ├── 分配ZXID
   ├── 写入事务日志
   └── 发送给所有Follower

4. Follower处理Proposal
   ├── 写入事务日志
   ├── 发送ACK给Leader
   └── （Observer只接收不同步）

5. Leader统计ACK
   ├── 收到过半ACK
   ├── 提交事务
   ├── 通知所有Follower提交
   └── 回复客户端

6. 客户端收到响应
   Leader -> Client: 响应（成功/失败）

详细流程：

┌─────────┐    create /test    ┌────────────┐    Proposal    ┌────────────┐
│ Client  │ ──────────────────►│  Follower  │ ─────────────►│   Leader    │
└─────────┘                    └────────────┘               └──────┬─────┘
                                   ▲                                  │
                                   │                                  │
                            ┌──────┴──────┐                    ┌──────┴──────┐
                            │  Follower1  │◄──────────────────│  Proposal   │
                            └──────┬──────┘                    └──────┬──────┘
                                   │                                  │
                            ┌──────┴──────┐                    ┌──────┴──────┐
                            │  Follower2  │◄──────────────────│     ACK     │
                            └─────────────┘                    └──────┬──────┘
                                                                      │
                                                               ┌──────┴──────┐
                                                               │  统计ACK    │
                                                               │  超过半数   │
                                                               └──────┬──────┘
                                                                      │
                                                               ┌──────┴──────┐
                                                               │  提交事务   │
                                                               └──────┬──────┘
                                                                      │
                                                     ┌───────────────┼───────────────┐
                                                     │               │               │
                                              ┌──────┴──────┐ ┌──────┴──────┐ ┌──────┴──────┐
                                              │  Commit    │ │  Commit    │ │  Commit    │
                                              │ 通知Follower│ │ 通知Follower│ │ 回复Client │
                                              └─────────────┘ └─────────────┘ └─────────────┘
```

### 2.2.3 读请求处理

```
读请求处理流程：

┌─────────────────────────────────────────────────────────────────┐
│  读请求处理流程                                        │
└─────────────────────────────────────────────────────────────────┘

1. 客户端发起读请求
   Client -> Server: get /test

2. Server本地处理
   ├── 直接从内存数据库读取
   ├── 返回数据给客户端
   └── 不需要与Leader交互

3. 客户端收到响应
   Server -> Client: 数据

特点：
├── 低延迟：无需网络通信
├── 可能不是最新数据（Follower同步有延迟）
└── 适合读多写少场景

注意：
├── Leader和Follower都可以处理读请求
├── 如果需要强一致性读，使用sync命令
└── Observer处理读请求与Follower相同
```

---

## 2.3 Zab协议详解

### 2.3.1 Zab协议状态

```
Zab协议状态：

┌─────────────────────────────────────────────────────────────────┐
│  Zab协议状态                                              │
└─────────────────────────────────────────────────────────────────┘

1. 状态类型
   ├── LOOKING：选举状态，查找Leader
   ├── LEADING：领导状态，作为Leader
   └── FOLLOWING：跟随状态，作为Follower

2. 状态转换
   启动时：
   Server -> LOOKING -> (选举) -> LEADING 或 FOLLOWING

   Leader崩溃：
   Leader -> LOOKING -> (选举) -> FOLLOWING 或 LEADING

   Follower崩溃：
   Follower -> (重新连接) -> FOLLOWING

3. 状态机
   ┌───────────┐
   │  启动     │
   └──────┬────┘
          │
          ▼
   ┌───────────┐
   │ LOOKING   │◄──────────────┐
   │  (选举)   │               │
   └──┬────┬───┘               │
      │    │                    │
      │    ▼                    │
 ┌────┴┐ ┌─┴────────┐         │
 │LEAD │ │FOLLOWING  │         │
 │ ING │ │  跟随     │─────────┘
 └──┬──┘ └──────────┘  Leader崩溃
    │                          或重新选举
    │
    └──────────────────────────►(选举)
```

### 2.3.2 Zab协议消息

```
Zab协议消息类型：

┌─────────────────────────────────────────────────────────────────┐
│  Zab协议消息类型                                        │
└─────────────────────────────────────────────────────────────────┘

1. 消息类型
   ├── PROPOSAL：提案消息，Leader发起的事务提案
   ├── ACK：确认消息，Follower对提案的确认
   ├── COMMIT：提交消息，Leader通知提交事务
   ├── UPTODATE：同步完成消息，通知Learner同步完成
   ├── OBSERVERINFO：观察者信息，用于Observer注册
   ├── FOLLOWERINFO：跟随者信息，用于Follower注册
   └── LEADERINFO：领导者信息，用于Leader注册

2. 消息格式
   PROPOSAL消息：
   ├── Zxid：事务ID
   ├── Proposal Data：提案数据
   └── Proposal AppData：提案应用数据

   ACK消息：
   ├── Zxid：事务ID
   └── Ack Sid：确认的Server ID

3. 消息流程
   Leader:
   1. 接收客户端请求
   2. 生成Proposal(Zxid, data)
   3. 发送PROPOSAL给所有Follower
   4. 等待过半ACK
   5. 发送COMMIT给所有Server
   6. 应用到数据库

   Follower:
   1. 接收PROPOSAL
   2. 写入事务日志
   3. 发送ACK
   4. 接收COMMIT
   5. 应用到数据库
```

### 2.3.3 Zab协议特性

```
Zab协议特性：

┌─────────────────────────────────────────────────────────────────┐
│  Zab协议特性                                              │
└─────────────────────────────────────────────────────────────────┘

1. 消息顺序保证
   ├── 全局顺序：所有消息按照发送顺序处理
   ├── 因果顺序：来自同一个Leader的消息按顺序处理
   └── 传输顺序：消息按照先进先出顺序传输

2. 故障恢复保证
   ├── 持久性：只要Leader提交了，事务不会丢失
   ├── 完整性：事务要么被所有Server接受，要么都不接受
   ├── 一致性：读操作返回一致的数据视图
   └── 活跃性：如果Leader崩溃，会重新选举

3. 性能特性
   ├── 高吞吐量：批量处理请求
   ├── 低延迟：内存操作
   └── 可扩展性：Observer可以扩展读性能

4. 一致性级别
   ├── 顺序一致性：所有操作按照全局顺序执行
   ├── 线性一致性：读操作返回最新写入
   └── 最终一致性：允许短暂不一致
```

---

## 2.4 选举机制详解

### 2.4.1 选举算法

```
选举算法（FastLeaderElection）：

┌─────────────────────────────────────────────────────────────────┐
│  FastLeaderElection算法                                │
└─────────────────────────────────────────────────────────────────┘

1. 投票内容
   ├── logicalclock：逻辑时钟，选举轮次
   ├── epoch：朝代，选举轮次（与logicalclock相同）
   ├── zxid：最后提交的事务ID
   ├── sid：服务器ID
   └── state：服务器状态（LOOKING/LEADING/FOLLOWING）

2. 投票比较规则
   规则1：epoch大的优先
   规则2：epoch相等时，zxid大的优先
   规则3：epoch和zxid都相等时，sid大的优先

3. 选举过程
   阶段1：初始化
   ├── Server状态变为LOOKING
   ├── logicalclock加1
   ├── 生成投票（epoch, zxid, sid, 0）
   └── 发送给所有其他Server

   阶段2：投票交换
   ├── 发送自己的投票
   ├── 接收其他Server的投票
   └── 更新自己的投票（如果收到的更优）

   阶段3：投票统计
   ├── 统计投票
   ├── 当过半Server投票相同时
   └── 选举完成

4. 选举示例
   场景：3台Server（S1, S2, S3）
   myid: S1=1, S2=2, S3=3

   S1启动：
   logicalclock=1, epoch=1, zxid=0, sid=1
   状态LOOKING

   S2启动：
   logicalclock=1, epoch=1, zxid=0, sid=2
   状态LOOKING
   发送投票给S1
   S1收到S2的投票
   比较：S2的sid更大
   S1更新投票：(1, 1, 0, 2)

   S3启动：
   状态LOOKING
   发送投票给S1和S2
   S1和S2收到S3的投票
   比较：S3的sid最大
   S1和S2更新投票：(1, 1, 0, 3)

   选举完成：
   S3赢得选举，成为Leader
   S1和S2成为Follower
```

### 2.4.2 选举触发条件

```
选举触发条件：

┌─────────────────────────────────────────────────────────────────┐
│  选举触发条件                                          │
└─────────────────────────────────────────────────────────────────┘

1. 触发条件
   ├── 服务器启动时
   ├── Leader崩溃时
   ├── Follower无法连接Leader时
   ├── 网络分区时
   └── Leader无响应超过阈值时

2. Leader崩溃检测
   ├── Follower检测：心跳超时
   ├── Observer检测：心跳超时
   ├── Leader自己检测：无法提交事务
   └── 客户端检测：会话超时

3. 选举过程
   检测到Leader不可用 ->
   进入LOOKING状态 ->
   发起选举 ->
   等待投票结果 ->
   确定新的Leader ->
   进入正常工作状态

4. 选举时间
   ├── 选举初始化：几毫秒
   ├── 投票交换：几毫秒到几秒
   ├── 选举完成：通常几秒内
   └── 恢复同步：几秒到几分钟
```

### 2.4.3 Observer配置

```
Observer配置：

┌─────────────────────────────────────────────────────────────────┐
│  Observer配置                                              │
└─────────────────────────────────────────────────────────────────┘

1. Observer作用
   ├── 扩展集群读性能
   ├── 不参与投票
   ├── 不影响写性能
   └── 用于跨数据中心部署

2. Observer配置
   # zoo.cfg
   server.1=localhost:2888:3888
   server.2=localhost:2889:3889
   server.3=localhost:2890:3890
   server.4=localhost:2891:3891:observer

3. Observer同步
   ├── Observer从Leader同步数据
   ├── Observer不参与投票
   ├── Observer处理读请求
   └── Observer不处理写请求

4. Observer配置示例
   # zoo.cfg
   tickTime=2000
   dataDir=/tmp/zookeeper
   clientPort=2181
   initLimit=10
   syncLimit=5

   # Observer配置
   server.1=zoo1:2888:3888
   server.2=zoo2:2888:3888
   server.3=zoo3:2888:3888
   server.4=zoo4:2888:3888:observer

   # 观察者配置
   peerType=observer

5. Observer使用场景
   ├── 跨数据中心部署
   ├── 读多写少场景
   ├── 需要扩展读性能
   └── 需要容错能力
```

---

## 2.5 数据同步机制

### 2.5.1 同步类型

```
同步类型：

┌─────────────────────────────────────────────────────────────────┐
│  数据同步类型                                              │
└─────────────────────────────────────────────────────────────────┘

1. DIFF同步（差异同步）
   条件：Follower与Leader有少量差异
   过程：只同步差异部分
   优点：同步速度快
   适用：差异较小的情况

2. TRUNC同步（回滚同步）
   条件：Follower有Leader没有的事务
   过程：删除多余的事务
   优点：保持数据一致
   适用：Follower有冗余事务

3. SNAP同步（快照同步）
   条件：Follower与Leader差异较大
   过程：全量同步数据
   优点：简单可靠
   适用：差异较大的情况

4. 同步流程
   ┌──────────┐
   │ Follower │
   │  连接    │
   └────┬─────┘
        │
        ▼
   ┌──────────┐
   │  Leader   │
   │ 注册Follower│
   └────┬─────┘
        │
        ▼
   ┌──────────┐
   │ 比较ZXID │
   └──┬──────┘
       │
   ┌────┴─────┐
   │ 差异判断  │
   └──┬──────┘
       │
   ┌────┬─────┬────────┐
   │    │     │        │
   ▼    ▼     ▼        ▼
  DIFF  TRUNC  SNAP   UPTODATE
```

### 2.5.2 同步时机

```
同步时机：

┌─────────────────────────────────────────────────────────────────┐
│  同步时机                                              │
└─────────────────────────────────────────────────────────────────┘

1. 启动时同步
   ├── Follower启动
   ├── 连接Leader
   ├── 注册Learner
   ├── 同步数据
   └── 进入正常工作

2. Leader选举后同步
   ├── 选举出新的Leader
   ├── Leader成为LEADING状态
   ├── Learner连接新的Leader
   ├── 同步数据
   └── 进入正常工作

3. 运行中同步
   ├── Leader处理写请求
   ├── 发送Proposal给Follower
   ├── Follower处理Proposal
   ├── 发送ACK给Leader
   ├── Leader收到过半ACK
   ├── Leader提交事务
   └── 通知Follower提交

4. 故障恢复同步
   ├── Follower重新连接Leader
   ├── Leader检测Follower状态
   ├── 同步缺失的数据
   └── 恢复同步
```

### 2.5.3 同步优化

```
同步优化：

┌─────────────────────────────────────────────────────────────────┐
│  同步优化                                                │
└─────────────────────────────────────────────────────────────────┘

1. 并发同步
   ├── Leader并发发送Proposal
   ├── 多个Follower同时同步
   └── 提高同步吞吐量

2. 批量同步
   ├── 批量发送Proposal
   ├── 批量处理ACK
   └── 减少网络开销

3. 压缩同步
   ├── 对大数据进行压缩
   ├── 减少网络传输
   └── 提高同步效率

4. 增量同步
   ├── 只同步增量数据
   ├── 跳过已同步数据
   └── 减少同步时间

5. 同步配置
   # zoo.cfg
   # 同步队列大小
   learnerQueueSize=500

   # 同步超时
   syncTimeout=2000

   # 同步窗口大小
   sync.window.size=10
```

---

## 2.6 实战：理解Zookeeper架构

### 2.6.1 搭建集群

```bash
# 搭建Zookeeper集群

# 1. 创建三个目录
mkdir -p zk1 zk2 zk3

# 2. 创建配置文件
for i in 1 2 3; do
  cat > zk$i/conf/zoo.cfg << EOF
tickTime=2000
dataDir=/tmp/zk$i
clientPort=218$i
initLimit=10
syncLimit=5
admin.enableServer=true
server.1=localhost:2887:3887
server.2=localhost:2888:3888
server.3=localhost:2889:3889
EOF
done

# 3. 创建myid文件
echo "1" > zk1/data/myid
echo "2" > zk2/data/myid
echo "3" > zk3/data/myid

# 4. 启动集群
zk1/bin/zkServer.sh start
zk2/bin/zkServer.sh start
zk3/bin/zkServer.sh start

# 5. 检查状态
zk1/bin/zkServer.sh status
zk2/bin/zkServer.sh status
zk3/bin/zkServer.sh status

# 预期输出：
# ZooKeeper JMX enabled by default
# Using config: /path/to/zk1/bin/../conf/zoo.cfg
# Mode: leader (或 follower)

# 6. 连接集群
zk1/bin/zkCli.sh -server localhost:2181,localhost:2182,localhost:2183

# 7. 测试集群
create /test "cluster"
get /test

# 预期输出：
# cluster
```

### 2.6.2 添加Observer

```bash
# 添加Observer节点

# 1. 创建Observer目录
mkdir -p zk4

# 2. 创建Observer配置
cat > zk4/conf/zoo.cfg << 'EOF'
tickTime=2000
dataDir=/tmp/zk4
clientPort=2184
initLimit=10
syncLimit=5
admin.enableServer=true
server.1=localhost:2887:3887
server.2=localhost:2888:3888
server.3=localhost:2889:3889
server.4=localhost:2890:3890:observer
peerType=observer
EOF

# 3. 创建myid文件
echo "4" > zk4/data/myid

# 4. 启动Observer
zk4/bin/zkServer.sh start

# 5. 检查Observer状态
zk4/bin/zkServer.sh status

# 预期输出：
# Mode: observer

# 6. 测试Observer读
zk1/bin/zkCli.sh -server localhost:2181,localhost:2184
get /test

# 预期输出：
# cluster
```

### 2.6.3 模拟故障

```bash
# 模拟故障场景

# 场景1：Leader崩溃

# 1. 查看当前状态
zk1/bin/zkServer.sh status

# 2. 停止Leader
# 如果Leader是zk1
zk1/bin/zkServer.sh stop

# 3. 观察选举
# 查看其他节点状态
zk2/bin/zkServer.sh status
zk3/bin/zkServer.sh status

# 预期：新的Leader被选举出来

# 4. 重启原Leader
zk1/bin/zkServer.sh start

# 5. 查看状态
zk1/bin/zkServer.sh status
# zk1会变成Follower

# 场景2：Follower崩溃

# 1. 停止Follower
zk2/bin/zkServer.sh stop

# 2. 测试读
zk3/bin/zkCli.sh -server localhost:2183
get /test

# 3. 测试写
zk3/bin/zkCli.sh -server localhost:2183
create /follower_test "test"

# 4. 重启Follower
zk2/bin/zkServer.sh start

# 5. 验证数据同步
zk2/bin/zkCli.sh -server localhost:2182
get /follower_test
```

---

## 本章小结

- Zookeeper架构采用Leader-Follower模式，包含Leader、Follower、Observer三种角色
- Leader处理所有写请求，Follower处理读请求并参与投票，Observer只处理读请求不参与投票
- Zab协议包括恢复模式（Leader选举）和广播模式（数据同步）
- Leader选举使用FastLeaderElection算法，基于Epoch、ZXID、ServerID进行优先级比较
- 数据同步包括DIFF同步、TRUNC同步、SNAP同步三种类型
- Observer用于扩展集群读性能，不参与投票
- 写请求通过Proposal-ACK-Commit机制保证一致性
- 读请求直接在本地处理，延迟低但可能不是最新数据

---

**下一章：Zookeeper数据模型**
