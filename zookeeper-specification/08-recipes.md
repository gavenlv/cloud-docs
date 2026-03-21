# Zookeeper典型应用场景

## 8.1 分布式锁

### 8.1.1 分布式锁原理

```
分布式锁原理：

┌─────────────────────────────────────────────────────────────────┐
│  分布式锁原理                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现分布式锁的原理：

1. 锁类型
   ├── 排他锁（Exclusive Lock）
   ├── 共享锁（Shared Lock）
   ├── 读写锁（Read/Write Lock）
   └── 信号量（Semaphore）

2. 排他锁实现原理
   锁竞争者：
   1. 创建临时顺序节点 /locks/lock-
   2. 获取所有子节点
   3. 判断自己是否最小
   4. 如果是，获得锁
   5. 如果不是，监听前一个节点
   6. 当前一个节点删除时，重复步骤3

3. 锁竞争流程
   Client1创建节点/locks/lock-0000000001
   Client2创建节点/locks/lock-0000000002
   Client3创建节点/locks/lock-0000000003

   Client1获得锁（最小节点）
   Client2监听Client1
   Client3监听Client2

   Client1释放锁，删除节点
   Client2收到通知，获得锁
   Client3继续监听

4. 锁特点
   ├── 公平锁：按顺序获得锁
   ├── 非阻塞锁：可以尝试获取
   ├── 可重入锁：同一线程可多次获取
   └── 自动释放：Session断开自动释放
```

### 8.1.2 分布式锁实现

```java
// 分布式锁实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;

public class DistributedLock {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String LOCK_PATH = "/locks";
    private ZooKeeper zk;
    private String lockName;
    private String lockPath;
    private CountDownLatch latch = new CountDownLatch(1);

    public DistributedLock(String lockName) throws IOException {
        this.lockName = lockName;
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {
            if (event.getState() == Event.KeeperState.SyncConnected) {
                latch.countDown();
            }
        });
        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public boolean acquire() throws KeeperException, InterruptedException {
        // 创建临时顺序节点
        lockPath = zk.create(LOCK_PATH + "/" + lockName + "-",
            null, ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);

        System.out.println("创建锁节点: " + lockPath);

        // 获取所有子节点
        List<String> children = zk.getChildren(LOCK_PATH, false);

        // 排序
        Collections.sort(children);

        // 判断是否获得锁
        String minNode = children.get(0);
        if (lockPath.endsWith(minNode)) {
            System.out.println("获得锁: " + lockPath);
            return true;
        }

        // 监听前一个节点
        String prevNode = null;
        for (int i = 0; i < children.size(); i++) {
            if (lockPath.endsWith(children.get(i))) {
                prevNode = children.get(i - 1);
                break;
            }
        }

        if (prevNode != null) {
            System.out.println("等待锁: " + prevNode);
            final CountDownLatch waitLatch = new CountDownLatch(1);

            Watcher watcher = event -> {
                if (event.getType() == Event.EventType.NodeDeleted) {
                    waitLatch.countDown();
                }
            };

            Stat stat = zk.exists(LOCK_PATH + "/" + prevNode, watcher);
            if (stat != null) {
                waitLatch.await();
            }
        }

        return true;
    }

    public void release() throws InterruptedException, KeeperException {
        if (lockPath != null) {
            System.out.println("释放锁: " + lockPath);
            zk.delete(lockPath, -1);
            lockPath = null;
        }
    }

    public void close() throws InterruptedException {
        release();
        zk.close();
    }

    public static void main(String[] args) throws Exception {
        DistributedLock lock = new DistributedLock("test-lock");

        System.out.println("尝试获取锁...");
        lock.acquire();

        System.out.println("执行临界区代码...");
        Thread.sleep(5000);

        System.out.println("释放锁...");
        lock.release();

        lock.close();
    }
}
```

---

## 8.2 服务发现

### 8.2.1 服务发现原理

```
服务发现原理：

┌─────────────────────────────────────────────────────────────────┐
│  服务发现原理                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现服务发现的原理：

1. 服务注册
   ├── 服务启动时创建临时节点
   ├── 节点路径包含服务信息
   ├── Session断开自动注销
   └── 心跳保持注册

2. 服务发现
   ├── 客户端监听服务节点
   ├── 节点变化时收到通知
   ├── 实时获取服务列表
   └── 动态感知服务上下线

3. 负载均衡
   ├── 随机策略
   ├── 轮询策略
   ├── 最少连接策略
   └── 一致性哈希策略

4. 服务健康检查
   ├── 基于Session心跳
   ├── 基于临时节点
   ├── 基于健康检查节点
   └── 自动故障转移

5. 服务发现流程
   服务启动
   -> 创建临时节点 /services/app/instance-xxx
   -> 服务信息（IP、端口）
   -> 客户端监听 /services/app
   -> 服务上线/下线
   -> 客户端收到通知
   -> 更新本地缓存
```

### 8.2.2 服务发现实现

```java
// 服务发现实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.*;

public class ServiceDiscovery {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String SERVICE_PATH = "/services";
    private ZooKeeper zk;
    private Map<String, String> serviceCache = new HashMap<>();

    public ServiceDiscovery() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {
            if (event.getType() == Event.EventType.NodeChildrenChanged) {
                try {
                    refreshServices();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }

    public void register(String serviceName, String serviceAddress) throws KeeperException, InterruptedException {
        String path = SERVICE_PATH + "/" + serviceName;
        if (zk.exists(path, false) == null) {
            zk.create(path, serviceName.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }

        String instancePath = zk.create(path + "/instance-",
            serviceAddress.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);

        System.out.println("服务注册: " + instancePath + " -> " + serviceAddress);
    }

    public void refreshServices() throws KeeperException, InterruptedException {
        List<String> serviceNames = zk.getChildren(SERVICE_PATH, true);
        serviceCache.clear();

        for (String serviceName : serviceNames) {
            String servicePath = SERVICE_PATH + "/" + serviceName;
            List<String> instances = zk.getChildren(servicePath, false);

            for (String instance : instances) {
                String instancePath = servicePath + "/" + instance;
                byte[] data = zk.getData(instancePath, false, null);
                if (data != null) {
                    serviceCache.put(instance, new String(data));
                }
            }
        }

        System.out.println("服务列表刷新: " + serviceCache);
    }

    public List<String> getServices(String serviceName) throws KeeperException, InterruptedException {
        List<String> services = new ArrayList<>();
        String servicePath = SERVICE_PATH + "/" + serviceName;

        if (zk.exists(servicePath, false) != null) {
            List<String> instances = zk.getChildren(servicePath, false);
            for (String instance : instances) {
                String instancePath = servicePath + "/" + instance;
                byte[] data = zk.getData(instancePath, false, null);
                if (data != null) {
                    services.add(new String(data));
                }
            }
        }

        return services;
    }

    public String getService(String serviceName) throws KeeperException, InterruptedException {
        List<String> services = getServices(serviceName);
        if (services.isEmpty()) {
            return null;
        }
        // 简单轮询策略
        return services.get(new Random().nextInt(services.size()));
    }

    public void close() throws InterruptedException {
        zk.close();
    }

    public static void main(String[] args) throws Exception {
        ServiceDiscovery discovery = new ServiceDiscovery();

        // 注册服务
        discovery.register("kafka", "192.168.1.101:9092");
        discovery.register("kafka", "192.168.1.102:9092");
        discovery.register("zookeeper", "192.168.1.101:2181");

        Thread.sleep(1000);

        // 发现服务
        System.out.println("Kafka服务: " + discovery.getServices("kafka"));
        System.out.println("Zookeeper服务: " + discovery.getServices("zookeeper"));

        discovery.close();
    }
}
```

---

## 8.3 配置管理

### 8.3.1 配置管理原理

```
配置管理原理：

┌─────────────────────────────────────────────────────────────────┐
│  配置管理原理                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现配置管理的原理：

1. 配置存储
   ├── 配置存储在ZNode
   ├── 支持版本管理
   ├── 支持多配置项
   └── 支持配置分组

2. 配置更新
   ├── 配置变更时更新ZNode
   ├── Watch通知所有客户端
   ├── 客户端拉取最新配置
   └── 本地缓存最新配置

3. 配置对比
   ├── 本地配置版本
   ├── Zookeeper配置版本
   ├── 版本不同时更新
   └── 避免频繁读取

4. 配置隔离
   ├── 按环境隔离配置
   ├── 按服务隔离配置
   ├── 按租户隔离配置
   └── 访问权限控制

5. 配置管理流程
   配置变更
   -> 更新ZNode
   -> 触发Watch
   -> 通知客户端
   -> 客户端拉取配置
   -> 更新本地配置
   -> 应用新配置
```

### 8.3.2 配置管理实现

```java
// 配置管理实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ConfigManagement {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String CONFIG_PATH = "/app/config";
    private ZooKeeper zk;
    private Map<String, String> configCache = new HashMap<>();
    private ConfigWatcher configWatcher;

    public ConfigManagement() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {
            if (event.getType() == Event.EventType.NodeDataChanged) {
                try {
                    String data = getConfig(event.getPath());
                    System.out.println("配置变更: " + event.getPath() + " = " + data);
                    if (configWatcher != null) {
                        configWatcher.onConfigChanged(event.getPath(), data);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }

    public void setConfigWatcher(ConfigWatcher watcher) {
        this.configWatcher = watcher;
    }

    public void initConfig() throws KeeperException, InterruptedException {
        if (zk.exists(CONFIG_PATH, false) == null) {
            zk.create(CONFIG_PATH, "config".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }
    }

    public void setConfig(String key, String value) throws KeeperException, InterruptedException {
        String path = CONFIG_PATH + "/" + key;
        if (zk.exists(path, false) == null) {
            zk.create(path, value.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        } else {
            zk.setData(path, value.getBytes(), -1);
        }
        System.out.println("设置配置: " + key + " = " + value);
    }

    public String getConfig(String key) throws KeeperException, InterruptedException {
        String path = CONFIG_PATH + "/" + key;
        byte[] data = zk.getData(path, true, null);
        return data != null ? new String(data) : null;
    }

    public void deleteConfig(String key) throws KeeperException, InterruptedException {
        String path = CONFIG_PATH + "/" + key;
        if (zk.exists(path, false) != null) {
            zk.delete(path, -1);
            System.out.println("删除配置: " + key);
        }
    }

    public void loadAllConfig() throws KeeperException, InterruptedException {
        List<String> keys = zk.getChildren(CONFIG_PATH, true);
        configCache.clear();
        for (String key : keys) {
            String value = getConfig(key);
            if (value != null) {
                configCache.put(key, value);
            }
        }
        System.out.println("加载所有配置: " + configCache);
    }

    public Map<String, String> getAllConfig() {
        return new HashMap<>(configCache);
    }

    public interface ConfigWatcher {
        void onConfigChanged(String key, String value);
    }

    public static void main(String[] args) throws Exception {
        ConfigManagement config = new ConfigManagement();

        config.setConfigWatcher((key, value) -> {
            System.out.println("配置变更通知: " + key + " = " + value);
        });

        config.initConfig();

        config.setConfig("database", "mysql://localhost:3306");
        config.setConfig("cache", "redis://localhost:6379");
        config.setConfig("server", "8080");

        Thread.sleep(1000);

        config.loadAllConfig();

        System.out.println("database: " + config.getConfig("database"));
        System.out.println("cache: " + config.getConfig("cache"));

        config.close();
    }
}
```

---

## 8.4 命名服务

### 8.4.1 命名服务原理

```
命名服务原理：

┌─────────────────────────────────────────────────────────────────┐
│  命名服务原理                                              │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现命名服务的原理：

1. 全局唯一ID生成
   ├── 使用顺序节点
   ├── 保证全局唯一性
   ├── 高可用
   └── 有序递增

2. 名称到地址的映射
   ├── 名称存储在ZNode
   ├── 地址作为数据
   ├── Watch监听变化
   └── 动态更新

3. 名称管理
   ├── 名称注册
   ├── 名称注销
   ├── 名称查询
   └── 名称监听

4. 命名服务场景
   ├── 全局事务ID
   ├── 分布式Job ID
   ├── 服务实例ID
   └── 配置Key

5. ID生成策略
   ├── UUID：简单但无序
   ├── Snowflake：需要时间同步
   ├── Zookeeper顺序节点：简单可靠
   └── 数据库自增：性能瓶颈
```

### 8.4.2 命名服务实现

```java
// 命名服务实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;

public class NamingService {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String NAMESPACE_PATH = "/names";
    private ZooKeeper zk;

    public NamingService() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});
    }

    public String generateId(String category) throws KeeperException, InterruptedException {
        String path = NAMESPACE_PATH + "/" + category;
        if (zk.exists(path, false) == null) {
            zk.create(path, category.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }

        // 创建顺序节点
        String idPath = zk.create(path + "/id-",
            null, ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);

        System.out.println("生成ID: " + idPath);
        return idPath;
    }

    public void register(String name, String address) throws KeeperException, InterruptedException {
        String path = NAMESPACE_PATH + "/address/" + name;
        if (zk.exists(path, false) == null) {
            zk.create(path, address.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        } else {
            zk.setData(path, address.getBytes(), -1);
        }
        System.out.println("注册名称: " + name + " -> " + address);
    }

    public String lookup(String name) throws KeeperException, InterruptedException {
        String path = NAMESPACE_PATH + "/address/" + name;
        byte[] data = zk.getData(path, false, null);
        return data != null ? new String(data) : null;
    }

    public void unregister(String name) throws KeeperException, InterruptedException {
        String path = NAMESPACE_PATH + "/address/" + name;
        if (zk.exists(path, false) != null) {
            zk.delete(path, -1);
            System.out.println("注销名称: " + name);
        }
    }

    public void watchName(String name, Watcher watcher) throws KeeperException, InterruptedException {
        String path = NAMESPACE_PATH + "/address/" + name;
        if (zk.exists(path, false) != null) {
            zk.getData(path, watcher, null);
            System.out.println("监听名称: " + name);
        }
    }

    public static void main(String[] args) throws Exception {
        NamingService naming = new NamingService();

        // 生成ID
        String id1 = naming.generateId("order");
        String id2 = naming.generateId("order");
        String id3 = naming.generateId("payment");

        System.out.println("生成的ID: " + id1 + ", " + id2 + ", " + id3);

        // 注册名称
        naming.register("service-a", "192.168.1.101:8080");
        naming.register("service-b", "192.168.1.102:8080");

        // 查询地址
        System.out.println("service-a: " + naming.lookup("service-a"));
        System.out.println("service-b: " + naming.lookup("service-b"));

        // 注销名称
        naming.unregister("service-b");

        naming.close();
    }
}
```

---

## 8.5 Master-Worker协同

### 8.5.1 Master-Worker原理

```
Master-Worker原理：

┌─────────────────────────────────────────────────────────────────┐
│  Master-Worker原理                                       │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现Master-Worker协同的原理：

1. Master选举
   ├── 使用临时节点
   ├── 谁创建成功谁就是Master
   ├── Master宕机自动重新选举
   └── 通知Worker新Master

2. 任务队列
   ├── 使用顺序节点
   ├── 保证任务顺序
   ├── 任务持久化
   └── 任务分发

3. 状态管理
   ├── Worker注册到Zookeeper
   ├── Master分配任务
   ├── Worker更新状态
   └── Master监控状态

4. 容错机制
   ├── Master宕机：重新选举
   ├── Worker宕机：任务重新分配
   ├── 任务超时：重新执行
   └── 心跳检测

5. 协同流程
   Master选举
   -> Master创建 /master 节点
   -> Worker注册到 /workers
   -> Master监听 /tasks 队列
   -> Client提交任务到 /tasks
   -> Master分配任务给Worker
   -> Worker执行任务
   -> Worker更新任务状态
```

### 8.5.2 Master-Worker实现

```java
// Master-Worker实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.*;

public class MasterWorkerDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String MASTER_PATH = "/master";
    private static final String WORKERS_PATH = "/workers";
    private static final String TASKS_PATH = "/tasks";
    private static final String ASSIGN_PATH = "/assign";
    private ZooKeeper zk;
    private String workerId;
    private boolean isMaster = false;

    public MasterWorkerDemo(String workerId) throws IOException {
        this.workerId = workerId;
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});
    }

    public void electMaster() throws KeeperException, InterruptedException {
        try {
            zk.create(MASTER_PATH, workerId.getBytes(),
                ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL);
            isMaster = true;
            System.out.println(workerId + " 成为Master");
        } catch (KeeperException.NodeExistsException e) {
            byte[] data = zk.getData(MASTER_PATH, false, null);
            String master = data != null ? new String(data) : "unknown";
            System.out.println(workerId + " 无法成为Master，当前Master: " + master);
            isMaster = false;
        }
    }

    public void registerWorker() throws KeeperException, InterruptedException {
        String path = zk.create(WORKERS_PATH + "/" + workerId,
            "idle".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL);

        System.out.println("Worker注册: " + path);

        // 监听Master变化
        Watcher masterWatcher = event -> {
            if (event.getType() == Event.EventType.NodeDeleted) {
                System.out.println("Master宕机，重新选举");
                try {
                    electMaster();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };

        zk.exists(MASTER_PATH, masterWatcher);
    }

    public void submitTask(String task) throws KeeperException, InterruptedException {
        String path = zk.create(TASKS_PATH + "/task-",
            task.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);

        System.out.println("提交任务: " + path + " -> " + task);
    }

    public void processTasks() throws KeeperException, InterruptedException {
        List<String> tasks = zk.getChildren(TASKS_PATH, false);
        List<String> workers = zk.getChildren(WORKERS_PATH, false);

        if (tasks.isEmpty() || workers.isEmpty()) {
            System.out.println("没有任务或Worker");
            return;
        }

        String task = tasks.get(0);
        String taskPath = TASKS_PATH + "/" + task;

        // 分配给一个Worker
        String worker = workers.get(0);
        String assignPath = ASSIGN_PATH + "/" + worker + "/" + task;

        if (zk.exists(ASSIGN_PATH + "/" + worker, false) == null) {
            zk.create(ASSIGN_PATH + "/" + worker,
                "".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }

        byte[] taskData = zk.getData(taskPath, false, null);
        zk.create(assignPath, taskData, ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        zk.delete(taskPath, -1);

        System.out.println("分配任务: " + task + " -> " + worker);

        // 更新Worker状态
        zk.setData(WORKERS_PATH + "/" + worker, "working".getBytes(), -1);
    }

    public void close() throws InterruptedException {
        zk.close();
    }

    public static void main(String[] args) throws Exception {
        MasterWorkerDemo worker1 = new MasterWorkerDemo("worker1");
        MasterWorkerDemo worker2 = new MasterWorkerDemo("worker2");

        // Worker注册
        worker1.registerWorker();
        worker2.registerWorker();

        // Master选举
        worker1.electMaster();

        Thread.sleep(1000);

        // 提交任务
        worker1.submitTask("Task 1");
        worker1.submitTask("Task 2");
        worker1.submitTask("Task 3");

        // Master处理任务
        if (worker1.isMaster) {
            for (int i = 0; i < 3; i++) {
                worker1.processTasks();
                Thread.sleep(500);
            }
        }

        worker1.close();
        worker2.close();
    }
}
```

---

## 8.6 分布式队列

### 8.6.1 分布式队列原理

```
分布式队列原理：

┌─────────────────────────────────────────────────────────────────┐
│  分布式队列原理                                         │
└─────────────────────────────────────────────────────────────────┘

Zookeeper实现分布式队列的原理：

1. 队列操作
   ├── 入队：创建顺序节点
   ├── 出队：删除最小顺序节点
   ├── 读取：获取最小顺序节点
   └── 阻塞：监听队列空状态

2. 队列类型
   ├── FIFO队列：按顺序
   ├── LIFO队列：逆序
   ├── 优先级队列：按优先级
   └── 阻塞队列：等待非空

3. FIFO队列实现
   入队：create -s /queue/task "data"
   出队：
   1. 获取所有子节点
   2. 选择最小序号节点
   3. 读取数据
   4. 删除节点

4. 阻塞队列实现
   1. 监听队列变化
   2. 队列为空时等待
   3. 队列非空时被通知
   4. 执行出队操作

5. 队列特点
   ├── 可靠：持久化
   ├── 有序：顺序节点
   ├── 原子：事务保证
   └── 阻塞：支持等待
```

### 8.6.2 分布式队列实现

```java
// 分布式队列实现

import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;
import java.io.IOException;
import java.util.Collections;
import java.util.List;

public class DistributedQueue {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static final String QUEUE_PATH = "/queue";
    private ZooKeeper zk;

    public DistributedQueue() throws IOException {
        zk = new ZooKeeper(ZK_ADDRESS, 3000, event -> {});
    }

    public void init() throws KeeperException, InterruptedException {
        if (zk.exists(QUEUE_PATH, false) == null) {
            zk.create(QUEUE_PATH, "queue".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
        }
    }

    public void enqueue(String data) throws KeeperException, InterruptedException {
        String path = zk.create(QUEUE_PATH + "/item-",
            data.getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);
        System.out.println("入队: " + path + " -> " + data);
    }

    public String dequeue() throws KeeperException, InterruptedException {
        List<String> items = zk.getChildren(QUEUE_PATH, false);
        if (items.isEmpty()) {
            System.out.println("队列为空");
            return null;
        }

        // 排序
        Collections.sort(items);

        // 取第一个（最小序号）
        String minItem = items.get(0);
        String itemPath = QUEUE_PATH + "/" + minItem;

        // 读取数据
        byte[] data = zk.getData(itemPath, false, null);
        String result = data != null ? new String(data) : null;

        // 删除节点
        zk.delete(itemPath, -1);
        System.out.println("出队: " + minItem + " -> " + result);

        return result;
    }

    public String peek() throws KeeperException, InterruptedException {
        List<String> items = zk.getChildren(QUEUE_PATH, false);
        if (items.isEmpty()) {
            return null;
        }

        Collections.sort(items);
        String minItem = items.get(0);
        String itemPath = QUEUE_PATH + "/" + minItem;

        byte[] data = zk.getData(itemPath, false, null);
        return data != null ? new String(data) : null;
    }

    public int size() throws KeeperException, InterruptedException {
        return zk.getChildren(QUEUE_PATH, false).size();
    }

    public void blockingDequeue() throws KeeperException, InterruptedException {
        while (true) {
            List<String> items = zk.getChildren(QUEUE_PATH, true);
            if (items.isEmpty()) {
                System.out.println("队列为空，等待...");
                Thread.sleep(1000);
                continue;
            }

            Collections.sort(items);
            String minItem = items.get(0);
            String itemPath = QUEUE_PATH + "/" + minItem;

            byte[] data = zk.getData(itemPath, false, null);
            String result = data != null ? new String(data) : null;

            zk.delete(itemPath, -1);
            System.out.println("阻塞出队: " + minItem + " -> " + result);

            return;
        }
    }

    public static void main(String[] args) throws Exception {
        DistributedQueue queue = new DistributedQueue();
        queue.init();

        // 入队
        queue.enqueue("Item 1");
        queue.enqueue("Item 2");
        queue.enqueue("Item 3");

        System.out.println("队列大小: " + queue.size());
        System.out.println("队首元素: " + queue.peek());

        // 出队
        System.out.println("出队: " + queue.dequeue());
        System.out.println("出队: " + queue.dequeue());
        System.out.println("出队: " + queue.dequeue());

        System.out.println("队列大小: " + queue.size());

        queue.close();
    }
}
```

---

## 本章小结

- 分布式锁利用Zookeeper临时顺序节点实现，提供公平锁、非阻塞锁、可重入锁等特性
- 服务发现利用Zookeeper临时节点和Watch机制实现，支持实时感知服务上下线
- 配置管理利用Zookeeper持久节点和Watch机制实现，支持配置变更实时通知
- 命名服务利用Zookeeper顺序节点实现全局唯一ID生成和名称到地址的映射
- Master-Worker协同利用Zookeeper临时节点实现Master选举和任务分配
- 分布式队列利用Zookeeper顺序节点实现FIFO队列和阻塞队列

---

**下一章：集群部署和运维**
