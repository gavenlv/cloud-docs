# Watch机制原理

## 5.1 Watch机制概述

### 5.1.1 Watch的核心概念

```
Watch机制核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  Watch机制概述                                              │
└─────────────────────────────────────────────────────────────────┘

Watch是Zookeeper提供的实时通知机制：

1. Watch基本概念
   ├── 客户端设置Watcher
   ├── 服务端感知变化
   ├── 服务端通知客户端
   ├── 客户端处理事件
   └── 一次性触发

2. Watch特点
   ├── 一次性：触发后自动失效
   ├── 异步通知：服务端异步推送
   ├── 客户端串行处理：客户端按顺序处理事件
   ├── 轻量级：只通知变化类型
   └── 最终一致：可能存在短暂不一致

3. Watch设置方式
   ├── get /path watch
   ├── ls /path watch
   └── API调用设置Watcher

4. Watch事件类型
   ├── NodeCreated：节点创建
   ├── NodeDeleted：节点删除
   ├── NodeDataChanged：节点数据变化
   ├── NodeChildrenChanged：子节点列表变化
   └── None：连接状态变化

5. Watch使用场景
   ├── 配置变更通知
   ├── 服务注册/注销
   ├── 分布式锁
   ├── Leader选举
   └── 依赖关系管理
```

### 5.1.2 Watch机制原理

```
Watch机制原理：

┌─────────────────────────────────────────────────────────────────┐
│  Watch机制原理                                              │
└─────────────────────────────────────────────────────────────────┘

Watch机制的实现原理：

1. 服务端实现
   ├── WatchManager管理所有Watcher
   ├── DataTree存储Watcher
   ├── 事务处理触发Watcher
   ├── 异步发送给客户端
   └── 一次性标记

2. 客户端实现
   ├── ClientCnxn管理Watcher
   ├── SendThread接收事件
   ├── EventThread处理事件
   ├── Watcher回调执行
   └── 重新设置Watcher（可选）

3. 通信机制
   ├── 基于TCP长连接
   ├── 事件异步推送
   ├── 心跳保持连接
   └── 自动重连

4. Watch注册流程
   客户端发送请求（含Watcher）
   -> 服务端注册Watcher
   -> 服务端存储Watcher
   -> 服务端返回响应
   -> 客户端等待事件

5. Watch触发流程
   数据变化
   -> 服务端查找Watcher
   -> 服务端发送事件
   -> 客户端接收事件
   -> 客户端处理事件
   -> 失效Watcher
```

---

## 5.2 Watch事件类型

### 5.2.1 事件类型详解

```
事件类型详解：

┌─────────────────────────────────────────────────────────────────┐
│  Watch事件类型                                              │
└─────────────────────────────────────────────────────────────────┘

1. None事件（连接状态）
   触发条件：连接状态变化
   事件类型：None
   含义：连接/断开/重连
   处理：检查连接状态

2. NodeCreated事件
   触发条件：节点被创建
   事件类型：NodeCreated
   路径：创建的节点路径
   处理：获取节点数据

3. NodeDeleted事件
   触发条件：节点被删除
   事件类型：NodeDeleted
   路径：删除的节点路径
   处理：清理相关资源

4. NodeDataChanged事件
   触发条件：节点数据被修改
   事件类型：NodeDataChanged
   路径：修改的节点路径
   处理：获取最新数据

5. NodeChildrenChanged事件
   触发条件：子节点列表变化
   事件类型：NodeChildrenChanged
   路径：父节点路径
   处理：重新获取子节点列表

事件类型对应关系：
┌─────────────────────────┬────────────────────────────┐
│       操作             │        事件类型             │
├─────────────────────────┼────────────────────────────┤
│ create /path           │ NodeCreated                 │
│ delete /path           │ NodeDeleted                │
│ setData /path          │ NodeDataChanged            │
│ create /path/child     │ NodeChildrenChanged(父节点) │
│ delete /path/child     │ NodeChildrenChanged(父节点) │
└─────────────────────────┴────────────────────────────┘
```

### 5.2.2 事件对象结构

```java
// WatchedEvent对象结构
// org.apache.zookeeper.WatchedEvent

public class WatchedEvent {
    private final KeeperState keeperState;  // 连接状态
    private final EventType eventType;      // 事件类型
    private final String path;              // 触发事件的路径

    public KeeperState getKeeperState() {
        return keeperState;
    }

    public EventType getEventType() {
        return eventType;
    }

    public String getPath() {
        return path;
    }
}

// KeeperState枚举
enum KeeperState {
    Unknown,          // 未知状态
    Disconnected,     // 断开连接
    NoSyncConnected,  // 未同步连接
    ConnectedReadOnly,// 只读连接
    SyncConnected,    // 同步连接
    AuthFailed,       // 认证失败
    ConnectedRequireSASL, // 需要SASL
    Expired,          // 会话过期
    Closed           // 连接关闭
}

// EventType枚举
enum EventType {
    None,              // 无
    NodeCreated,       // 节点创建
    NodeDeleted,        // 节点删除
    NodeDataChanged,    // 节点数据变化
    NodeChildrenChanged,// 子节点变化
    DataWatchRemoved,   // 数据Watcher删除
    ChildWatchRemoved,  // 子节点Watcher删除
    watchesWatchRemoved // 所有Watcher删除
}
```

---

## 5.3 Watch触发原理

### 5.3.1 触发流程

```
Watch触发流程：

┌─────────────────────────────────────────────────────────────────┐
│  Watch触发流程                                              │
└─────────────────────────────────────────────────────────────────┘

1. Watch注册
   客户端：
   get /path watch=true
   ->
   服务端：
   注册Watcher到WatchManager
   返回节点数据

2. Watch等待
   客户端：
   等待事件
   ->
   服务端：
   监控数据变化

3. Watch触发
   客户端1：
   set /path "newdata"
   ->
   服务端：
   检测数据变化
   查找相关Watcher
   发送事件给客户端2

4. Watch处理
   客户端2：
   接收事件
   ->
   EventThread：
   回调Watcher
   处理业务逻辑

5. Watch失效
   Watch一次性触发后失效
   如果需要再次监控，需要重新注册

详细触发流程：

┌──────────┐    set /path    ┌─────────────┐    事务处理    ┌──────────────┐
│ Client1 │ ───────────────►│   服务端    │ ─────────────►│  DataTree   │
└──────────┘                └─────────────┘               └──────┬───────┘
                                                                │
                                                                ▼
                                                         ┌──────────────┐
                                                         │ WatchManager │
                                                         └──────┬───────┘
                                                                │
                                                                ▼
                                                         ┌──────────────┐
                                                         │  查找Watcher │
                                                         └──────┬───────┘
                                                                │
                                                                ▼
┌──────────┐    事件推送    ┌─────────────┐               ┌──────────────┐
│ Client2 │ ◄──────────────│  SendThread │◄──────────────│  事件封装    │
└──────────┘                └─────────────┘               └──────────────┘
        │
        ▼
┌──────────────┐
│ EventThread  │
│  回调Watcher │
└──────────────┘
```

### 5.3.2 触发条件

```
触发条件：

┌─────────────────────────────────────────────────────────────────┐
│  Watch触发条件                                              │
└─────────────────────────────────────────────────────────────────┘

1. NodeCreated触发
   条件：节点被创建
   命令：create /path
   监听：get /path watch=true 或 exists /path watch=true

2. NodeDeleted触发
   条件：节点被删除
   命令：delete /path
   监听：get /path watch=true 或 exists /path watch=true

3. NodeDataChanged触发
   条件：节点数据被修改
   命令：set /path "newdata"
   监听：get /path watch=true 或 exists /path watch=true

4. NodeChildrenChanged触发
   条件：子节点列表变化
   命令：create /path/child 或 delete /path/child
   监听：ls /path watch=true 或 getChildren /path watch=true

5. None触发（连接状态）
   条件：连接状态变化
   状态：Disconnected/SyncConnected/Expired
   监听：所有操作都可以触发

6. 不触发的情况
   ├── setData值相同
   ├── create相同节点（已存在）
   ├── delete不存在节点
   └── setAcl相同权限
```

---

## 5.4 Watch使用场景

### 5.4.1 配置变更监听

```
配置变更监听：

┌─────────────────────────────────────────────────────────────────┐
│  配置变更监听                                              │
└─────────────────────────────────────────────────────────────────┘

场景：监听配置变化，实时更新应用配置

1. 配置存储
   /config/
   ├── database
   ├── cache
   └── server

2. Watch设置
   客户端：
   get -w /config/database

3. 配置变更
   管理员：
   set /config/database "mysql://newhost:3306"

4. 事件通知
   客户端收到NodeDataChanged事件
   重新获取配置
   更新本地配置

示例代码：
```java
public class ConfigWatcher implements Watcher {
    private final ZooKeeper zk;
    private final String configPath;

    public ConfigWatcher(ZooKeeper zk, String configPath) {
        this.zk = zk;
        this.configPath = configPath;
    }

    @Override
    public void process(WatchedEvent event) {
        if (event.getType() == EventType.NodeDataChanged) {
            try {
                byte[] data = zk.getData(configPath, true, null);
                String newConfig = new String(data);
                System.out.println("配置更新: " + newConfig);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
```
```

### 5.4.2 服务发现

```
服务发现：

┌─────────────────────────────────────────────────────────────────┐
│  服务发现                                              │
└─────────────────────────────────────────────────────────────────┘

场景：监听服务节点变化，实现动态服务发现

1. 服务注册
   /services/
   ├── kafka/
   │   ├── broker1 -> "192.168.1.101:9092"
   │   └── broker2 -> "192.168.1.102:9092"
   └── zookeeper/
       ├── server1 -> "192.168.1.101:2181"
       └── server2 -> "192.168.1.102:2181"

2. Watch设置
   客户端：
   ls -w /services/kafka

3. 服务变化
   新服务上线：create -e /services/kafka/broker3 "192.168.1.103:9092"
   服务下线：delete /services/kafka/broker3

4. 事件通知
   客户端收到NodeChildrenChanged事件
   重新获取服务列表
   更新本地服务缓存

示例代码：
```java
public class ServiceDiscovery implements Watcher {
    private final ZooKeeper zk;
    private final String servicePath;
    private List<String> services = new ArrayList<>();

    public ServiceDiscovery(ZooKeeper zk, String servicePath) {
        this.zk = zk;
        this.servicePath = servicePath;
    }

    @Override
    public void process(WatchedEvent event) {
        if (event.getType() == EventType.NodeChildrenChanged) {
            try {
                List<String> newServices = zk.getChildren(servicePath, true);
                services.clear();
                services.addAll(newServices);
                System.out.println("服务列表更新: " + services);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void discover() throws Exception {
        services = zk.getChildren(servicePath, true);
        System.out.println("当前服务: " + services);
    }
}
```
```

### 5.4.3 Leader选举

```
Leader选举：

┌─────────────────────────────────────────────────────────────────┐
│  Leader选举                                              │
└─────────────────────────────────────────────────────────────────┘

场景：监听Leader节点变化，实现故障转移

1. Leader存储
   /election/
   └── leader -> "leader_info"

2. Watch设置
   客户端：
   get -w /election/leader

3. Leader变化
   Leader宕机
   Session断开
   临时节点删除

4. 事件通知
   客户端收到NodeDeleted事件
   重新竞争Leader
   选出新的Leader

示例代码：
```java
public class LeaderElection implements Watcher {
    private final ZooKeeper zk;
    private final String electionPath;
    private String currentLeader;

    @Override
    public void process(WatchedEvent event) {
        if (event.getType() == EventType.NodeDeleted) {
            if (event.getPath().equals(electionPath + "/leader")) {
                try {
                    electLeader();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    public void electLeader() throws Exception {
        List<String> children = zk.getChildren(electionPath, true);
        Collections.sort(children);
        String newLeader = children.get(0);
        currentLeader = newLeader;
        System.out.println("新Leader: " + newLeader);
    }
}
```
```

---

## 5.5 Watch注意事项

### 5.5.1 Watch限制

```
Watch限制：

┌─────────────────────────────────────────────────────────────────┐
│  Watch限制                                              │
└─────────────────────────────────────────────────────────────────┘

1. 一次性触发
   ├── Watch触发后自动失效
   ├── 需要重新注册才能继续监控
   ├── 可能丢失中间变化
   └── 建议：收到事件后立即重新注册

2. 异步通知
   ├── 服务端异步推送事件
   ├── 不保证实时性
   ├── 不保证顺序
   └── 可能存在延迟

3. 客户端串行处理
   ├── 事件按接收顺序处理
   ├── 一个Watcher处理阻塞后续事件
   ├── 建议：快速处理事件
   └── 建议：使用线程池处理

4. 内存限制
   ├── 每个Watcher占用内存
   ├── Watcher数量有限制
   └── 建议：合理使用Watcher

5. 连接断开
   ├── 连接断开时Watcher失效
   ├── 重连后需要重新注册
   └── 建议：监听None事件处理重连

6. 数据大小
   ├── Watch事件只包含路径
   ├── 不包含具体数据
   ├── 需要主动获取数据
   └── 建议：结合get获取数据
```

### 5.5.2 最佳实践

```
最佳实践：

┌─────────────────────────────────────────────────────────────────┐
│  Watch最佳实践                                              │
└─────────────────────────────────────────────────────────────────┘

1. 事件处理
   ├── 快速处理事件，避免阻塞
   ├── 收到事件后立即重新注册
   ├── 使用线程池处理事件
   └── 处理异常情况

2. 连接管理
   ├── 监听连接状态变化
   ├── 重连时重新注册Watcher
   ├── 处理好Session过期
   └── 使用ConnectionWatcher

3. 错误处理
   ├── 处理KeeperException
   ├── 处理InterruptedException
   ├── 处理Exception
   └── 记录错误日志

4. 性能优化
   ├── 减少Watcher数量
   ├── 合理设置监控节点
   ├── 使用一次性Watcher
   └── 避免频繁创建删除

5. 代码示例
```java
public class WatcherExample implements Watcher {
    private final ZooKeeper zk;
    private final CountDownLatch latch = new CountDownLatch(1);

    @Override
    public void process(WatchedEvent event) {
        switch (event.getState()) {
            case SyncConnected:
                latch.countDown();
                break;
            case Disconnected:
                System.out.println("连接断开");
                break;
            case Expired:
                System.out.println("会话过期");
                break;
        }

        if (event.getType() == EventType.NodeDataChanged) {
            try {
                byte[] data = zk.getData(event.getPath(), true, null);
                System.out.println("数据更新: " + new String(data));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
```
```

---

## 5.6 实战：使用Watch机制

### 5.6.1 CLI使用Watch

```bash
# CLI使用Watch示例

# 启动Zookeeper CLI
bin/zkCli.sh

# 终端1：设置Watch监控节点
get /test watch

# 终端2：修改节点数据
set /test "new value"

# 终端1：收到事件
# WatchedEvent state:SyncConnected type:NodeDataChanged path:/test

# 设置子节点Watch
ls /services watch

# 终端2：创建子节点
create /services/kafka "kafka"

# 终端1：收到事件
# WatchedEvent state:SyncConnected type:NodeChildrenChanged path:/services

# 监听连接状态
# 连接状态变化会收到None事件
```

### 5.6.2 Java API使用Watch

```java
// Java API使用Watch示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.WatchedEvent;
import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.data.Stat;

import java.io.IOException;
import java.util.concurrent.CountDownLatch;

public class WatcherDemo implements Watcher {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final int SESSION_TIMEOUT = 3000;
    private ZooKeeper zk;
    private CountDownLatch latch = new CountDownLatch(1);

    public void connect() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, SESSION_TIMEOUT, this);
        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    @Override
    public void process(WatchedEvent event) {
        System.out.println("事件: " + event);

        if (event.getState() == Event.KeeperState.SyncConnected) {
            latch.countDown();
        }

        if (event.getType() == Event.EventType.NodeDataChanged) {
            try {
                byte[] data = zk.getData(event.getPath(), true, null);
                System.out.println("数据更新: " + new String(data));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (event.getType() == Event.EventType.NodeChildrenChanged) {
            try {
                System.out.println("子节点变化: " + zk.getChildren(event.getPath(), true));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void watchPath(String path) throws Exception {
        byte[] data = zk.getData(path, true, null);
        System.out.println("当前数据: " + (data != null ? new String(data) : "null"));
    }

    public void createPath(String path, String data) throws Exception {
        zk.create(path, data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
    }

    public void setData(String path, String data) throws Exception {
        zk.setData(path, data.getBytes(), -1);
    }

    public void close() throws InterruptedException {
        zk.close();
    }

    public static void main(String[] args) throws Exception {
        WatcherDemo demo = new WatcherDemo();
        demo.connect();

        demo.createPath("/test", "initial");
        demo.watchPath("/test");

        System.out.println("修改数据...");
        demo.setData("/test", "updated");

        Thread.sleep(1000);
        demo.close();
    }
}
```

### 5.6.3 Curator使用Watch

```java
// Curator使用Watch示例

import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.recipes.cache.*;
import org.apache.curator.retry.ExponentialBackoffRetry;

public class CuratorWatcherDemo {
    private static final String ZK_ADDRESS = "localhost:2181";

    public static void main(String[] args) throws Exception {
        CuratorFramework zk = CuratorFrameworkFactory.newClient(
            ZK_ADDRESS,
            new ExponentialBackoffRetry(1000, 3)
        );
        zk.start();

        // NodeCache: 监听单个节点变化
        NodeCache nodeCache = new NodeCache(zk, "/test");
        nodeCache.getListenable().addListener(() -> {
            System.out.println("节点变化: " + nodeCache.getCurrentData());
        });
        nodeCache.start();

        // PathChildrenCache: 监听子节点变化
        PathChildrenCache pathChildrenCache = new PathChildrenCache(zk, "/services", true);
        pathChildrenCache.getListenable().addListener((curator, event) -> {
            System.out.println("子节点事件: " + event);
        });
        pathChildrenCache.start();

        // TreeCache: 监听整个树变化
        TreeCache treeCache = new TreeCache(zk, "/app");
        treeCache.getListenable().addListener((curator, event) -> {
            System.out.println("树事件: " + event);
        });
        treeCache.start();

        Thread.sleep(60000);
        zk.close();
    }
}
```

---

## 本章小结

- Watch是Zookeeper提供的实时通知机制，用于监听数据变化
- Watch具有一次性、异步通知、客户端串行处理、轻量级等特点
- Watch事件类型包括None、NodeCreated、NodeDeleted、NodeDataChanged、NodeChildrenChanged
- Watch触发流程包括注册、等待、触发、处理、失效
- Watch使用场景包括配置变更监听、服务发现、Leader选举、分布式锁等
- Watch限制包括一次性触发、异步通知、客户端串行处理、内存限制等
- Watch最佳实践包括快速处理事件、监听连接状态、错误处理、性能优化
- Curator框架提供了更高级的Watch使用方式，包括NodeCache、PathChildrenCache、TreeCache

---

**下一章：CLI命令详解**
