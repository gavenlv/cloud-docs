# Doris集群管理

## 概述

本文档介绍Doris集群的日常管理操作，包括节点管理、扩缩容、故障恢复和配置管理。

## 节点管理

### 查看集群状态

```sql
-- 查看FE节点状态
SHOW FRONTENDS;

-- 查看BE节点状态
SHOW BACKENDS;

-- 查看所有进程状态
SHOW PROC '/frontends';
SHOW PROC '/backends';

-- 查看Broker状态
SHOW BROKER;
```

### 添加节点

```sql
-- 添加FE Follower
ALTER SYSTEM ADD FOLLOWER 'fe_host:9010';

-- 添加FE Observer
ALTER SYSTEM ADD OBSERVER 'observer_host:9010';

-- 添加BE节点
ALTER SYSTEM ADD BACKEND 'be_host:9050';

-- 添加Broker
ALTER SYSTEM ADD BROKER broker_name 'broker_host:8000';
```

### 删除节点

```sql
-- 下线BE节点（安全删除，先迁移数据）
ALTER SYSTEM DECOMMISSION BACKEND 'be_host:9050';

-- 强制删除BE节点
ALTER SYSTEM DROP BACKEND 'be_host:9050';

-- 删除FE节点
ALTER SYSTEM DROP FOLLOWER 'fe_host:9010';
ALTER SYSTEM DROP OBSERVER 'observer_host:9010';

-- 删除Broker
ALTER SYSTEM DROP BROKER broker_name 'broker_host:8000';
```

### 节点操作

```bash
# 启动FE
sh bin/start_fe.sh --daemon

# 停止FE
sh bin/stop_fe.sh

# 启动BE
sh bin/start_be.sh --daemon

# 停止BE
sh bin/stop_be.sh

# 重启BE（滚动升级）
ALTER SYSTEM STOP BACKEND 'be_host:9050';
sh bin/stop_be.sh
sh bin/start_be.sh --daemon
ALTER SYSTEM START BACKEND 'be_host:9050';
```

## 扩缩容

### 扩容BE

```bash
# 1. 在新服务器上安装BE
scp -r be.tar.gz new_host:/opt/
ssh new_host
tar -xvf be.tar.gz

# 2. 配置BE
cat > be/conf/be.conf << EOF
priority_networks = 192.168.1.0/24
EOF

# 3. 添加到集群
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM ADD BACKEND 'new_be_host:9050';"

# 4. 启动BE
ssh new_host
cd be && sh bin/start_be.sh --daemon

# 5. 验证状态
mysql -h fe_host -P 9030 -uroot -e "SHOW BACKENDS;"
```

### 缩容BE

```bash
# 1. 检查数据迁移状态
SHOW PROC '/backends';

# 2. 安全下线（推荐）
ALTER SYSTEM DECOMMISSION BACKEND 'be_host:9050';

# 3. 等待数据迁移完成
# 直到Backend的TabletNum变为0

# 4. 下线完成后停止BE
ssh be_host
cd be && sh bin/stop_be.sh

# 5. 从集群移除
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM DROP BACKEND 'be_host:9050';"
```

### FE扩缩容

```bash
# 扩容FE Observer（只读副本，不参与选举）
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM ADD OBSERVER 'observer_host:9010';"

# 在新服务器启动Observer
sh bin/start_fe.sh --helper leader_host:9010 --daemon

# 缩容FE Follower（需要先转移leader）
# 1. 转移Leader到其他节点
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM TRANSFER LEADER TO 'other_follower:9010';"

# 2. 停止要被删除的Follower
ssh target_host
cd fe && sh bin/stop_fe.sh

# 3. 从集群移除
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM DROP FOLLOWER 'target_host:9010';"
```

## 故障恢复

### BE故障恢复

```sql
-- 查看失败的BE
SHOW BACKENDS\G

-- 检查BE状态
SHOW PROC '/backends';
```

```bash
# 1. 如果是临时故障，尝试重启BE
ssh be_host
cd be && sh bin/stop_be.sh
sh bin/start_be.sh --daemon

# 2. 如果BE数据损坏，需要重新添加
# 先删除坏节点
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM DROP BACKEND 'bad_be_host:9050';"

# 重新添加
mysql -h fe_host -P 9030 -uroot -e "ALTER SYSTEM ADD BACKEND 'new_be_host:9050';"

# 启动新BE
ssh new_be_host
cd be && sh bin/start_be.sh --daemon
```

### FE故障恢复

```bash
# 1. 检查FE状态
mysql -h fe_host -P 9030 -uroot -e "SHOW FRONTENDS;"

# 2. 如果是Followder故障
# 重启Follower
ssh follower_host
cd fe && sh bin/stop_fe.sh
sh bin/start_fe.sh --helper leader_host:9010 --daemon

# 3. 如果是Leader故障
# Leader会自动选举
# 检查新Leader
mysql -h any_fe_host -P 9030 -uroot -e "SHOW FRONTENDS;" | grep Leader

# 4. 如果需要重新部署FE
# 添加回集群
mysql -h new_leader -P 9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER 'new_follower:9010';"
```

### 恢复取消的Tablet

```sql
-- 查看损坏的Tablet
SHOW TABLETS;

-- 修复Tablet（通过重新分发）
ADMIN REPAIR TABLE database.table;
```

## 配置管理

### 修改配置

```sql
-- 修改FE配置（动态）
ADMIN SET FRONTEND CONFIG ("key" = "value");

-- 查看FE配置
SHOW VARIABLES;

-- 示例：修改查询超时时间
ADMIN SET FRONTEND CONFIG ("query_timeout" = "3600");
```

```bash
# 修改BE配置（需要重启）
# 编辑配置文件
vim be/conf/be.conf

# 需要修改的配置项
be_port = 9050
webserver_port = 8040
heartbeat_service_port = 9050
brpc_port = 9060
storage_root_path = /data/doris
```

### 常用配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| be_port | BE thrift server端口 | 9050 |
| webserver_port | BE HTTP服务端口 | 8040 |
| heartbeat_service_port | BE心跳端口 | 9050 |
| brpc_port | BE RPC端口 | 9060 |
| storage_root_path | 存储路径 | storage |
| sys_log_dir | 日志目录 | log |

## 集群升级

### 滚动升级BE

```bash
# 1. 升级前检查
mysql -h fe_host -P 9030 -uroot -e "SHOW BACKENDS;"

# 2. 停止一个BE
ALTER SYSTEM STOP BACKEND 'be_host:9050';
ssh be_host
cd be && sh bin/stop_be.sh

# 3. 替换BE文件
scp -r apache-doris-new/be/* be_host:/opt/apache-doris/be/

# 4. 启动BE
sh bin/start_be.sh --daemon
ALTER SYSTEM START BACKEND 'be_host:9050';

# 5. 验证状态
mysql -h fe_host -P 9030 -uroot -e "SHOW BACKENDS;"

# 6. 重复以上步骤升级其他BE
```

### 升级FE

```bash
# 1. 停止Observer（如果有）
# 2. 升级Follower
# 3. 最后升级Leader
```
