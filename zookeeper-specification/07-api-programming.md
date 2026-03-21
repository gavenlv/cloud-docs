# API编程

## 7.1 Zookeeper API概述

### 7.1.1 API基本介绍

```
Zookeeper API概述：

┌─────────────────────────────────────────────────────────────────┐
│  Zookeeper API概述                                        │
└─────────────────────────────────────────────────────────────────┘

Zookeeper提供多种编程语言的API：

1. Java API（原生）
   ├── org.apache.zookeeper.ZooKeeper
   ├── org.apache.zookeeper.WatchedEvent
   ├── org.apache.zookeeper.CreateMode
   ├── org.apache.zookeeper.ZooDefs
   └── org.apache.zookeeper.data.*

2. Python API（zkpython）
   ├── zookeeper.ZooKeeper
   ├── zookeeper.WatchedEvent
   └── 使用ctypes调用C库

3. Curator（推荐）
   ├── curator.framework.CuratorFramework
   ├── curator.framework.CuratorFrameworkFactory
   ├── curator.recipes.cache.*
   └── 提供高级特性

4.ZkClient
   ├── com.101tec.ZkClient
   ├── 简化Zookeeper操作
   └── 提供事件监听

5. Node.js API（node-zookeeper）
   ├── zookeeper.Client
   └── 事件驱动

6. Go API（go-zookeeper）
   ├── github.com/samuel/go-zookeeper
   └── 原生Go实现
```

### 7.1.2 Java API核心类

```
Java API核心类：

┌─────────────────────────────────────────────────────────────────┐
│  Java API核心类                                          │
└─────────────────────────────────────────────────────────────────┘

1. ZooKeeper类
   构造函数：
   ZooKeeper(String connectString, int sessionTimeout, Watcher watcher)
   ZooKeeper(String connectString, int sessionTimeout, Watcher watcher, boolean canBeReadOnly)
   ZooKeeper(String connectString, int sessionTimeout, Watcher watcher, long sessionId, byte[] sessionPasswd)

   主要方法：
   String create(String path, byte[] data, List<ACL> acl, CreateMode mode)
   byte[] getData(String path, boolean watch, Stat stat)
   Stat setData(String path, byte[] data, int version)
   void delete(String path, int version)
   List<String> getChildren(String path, boolean watch)
   List<String> getChildren(String path, boolean watch, Stat stat)
   Stat exists(String path, boolean watch)
   void close()

2. Watcher接口
   void process(WatchedEvent event)

3. CreateMode枚举
   PERSISTENT
   PERSISTENT_SEQUENTIAL
   EPHEMERAL
   EPHEMERAL_SEQUENTIAL
   CONTAINER（3.5+）
   PERSISTENT_WITH_TTL（3.5+）

4. ZooDefs常量
   Ids.OPEN_ACL_UNSAFE - 完全开放的ACL
   Ids.CREATOR_ALL_ACL - 创建者所有权限
   Ids.READ_ACL_UNSAFE - 只读权限
```

---

## 7.2 连接管理

### 7.2.1 建立连接

```java
// 建立连接示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.ZooKeeper;
import java.io.IOException;
import java.util.concurrent.CountDownLatch;

public class ZKConnectionDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final int SESSION_TIMEOUT = 3000;
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException {
        CountDownLatch latch = new CountDownLatch(1);

        Watcher watcher = new Watcher() {
            @Override
            public void process(WatchedEvent event) {
                System.out.println("事件: " + event);
                if (event.getState() == Event.KeeperState.SyncConnected) {
                    latch.countDown();
                }
            }
        };

        zk = new ZooKeeper(ZK_ADDRESS, SESSION_TIMEOUT, watcher);
        latch.await();
        System.out.println("连接成功");

        // 使用连接
        try {
            System.out.println("节点: " + zk.getChildren("/", false));
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 关闭连接
        zk.close();
    }
}
```

### 7.2.2 连接参数配置

```java
// 连接参数配置示例

import org.apache.zookeeper.*;
import java.io.IOException;
import java.util.List;

public class ZKConnectionConfigDemo {
    private static final String ZK_ADDRESS = "localhost:2181,localhost:2182,localhost:2183";
    private static final int SESSION_TIMEOUT = 5000;
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException {
        Watcher watcher = event -> {
            System.out.println("事件: " + event);
        };

        // 完整参数构造函数
        // ZooKeeper(String connectString, int sessionTimeout, Watcher watcher, long sessionId, byte[] sessionPasswd)
        zk = new ZooKeeper(ZK_ADDRESS, SESSION_TIMEOUT, watcher);

        // 连接字符串格式
        // host1:port1,host2:port2,host3:port3
        // host1:port1,host2:port2,host3:port3/chroot

        // chroot后缀（3.2+）
        // localhost:2181/app
        // 所有操作都在/app下

        System.out.println("连接状态: " + zk.getState());

        Thread.sleep(1000);

        // 获取连接信息
        System.out.println("会话ID: " + zk.getSessionId());
        System.out.println("会话超时: " + zk.getSessionTimeout());

        zk.close();
    }
}
```

### 7.2.3 连接状态和重连

```java
// 连接状态和重连示例

import org.apache.zookeeper.*;
import java.io.IOException;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class ZKConnectionStateDemo implements Watcher {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;
    private static CountDownLatch connectLatch = new CountDownLatch(1);

    @Override
    public void process(WatchedEvent event) {
        System.out.println("事件类型: " + event.getType());
        System.out.println("连接状态: " + event.getState());
        System.out.println("路径: " + event.getPath());

        switch (event.getState()) {
            case SyncConnected:
                System.out.println("连接成功");
                connectLatch.countDown();
                break;
            case Disconnected:
                System.out.println("连接断开");
                break;
            case Expired:
                System.out.println("会话过期");
                break;
            case AuthFailed:
                System.out.println("认证失败");
                break;
            case ConnectedReadOnly:
                System.out.println("只读连接");
                break;
            case SaslAuthenticated:
                System.out.println("SASL认证");
                break;
            case NoSyncConnected:
                System.out.println("未同步连接");
                break;
            case Unknown:
                System.out.println("未知状态");
                break;
        }
    }

    public static void main(String[] args) throws IOException, InterruptedException {
        ZKConnectionStateDemo demo = new ZKConnectionStateDemo();
        zk = new ZooKeeper(ZK_ADDRESS, 3000, demo);
        connectLatch.await();

        // 检查状态
        System.out.println("当前状态: " + zk.getState());

        // 模拟断开
        System.out.println("模拟断开...");
        zk.close();

        // 等待重连
        Thread.sleep(5000);

        // 重新连接
        zk = new ZooKeeper(ZK_ADDRESS, 3000, demo);
        connectLatch.await();

        System.out.println("重新连接成功");
        zk.close();
    }
}
```

---

## 7.3 CRUD操作

### 7.3.1 创建节点

```java
// 创建节点示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.ACL;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.List;

public class ZKCreateDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});

        Thread.sleep(1000);

        // 创建持久节点
        String path1 = zk.create("/config", "config data".getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        System.out.println("创建持久节点: " + path1);

        // 创建临时节点
        String path2 = zk.create("/service/node1", "192.168.1.1:8080".getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL);
        System.out.println("创建临时节点: " + path2);

        // 创建顺序持久节点
        String path3 = zk.create("/queue/task", "task data".getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);
        System.out.println("创建顺序持久节点: " + path3);

        // 创建顺序临时节点
        String path4 = zk.create("/lock/lock", "lock data".getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
        System.out.println("创建顺序临时节点: " + path4);

        // 创建带ACL的节点
        List<ACL> acl = ZooDefs.Ids.CREATOR_ALL_ACL;
        String path5 = zk.create("/protected", "protected data".getBytes(),
            acl, CreateMode.PERSISTENT);
        System.out.println("创建带ACL节点: " + path5);

        // 创建容器节点（3.5+）
        String path6 = zk.create("/container", "container data".getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.CONTAINER);
        System.out.println("创建容器节点: " + path6);

        // 验证创建
        System.out.println("根节点子节点: " + zk.getChildren("/", false));

        zk.close();
    }
}
```

### 7.3.2 读取节点

```java
// 读取节点示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;

public class ZKReadDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});

        Thread.sleep(1000);

        // 创建测试节点
        zk.create("/test", "Hello Zookeeper".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        zk.create("/test/child1", "Child 1".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        zk.create("/test/child2", "Child 2".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);

        // 读取节点数据
        byte[] data = zk.getData("/test", false, null);
        System.out.println("节点数据: " + new String(data));

        // 读取节点数据（带状态）
        Stat stat = new Stat();
        data = zk.getData("/test", false, stat);
        System.out.println("节点数据: " + new String(data));
        System.out.println("状态: " + stat);

        // 读取节点数据（带监听）
        Watcher watcher = event -> {
            System.out.println("监听事件: " + event);
        };
        data = zk.getData("/test", watcher, null);
        System.out.println("节点数据: " + new String(data));

        // 检查节点是否存在
        Stat existsStat = zk.exists("/test", false);
        System.out.println("节点存在: " + (existsStat != null));

        // 获取子节点列表
        List<String> children = zk.getChildren("/test", false);
        System.out.println("子节点: " + children);

        // 获取子节点列表（带监听）
        children = zk.getChildren("/test", event -> {
            System.out.println("子节点变化: " + event);
        });
        System.out.println("子节点: " + children);

        zk.close();
    }
}
```

### 7.3.3 更新和删除节点

```java
// 更新和删除节点示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;

public class ZKUpdateDeleteDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});

        Thread.sleep(1000);

        // 创建测试节点
        String path = zk.create("/test", "Initial".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        System.out.println("创建节点: " + path);

        // 读取初始数据
        byte[] data = zk.getData("/test", false, null);
        System.out.println("初始数据: " + new String(data));

        // 获取初始版本
        Stat stat = new Stat();
        zk.getData("/test", false, stat);
        int version = stat.getVersion();
        System.out.println("初始版本: " + version);

        // 更新数据
        Stat setStat = zk.setData("/test", "Updated".getBytes(), version);
        System.out.println("更新后版本: " + setStat.getVersion());

        // 读取更新后数据
        data = zk.getData("/test", false, null);
        System.out.println("更新后数据: " + new String(data));

        // 使用错误版本更新（乐观锁失败）
        try {
            zk.setData("/test", "Failed".getBytes(), 0);
        } catch (KeeperException.BadVersionException e) {
            System.out.println("乐观锁失败: 版本不匹配");
        }

        // 获取最新版本
        stat = new Stat();
        zk.getData("/test", false, stat);
        int latestVersion = stat.getVersion();

        // 使用正确版本更新
        zk.setData("/test", "Success".getBytes(), latestVersion);
        System.out.println("乐观锁成功");

        // 读取最终数据
        data = zk.getData("/test", false, null);
        System.out.println("最终数据: " + new String(data));

        // 删除节点
        zk.delete("/test", -1);
        System.out.println("删除节点");

        // 验证删除
        System.out.println("节点存在: " + (zk.exists("/test", false) != null));

        zk.close();
    }
}
```

---

## 7.4 监听操作

### 7.4.1 设置监听

```java
// 设置监听示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.List;

public class ZKWatchDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        Watcher watcher = event -> {
            System.out.println("监听事件: " + event);
            System.out.println("事件类型: " + event.getType());
            System.out.println("连接状态: " + event.getState());
            System.out.println("路径: " + event.getPath());
        };

        zk = new ZooKeeper(ZK_ADDRESS, 3000, watcher);

        Thread.sleep(1000);

        // 创建测试节点
        zk.create("/watch-test", "initial".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);

        // 设置节点数据监听
        System.out.println("设置节点数据监听...");
        byte[] data = zk.getData("/watch-test", true, null);
        System.out.println("初始数据: " + new String(data));

        // 更新节点数据（触发监听）
        System.out.println("更新节点数据...");
        zk.setData("/watch-test", "updated".getBytes(), -1);

        Thread.sleep(1000);

        // 设置子节点列表监听
        System.out.println("设置子节点列表监听...");
        List<String> children = zk.getChildren("/watch-test", true);
        System.out.println("子节点: " + children);

        // 创建子节点（触发监听）
        System.out.println("创建子节点...");
        zk.create("/watch-test/child1", "child".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);

        Thread.sleep(1000);

        // 删除子节点（触发监听）
        System.out.println("删除子节点...");
        zk.delete("/watch-test/child1", -1);

        Thread.sleep(1000);

        // 设置节点存在监听
        System.out.println("设置节点存在监听...");
        Stat stat = zk.exists("/watch-test", true);
        System.out.println("节点存在: " + (stat != null));

        // 删除节点（触发监听）
        System.out.println("删除节点...");
        zk.delete("/watch-test", -1);

        Thread.sleep(1000);

        zk.close();
    }
}
```

### 7.4.2 监听事件处理

```java
// 监听事件处理示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.concurrent.CountDownLatch;

public class ZKWatchEventDemo implements Watcher {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;
    private static CountDownLatch latch = new CountDownLatch(1);

    @Override
    public void process(WatchedEvent event) {
        System.out.println("========== 监听事件 ==========");
        System.out.println("事件: " + event);
        System.out.println("类型: " + event.getType());
        System.out.println("状态: " + event.getState());
        System.out.println("路径: " + event.getPath());
        System.out.println("================================");

        // 处理连接状态变化
        if (event.getState() == Event.KeeperState.SyncConnected) {
            latch.countDown();
        }

        // 处理节点数据变化
        if (event.getType() == Event.EventType.NodeDataChanged) {
            try {
                byte[] data = zk.getData(event.getPath(), true, null);
                System.out.println("新数据: " + new String(data));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // 处理子节点变化
        if (event.getType() == Event.EventType.NodeChildrenChanged) {
            try {
                List<String> children = zk.getChildren(event.getPath(), true);
                System.out.println("新子节点: " + children);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // 处理节点删除
        if (event.getType() == Event.EventType.NodeDeleted) {
            System.out.println("节点被删除: " + event.getPath());
        }

        // 处理节点创建
        if (event.getType() == Event.EventType.NodeCreated) {
            System.out.println("节点被创建: " + event.getPath());
        }
    }

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        ZKWatchEventDemo demo = new ZKWatchEventDemo();
        zk = new ZooKeeper(ZK_ADDRESS, 3000, demo);

        latch.await();

        // 创建测试节点
        zk.create("/event-test", "initial".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        System.out.println("创建节点: /event-test");

        Thread.sleep(500);

        // 更新数据
        zk.setData("/event-test", "updated".getBytes(), -1);
        System.out.println("更新数据");

        Thread.sleep(500);

        // 创建子节点
        zk.create("/event-test/child", "child".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        System.out.println("创建子节点");

        Thread.sleep(500);

        // 删除子节点
        zk.delete("/event-test/child", -1);
        System.out.println("删除子节点");

        Thread.sleep(500);

        // 删除节点
        zk.delete("/event-test", -1);
        System.out.println("删除节点");

        Thread.sleep(1000);

        zk.close();
    }
}
```

---

## 7.5 事务操作

### 7.5.1 事务概念

```
事务概念：

┌─────────────────────────────────────────────────────────────────┐
│  事务概念                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper事务是一组操作的原子性执行：

1. 事务特点
   ├── 原子性：所有操作要么全部成功，要么全部失败
   ├── 一致性：操作后数据保持一致状态
   ├── 隔离性：事务之间互不干扰
   └── 持久性：事务提交后结果持久保存

2. 事务操作
   ├── create：创建节点
   ├── delete：删除节点
   ├── setData：更新节点数据
   └── setAcl：更新节点权限

3. 事务ID（ZXID）
   ├── 高32位：Epoch
   ├── 低32位：Counter
   └── 全局唯一

4. 事务流程
   客户端创建事务请求
   -> Leader生成Proposal
   -> Follower处理Proposal
   -> Leader收到过半ACK
   -> Leader提交事务
   -> 通知所有Follower提交

5. 事务保证
   ├── 所有Server看到相同的事务
   ├── 事务按顺序处理
   ├── Leader崩溃可以恢复
   └── 崩溃后不丢失事务
```

### 7.5.2 事务操作示例

```java
// 事务操作示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.List;

public class ZKTransactionDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws IOException, InterruptedException, KeeperException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});

        Thread.sleep(1000);

        // 事务操作（3.5+）
        // 使用Transaction类

        // 创建事务
        Transaction transaction = zk.transaction();

        // 添加操作
        transaction.create("/txn/test1", "test1".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        transaction.create("/txn/test2", "test2".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        transaction.setData("/txn/test1", "updated".getBytes(), -1);
        transaction.delete("/txn/test2", -1);

        // 提交事务
        try {
            List<OpResult> results = transaction.commit();
            System.out.println("事务提交成功");
            System.out.println("结果: " + results);
        } catch (KeeperException e) {
            System.out.println("事务提交失败: " + e);
        }

        // 验证事务结果
        System.out.println("test1存在: " + (zk.exists("/txn/test1", false) != null));
        System.out.println("test2存在: " + (zk.exists("/txn/test2", false) != null));

        // 读取数据
        byte[] data = zk.getData("/txn/test1", false, null);
        System.out.println("test1数据: " + new String(data));

        // 清理
        zk.delete("/txn/test1", -1);

        zk.close();
    }
}
```

---

## 7.6 实战：API编程

### 7.6.1 配置管理

```java
// 配置管理示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;

public class ConfigManager {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String CONFIG_PATH = "/app/config";
    private ZooKeeper zk;
    private Watcher watcher;

    public ConfigManager() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {
            if (event.getType() == Event.EventType.NodeDataChanged) {
                try {
                    String data = getConfig(event.getPath());
                    System.out.println("配置更新: " + event.getPath() + " = " + data);
                    if (watcher != null) {
                        watcher.onConfigChanged(event.getPath(), data);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }

    public void setWatcher(ConfigWatcher watcher) {
        this.watcher = watcher;
    }

    public void initConfig(String configData) throws KeeperException, InterruptedException {
        if (zk.exists(CONFIG_PATH, false) == null) {
            zk.create(CONFIG_PATH, configData.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }
    }

    public String getConfig() throws KeeperException, InterruptedException {
        return getConfig(CONFIG_PATH);
    }

    public String getConfig(String path) throws KeeperException, InterruptedException {
        byte[] data = zk.getData(path, true, null);
        return data != null ? new String(data) : null;
    }

    public void setConfig(String configData) throws KeeperException, InterruptedException {
        Stat stat = zk.setData(CONFIG_PATH, configData.getBytes(), -1);
        System.out.println("配置已更新，版本: " + stat.getVersion());
    }

    public void close() throws InterruptedException {
        zk.close();
    }

    public interface ConfigWatcher {
        void onConfigChanged(String path, String data);
    }

    public static void main(String[] args) throws Exception {
        ConfigManager manager = new ConfigManager();

        manager.setWatcher((path, data) -> {
            System.out.println("收到配置变更通知: " + data);
        });

        manager.initConfig("initial config");

        System.out.println("当前配置: " + manager.getConfig());

        Thread.sleep(1000);

        manager.setConfig("updated config");

        Thread.sleep(1000);

        manager.close();
    }
}
```

### 7.6.2 服务注册和发现

```java
// 服务注册和发现示例

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ServiceRegistry {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String SERVICE_PATH = "/services";
    private ZooKeeper zk;
    private String serviceName;
    private String serviceAddress;
    private String ephemeralPath;

    public ServiceRegistry(String serviceName, String serviceAddress) throws IOException {
        this.serviceName = serviceName;
        this.serviceAddress = serviceAddress;

        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {
            if (event.getType() == Event.EventType.NodeChildrenChanged) {
                try {
                    System.out.println("服务列表变化: " + getServices());
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        init();
    }

    private void init() throws KeeperException, InterruptedException {
        // 创建服务根节点
        if (zk.exists(SERVICE_PATH, false) == null) {
            zk.create(SERVICE_PATH, "services".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }
    }

    public void register() throws KeeperException, InterruptedException {
        // 创建临时节点
        String path = SERVICE_PATH + "/" + serviceName;
        ephemeralPath = zk.create(path, serviceAddress.getBytes(),
            ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
        System.out.println("服务注册: " + ephemeralPath + " -> " + serviceAddress);
    }

    public void unregister() throws InterruptedException, KeeperException {
        if (ephemeralPath != null) {
            zk.delete(ephemeralPath, -1);
            System.out.println("服务注销: " + ephemeralPath);
        }
    }

    public List<String> getServices() throws KeeperException, InterruptedException {
        List<String> services = zk.getChildren(SERVICE_PATH, true);
        List<String> result = new ArrayList<>();
        for (String service : services) {
            String path = SERVICE_PATH + "/" + service;
            byte[] data = zk.getData(path, false, null);
            if (data != null) {
                result.add(new String(data));
            }
        }
        return result;
    }

    public String getServiceAddress(String serviceName) throws KeeperException, InterruptedException {
        String path = SERVICE_PATH + "/" + serviceName;
        byte[] data = zk.getData(path, false, null);
        return data != null ? new String(data) : null;
    }

    public void close() throws InterruptedException {
        unregister();
        zk.close();
    }

    public static void main(String[] args) throws Exception {
        // 服务注册
        ServiceRegistry registry = new ServiceRegistry("kafka", "192.168.1.101:9092");
        registry.register();

        Thread.sleep(5000);

        // 发现服务
        System.out.println("当前服务: " + registry.getServices());

        // 注销服务
        registry.close();
    }
}
```

---

## 本章小结

- Zookeeper提供Java API、Python API、Curator等多种编程语言的API
- Java API核心类包括ZooKeeper、Watcher、CreateMode、ZooDefs等
- 连接管理包括建立连接、连接参数配置、连接状态和重连
- CRUD操作包括创建节点、读取节点、更新节点、删除节点
- 监听操作包括设置监听、监听事件处理
- 事务操作使用Transaction类，实现操作的原子性
- 常见应用包括配置管理、服务注册和发现等

---

**下一章：Zookeeper典型应用场景**
