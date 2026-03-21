# 常见错误处理

## 10.1 连接错误

### 10.1.1 连接超时

```
连接超时错误：

┌─────────────────────────────────────────────────────────────────┐
│  连接超时错误                                          │
└─────────────────────────────────────────────────────────────────┘

错误信息：
org.apache.zookeeper.KeeperException.ConnectionLossException: No response from server

原因分析：
1. 网络不通
2. 防火墙阻止
3. Zookeeper服务未启动
4. 端口配置错误
5. Session超时设置过短

解决方案：

1. 检查网络连通性
   ping 192.168.1.101

   telnet 192.168.1.101 2181

   nc -zv 192.168.1.101 2181

2. 检查防火墙
   # Linux
   sudo iptables -L -n

   # 开放端口
   sudo iptables -A INPUT -p tcp --dport 2181 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 2888 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 3888 -j ACCEPT

3. 检查服务状态
   bin/zkServer.sh status

   systemctl status zookeeper

   # 查看进程
   ps -ef | grep zookeeper

4. 检查端口配置
   netstat -tlnp | grep 2181

   ss -tlnp | grep 2181

5. 调整Session超时
   # 在客户端设置更长的超时时间
   ZooKeeper(String connectString, int sessionTimeout, Watcher watcher)

   # 建议sessionTimeout >= 30000
```

### 10.1.2 无法连接服务器

```
无法连接服务器错误：

┌─────────────────────────────────────────────────────────────────┐
│  无法连接服务器错误                                      │
└─────────────────────────────────────────────────────────────────┘

错误信息：
org.apache.zookeeper.KeeperException$NoServerException: Cannot open channel to server

原因分析：
1. 服务器地址错误
2. Zookeeper服务未启动
3. 端口被占用
4. 多网卡绑定问题

解决方案：

1. 检查连接字符串
   # 正确格式
   localhost:2181
   192.168.1.101:2181
   192.168.1.101:2181,192.168.1.102:2181,192.168.1.103:2181

   # 带chroot路径
   localhost:2181/app
   192.168.1.101:2181,192.168.1.102:2181/app

2. 检查服务状态
   bin/zkServer.sh status

   # 查看日志
   tail -f logs/zookeeper.out

3. 检查端口占用
   netstat -tlnp | grep 2181

   # 如果端口被占用，修改配置
   # 在zoo.cfg中：
   clientPort=2182

4. 检查多网卡绑定
   # 在zoo.cfg中指定监听地址
   clientPortAddress=192.168.1.101

   # 或使用0.0.0.0监听所有地址
   clientPortAddress=0.0.0.0
```

---

## 10.2 节点操作错误

### 10.2.1 节点不存在

```
节点不存在错误：

┌─────────────────────────────────────────────────────────────────┐
│  节点不存在错误                                        │
└─────────────────────────────────────────────────────────────────┘

错误信息：
org.apache.zookeeper.KeeperException$NoNodeException: No node for path /path

原因分析：
1. 节点尚未创建
2. 节点路径错误
3. 节点已被删除
4. 写错路径（大小写敏感）

解决方案：

1. 检查节点是否存在
   # 使用CLI
   ls /path

   # 使用exists
   stat /path

   # 使用Java API
   Stat stat = zk.exists("/path", false);
   if (stat == null) {
       // 节点不存在
   }

2. 创建节点
   # CLI创建
   create /path "data"

   # Java API创建
   String path = zk.create("/path", "data".getBytes(),
       ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);

3. 处理NoNodeException
   try {
       byte[] data = zk.getData("/path", false, null);
   } catch (NoNodeException e) {
       // 节点不存在，需要处理
       zk.create("/path", "default".getBytes(),
           ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
   }

4. 使用递归创建
   # 确保父节点存在
   create -p /parent/child "data"

   # 或先创建父节点
   if (zk.exists("/parent", false) == null) {
       zk.create("/parent", "".getBytes(),
           ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
   }
```

### 10.2.2 节点已存在

```
节点已存在错误：

┌─────────────────────────────────────────────────────────────────┐
│  节点已存在错误                                        │
└─────────────────────────────────────────────────────────────────┘

错误信息：
org.apache.zookeeper.KeeperException$NodeExistsException: Node already exists

原因分析：
1. 重复创建节点
2. 并发创建冲突
3. 没有检查节点是否存在

解决方案：

1. 检查节点是否存在
   if (zk.exists("/path", false) == null) {
       zk.create("/path", "data".getBytes(),
           ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
   }

2. 使用createAsync
   zk.createAsync("/path", "data".getBytes(),
       ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT,
       (rc, path, ctx, stat) -> {
           if (rc == KeeperException.Code.OK.intValue()) {
               // 创建成功
           }
       }, null);

3. 使用幂等操作
   # 忽略NodeExistsException
   try {
       zk.create("/path", "data".getBytes(),
           ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
   } catch (NodeExistsException e) {
       // 忽略，节点已存在
   }

4. 使用setData代替create
   if (zk.exists("/path", false) != null) {
       zk.setData("/path", "data".getBytes(), -1);
   } else {
       zk.create("/path", "data".getBytes(),
           ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
   }
```

### 10.2.3 版本冲突

```
版本冲突错误：

┌─────────────────────────────────────────────────────────────────┐
│  版本冲突错误                                        │
└─────────────────────────────────────────────────────────────────┘

错误信息：
org.apache.zookeeper.KeeperException$BadVersionException: version No is not correct

原因分析：
1. 乐观锁版本不匹配
2. 并发更新同一节点
3. 错误的版本号

解决方案：

1. 获取最新版本
   Stat stat = new Stat();
   byte[] data = zk.getData("/path", false, stat);
   int latestVersion = stat.getVersion();

   // 使用正确版本更新
   zk.setData("/path", newData.getBytes(), latestVersion);

2. 使用-1忽略版本检查
   # 不推荐，可能导致数据覆盖
   zk.setData("/path", newData.getBytes(), -1);

3. 处理BadVersionException
   while (true) {
       try {
           Stat stat = new Stat();
           byte[] data = zk.getData("/path", false, stat);
           zk.setData("/path", newData.getBytes(), stat.getVersion());
           break;
       } catch (BadVersionException e) {
           // 版本冲突，重试
           continue;
       }
   }

4. 使用分布式锁保护更新
   DistributedLock lock = new DistributedLock("update-lock");
   lock.acquire();
   try {
       // 更新操作
       zk.setData("/path", newData.getBytes(), -1);
   } finally {
       lock.release();
   }
```

---

## 10.3 集群错误

### 10.3.1 Leader选举失败

```
Leader选举失败错误：

┌─────────────────────────────────────────────────────────────────┐
│  Leader选举失败错误                                      │
└─────────────────────────────────────────────────────────────────┘

错误信息：
WARN [QuorumPeermyid=1]: No vote info received; initialization must be running

原因分析：
1. 节点数量不足
2. 网络分区
3. 配置错误
4. 无法达成多数派

解决方案：

1. 检查节点数量
   # 集群节点数必须是奇数
   # 最少需要3节点

2. 检查网络连通性
   # 所有节点之间
   ping 192.168.1.102
   ping 192.168.1.103

   # 检查端口
   telnet 192.168.1.102 2888
   telnet 192.168.1.102 3888

3. 检查配置
   # zoo.cfg配置
   server.1=192.168.1.101:2888:3888
   server.2=192.168.1.102:2888:3888
   server.3=192.168.1.103:2888:3888

   # myid文件
   cat /data/zookeeper/myid

4. 检查日志
   tail -f logs/zookeeper.out

   # 查看选举日志
   grep -i "election" logs/zookeeper.out

5. 节点重启
   # 重启所有节点
   bin/zkServer.sh restart
```

### 10.3.2 无法加入集群

```
无法加入集群错误：

┌─────────────────────────────────────────────────────────────────┐
│  无法加入集群错误                                      │
└─────────────────────────────────────────────────────────────────┘

错误信息：
WARN [QuorumPeermyid=2]: Unexpected exception, retries=3, ending

原因分析：
1. 配置未同步
2. 数据不一致
3. 端口冲突
4. 版本不兼容

解决方案：

1. 检查配置是否同步
   # 所有节点的zoo.cfg应该相同
   diff /opt/zookeeper/conf/zoo.cfg server2:/opt/zookeeper/conf/zoo.cfg
   diff /opt/zookeeper/conf/zoo.cfg server3:/opt/zookeeper/conf/zoo.cfg

2. 检查myid
   # 每个节点的myid必须唯一
   cat /data/zookeeper/myid

3. 清理数据目录
   # 停止Zookeeper
   bin/zkServer.sh stop

   # 清理数据
   rm -rf /data/zookeeper/version-2/*
   rm -rf /data/zookeeper/logs/*

   # 重启
   bin/zkServer.sh start

4. 检查版本兼容性
   # 确保所有节点使用相同版本
   bin/zkServer.sh version
```

### 10.3.3 数据同步失败

```
数据同步失败错误：

┌─────────────────────────────────────────────────────────────────┐
│  数据同步失败错误                                      │
└─────────────────────────────────────────────────────────────────┘

错误信息：
WARN [QuorumPeerListener:QuorumPEERlistener@617] - Exception while listening

原因分析：
1. 网络延迟
2. 数据量过大
3. 同步超时
4. Leader异常

解决方案：

1. 检查网络
   ping -c 10 192.168.1.101
   traceroute 192.168.1.101

2. 调整同步参数
   # 在zoo.cfg中
   initLimit=20  # 增加初始化超时
   syncLimit=10  # 增加同步超时

3. 检查Leader状态
   echo "stat" | nc localhost 2181

4. 手动同步
   # 在Leader上
   echo "sync" | nc localhost 2181

5. 重启Follower
   bin/zkServer.sh restart
```

---

## 10.4 性能问题

### 10.4.1 Session堆积

```
Session堆积问题：

┌─────────────────────────────────────────────────────────────────┐
│  Session堆积问题                                      │
└─────────────────────────────────────────────────────────────────┘

问题表现：
1. 响应变慢
2. 内存使用增加
3. 连接数过多

原因分析：
1. 客户端未正确关闭
2. 频繁创建和销毁ZooKeeper实例
3. 连接泄漏

解决方案：

1. 检查连接数
   echo "cons" | nc localhost 2181

   echo "mntr" | nc localhost 2181 | grep zk_num_alive_connections

2. 检查Watcher数量
   echo "wchs" | nc localhost 2181

3. 确保正确关闭连接
   ZooKeeper zk = new ZooKeeper(...);
   try {
       // 操作
   } finally {
       zk.close();  // 重要！
   }

4. 使用连接池
   public class ZKConnectionPool {
       private Queue<ZooKeeper> pool = new LinkedList<>();

       public ZooKeeper getConnection() {
           ZooKeeper zk = pool.poll();
           if (zk == null || !zk.getState().isConnected()) {
               zk = new ZooKeeper(...);
           }
           return zk;
       }

       public void release(ZooKeeper zk) {
           if (zk.getState().isConnected()) {
               pool.add(zk);
           }
       }
   }

5. 限制最大连接数
   # 在zoo.cfg中
   maxClientCnxns=60
```

### 10.4.2 Watch堆积

```
Watch堆积问题：

┌─────────────────────────────────────────────────────────────────┐
│  Watch堆积问题                                      │
└─────────────────────────────────────────────────────────────────┘

问题表现：
1. 事件响应变慢
2. 内存使用增加
3. 通知延迟

原因分析：
1. Watch未清理
2. 频繁创建Watch
3. Watch泄漏

解决方案：

1. 检查Watch数量
   echo "wchs" | nc localhost 2181

   # 详细Watch信息
   echo "wchc" | nc localhost 2181

2. 清理无用Watch
   # 重启Zookeeper
   bin/zkServer.sh restart

3. 优化Watch使用
   # 使用一次性Watch
   zk.getData("/path", event -> {
       // 处理事件
       // 重新注册Watch
   }, null);

   # 避免在Watch中执行耗时操作
   // 将耗时操作放到异步线程

4. 监控Watch趋势
   echo "mntr" | nc localhost 2181 | grep zk_watches
```

### 10.4.3 数据量过大

```
数据量过大问题：

┌─────────────────────────────────────────────────────────────────┐
│  数据量过大问题                                      │
└─────────────────────────────────────────────────────────────────┘

问题表现：
1. 启动变慢
2. 同步变慢
3. 快照文件过大

原因分析：
1. 节点数据过大
2. 子节点过多
3. 快照保留过多

解决方案：

1. 检查数据大小
   echo "stat" | nc localhost 2181

   echo "mntr" | nc localhost 2181 | grep zk_approximate_data_size

2. 限制节点数据大小
   # 不要存储大文件
   # 使用外部存储存储大数据

3. 限制子节点数量
   # 使用配额
   setquota -n 1000 /path

4. 清理快照
   # 自动清理
   autopurge.snapRetainCount=3
   autopurge.purgeInterval=1

   # 手动清理
   bin/zkCleanup.sh -n 3

5. 优化存储
   # 使用SSD
   # 数据目录独立磁盘
```

---

## 10.5 调试技巧

### 10.5.1 日志调试

```bash
# 日志调试

# 1. 启用详细日志
# 在conf/log4j.properties中
zookeeper.root.logger=DEBUG, CONSOLE
zookeeper.console.threshold=DEBUG

# 2. 查看日志
tail -f logs/zookeeper.out

# 3. 搜索错误
grep -i "error" logs/zookeeper.out
grep -i "exception" logs/zookeeper.out
grep -i "warn" logs/zookeeper.out

# 4. 查看特定时间日志
sed -n '/2024-01-01 10:00:00/,/2024-01-01 11:00:00/p' logs/zookeeper.out

# 5. 查看GC日志
# 添加JVM参数
export JVMFLAGS="-Xlog:gc*:file=logs/gc.log"

# 6. 查看线程日志
kill -3 <pid>
# 会打印线程堆栈到stdout
```

### 10.5.2 四字命令调试

```bash
# 四字命令调试

# 1. 健康检查
echo "ruok" | nc localhost 2181

# 预期输出：imok

# 2. 状态信息
echo "stat" | nc localhost 2181

# 3. 配置文件
echo "conf" | nc localhost 2181

# 4. 监控指标
echo "mntr" | nc localhost 2181

# 5. 连接信息
echo "cons" | nc localhost 2181

# 6. 监听统计
echo "wchs" | nc localhost 2181

# 7. 监听详情（按连接）
echo "wchc" | nc localhost 2181

# 8. 监听详情（按路径）
echo "wchp" | nc localhost 2181

# 9. 会话信息
echo "dump" | nc localhost 2181

# 10. 环境信息
echo "envi" | nc localhost 2181
```

### 10.5.3 Java调试

```java
// Java调试

import org.apache.zookeeper.ZooKeeper;
import org.apache.zookeeper.Watcher;
import org.apache.zookeeper.KeeperException;

public class ZKDebugDemo {
    private static final String ZK_ADDRESS = "localhost:2181";
    private static ZooKeeper zk;

    public static void main(String[] args) throws Exception {
        // 启用调试模式
        System.setProperty("zookeeper.debug", "true");
        System.setProperty("log4j.debug", "true");

        Watcher watcher = event -> {
            System.out.println("=== DEBUG ===");
            System.out.println("事件: " + event);
            System.out.println("类型: " + event.getType());
            System.out.println("状态: " + event.getState());
            System.out.println("路径: " + event.getPath());
            System.out.println("=============");
        };

        zk = new ZooKeeper(ZK_ADDRESS, 3000, watcher);

        Thread.sleep(1000);

        try {
            // 调试创建
            String path = zk.create("/debug", "test".getBytes(),
                ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
            System.out.println("创建成功: " + path);
        } catch (Exception e) {
            System.out.println("创建失败: " + e);
            e.printStackTrace();
        }

        try {
            // 调试读取
            byte[] data = zk.getData("/debug", false, null);
            System.out.println("读取成功: " + new String(data));
        } catch (Exception e) {
            System.out.println("读取失败: " + e);
            e.printStackTrace();
        }

        zk.close();
    }
}
```

### 10.5.4 网络调试

```bash
# 网络调试

# 1. 检查端口
netstat -tlnp | grep 2181
ss -tlnp | grep 2181

# 2. 检查连接
netstat -tnp | grep 2181
ss -tnp | grep 2181

# 3. 检查网络延迟
ping 192.168.1.101

# 4. 检查端口连通性
telnet 192.168.1.101 2181

nc -zv 192.168.1.101 2181

# 5. 抓包分析
tcpdump -i eth0 port 2181 -w zk.pcap

# 6. 分析抓包文件
wireshark zk.pcap

# 7. 检查防火墙
iptables -L -n
firewall-cmd --list-all

# 8. 检查路由
route -n
ip route
```

---

## 10.6 常见错误速查表

```
常见错误速查表：

┌─────────────────────────────────────────────────────────────────┐
│  常见错误速查表                                        │
└─────────────────────────────────────────────────────────────────┘

错误类型                      原因                        解决方案
─────────────────────────────────────────────────────────────────
ConnectionLossException       网络不通/服务未启动          检查网络和服务状态
NoServerException            服务器地址错误               验证连接字符串
SessionExpiredException      会话超时                     增加sessionTimeout
NoNodeException              节点不存在                   先创建节点
NodeExistsException          节点已存在                   使用exists检查或捕获异常
BadVersionException          版本冲突                     使用正确版本或重试
NotEmptyException            节点有子节点                 先删除子节点或使用deleteall
NoAuthException              无权限                       检查ACL配置
InvalidACLException          ACL格式错误                  检查ACL格式
NotReadOnlyException         非只读模式                   使用正确连接
OperationTimeoutException    操作超时                     增加超时或检查性能
```

---

## 本章小结

- 连接错误包括连接超时、无法连接服务器等，需要检查网络、防火墙、服务状态
- 节点操作错误包括节点不存在、节点已存在、版本冲突等，需要先检查或使用异常处理
- 集群错误包括Leader选举失败、无法加入集群、数据同步失败等，需要检查配置和网络
- 性能问题包括Session堆积、Watch堆积、数据量过大等，需要监控和优化
- 调试技巧包括日志调试、四字命令调试、Java调试、网络调试等
- 常见错误速查表可以帮助快速定位和解决问题

---

**Zookeeper专题完结**
