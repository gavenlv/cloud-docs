# Apache Doris专题

## 概述

本专题提供从基础到专家级的Apache Doris教程，涵盖Doris核心概念、安装部署、集群管理、SQL基础、表设计、数据导入、性能调优、安全配置、备份恢复和监控告警。每个章节都包含详细的代码示例、配置说明和验证步骤，帮助读者深入理解Doris的使用方法。

## 目录结构

```
apache-doris-specification/
├── README.md                              # 本文件
├── 01-doris-fundamentals/                 # Doris基础
│   └── 01-doris-fundamentals.md
├── 02-doris-installation/                 # Doris安装部署
│   ├── 02-doris-installation.md
│   └── codes/
│       ├── docker-compose.yaml            # Docker Compose部署
│       ├── doris-cluster.yaml             # Kubernetes部署
│       ├── fe.conf                        # FE配置
│       └── be.conf                        # BE配置
├── 03-doris-cluster-management/           # 集群管理
│   ├── 03-doris-cluster-management.md
│   └── codes/
│       ├── add-node.sql                   # 添加节点SQL
│       └── scale-out.sh                   # 扩容脚本
├── 04-doris-sql-basics/                  # SQL基础
│   ├── 04-doris-sql-basics.md
│   └── codes/
│       └── sql-basics.sql                 # SQL基础示例
├── 05-doris-table-design/                # 表设计
│   ├── 05-doris-table-design.md
│   └── codes/
│       ├── table-dup.sql                  # Duplicate模型表
│       ├── table-agg.sql                  # Aggregate模型表
│       ├── table-unique.sql               # Unique模型表
│       └── partition-example.sql          # 分区表示例
├── 06-doris-data-loading/                # 数据导入
│   ├── 06-doris-data-loading.md
│   └── codes/
│       ├── stream-load.sh                 # Stream Load示例
│       ├── broker-load.sql                # Broker Load示例
│       ├── routine-load.sql               # Routine Load示例
│       └── s3-load.sql                    # S3 Import示例
├── 07-doris-performance-tuning/          # 性能调优
│   ├── 07-doris-performance-tuning.md
│   └── codes/
│       ├── explain-example.sql            # 执行计划分析
│       └── materialized-view.sql         # 物化视图示例
├── 08-doris-security/                    # 安全配置
│   ├── 08-doris-security.md
│   └── codes/
│       ├── user-management.sql           # 用户管理SQL
│       └── ldap-config.properties         # LDAP配置
├── 09-doris-backup-recovery/             # 备份恢复
│   ├── 09-doris-backup-recovery.md
│   └── codes/
│       ├── backup.sql                    # 备份SQL
│       └── restore.sql                    # 恢复SQL
├── 10-doris-monitoring/                  # 监控告警
│   ├── 10-doris-monitoring.md
│   └── codes/
│       ├── prometheus.yml                # Prometheus配置
│       ├── alert-rules.yml               # 告警规则
│       └── grafana-dashboard.json        # Grafana面板
├── docker/                              # Docker部署
│   ├── docker-compose.yml
│   └── Dockerfile_fe
│   └── Dockerfile_be
├── k8s/                                 # Kubernetes部署
│   ├── doris-operator.yaml
│   └── doris-cluster.yaml
└── bin/                                 # 运维脚本
    ├── start_fe.sh
    ├── start_be.sh
    └── init_fe.sh
```

## 快速开始

### 1. Docker快速部署

```bash
cd docker
docker-compose up -d

# 连接Doris
mysql -h 127.0.0.1 -P 9030 -uroot -p''
```

### 2. 创建测试表

```sql
CREATE TABLE IF NOT EXISTS example_db.test_table
(
    user_id LARGEINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age SMALLINT
)
DUPLICATE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "replication_num" = "1"
);
```

### 3. 导入数据

```bash
# Stream Load导入
curl --location-trusted -u root: \
    -T data.csv \
    -H "column_separator:," \
    -H "columns: user_id, username, email, age" \
    http://127.0.0.1:8030/api/example_db/test_table/_stream_load
```

## 章节运行指南

### 01-doris-fundamentals - Doris基础

**运行命令：**
```bash
# 连接Doris查看集群状态
mysql -h 127.0.0.1 -P 9030 -uroot -p''
SHOW FRONTENDS;
SHOW BACKENDS;
```

### 02-doris-installation - 安装部署

**运行命令：**
```bash
# Docker部署
cd docker
docker-compose up -d

# Kubernetes部署
kubectl apply -f ../k8s/doris-cluster.yaml

# 验证部署
mysql -h 127.0.0.1 -P 9030 -uroot -p''
SHOW FRONTENDS;
SHOW BACKENDS;
```

### 03-doris-cluster-management - 集群管理

**运行命令：**
```bash
# 连接Doris执行集群管理
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 添加BE节点
ALTER SYSTEM ADD BACKEND 'be_host:9050';

# 查看集群状态
SHOW BACKENDS;
SHOW PROC '/backends';
```

### 04-doris-sql-basics - SQL基础

**运行命令：**
```bash
# 连接Doris执行SQL
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 执行SQL基础示例
source 04-doris-sql-basics/codes/sql-basics.sql;
```

### 05-doris-table-design - 表设计

**运行命令：**
```bash
# 连接Doris执行建表SQL
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 创建Duplicate模型表
source 05-doris-table-design/codes/table-dup.sql;

# 创建分区表
source 05-doris-table-design/codes/partition-example.sql;
```

### 06-doris-data-loading - 数据导入

**运行命令：**
```bash
# Stream Load导入
cd 06-doris-data-loading/codes
bash stream-load.sh

# Broker Load导入
mysql -h 127.0.0.1 -P 9030 -uroot -p''
source broker-load.sql;
```

### 07-doris-performance-tuning - 性能调优

**运行命令：**
```bash
# 连接Doris分析执行计划
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 分析查询计划
source 07-doris-performance-tuning/codes/explain-example.sql;

# 创建物化视图
source 07-doris-performance-tuning/codes/materialized-view.sql;
```

### 08-doris-security - 安全配置

**运行命令：**
```bash
# 连接Doris执行用户管理
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 用户管理
source 08-doris-security/codes/user-management.sql;
```

### 09-doris-backup-recovery - 备份恢复

**运行命令：**
```bash
# 连接Doris执行备份
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 执行备份
source 09-doris-backup-recovery/codes/backup.sql;

# 执行恢复
source 09-doris-backup-recovery/codes/restore.sql;
```

### 10-doris-monitoring - 监控告警

**运行命令：**
```bash
# 启动Prometheus
cd 10-doris-monitoring/codes
docker run -d --name=prometheus -p 9090:9090 \
    -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus

# 启动Grafana
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

## 学习路径

### 初级路径

1. [01-doris-fundamentals](./01-doris-fundamentals/) - 掌握Doris基础概念
2. [02-doris-installation](./02-doris-installation/) - 掌握Doris安装部署
3. [04-doris-sql-basics](./04-doris-sql-basics/) - 掌握SQL基础

### 中级路径

1. [03-doris-cluster-management](./03-doris-cluster-management/) - 掌握集群管理
2. [05-doris-table-design](./05-doris-table-design/) - 掌握表设计
3. [06-doris-data-loading](./06-doris-data-loading/) - 掌握数据导入

### 高级路径

1. [07-doris-performance-tuning](./07-doris-performance-tuning/) - 掌握性能调优
2. [08-doris-security](./08-doris-security/) - 掌握安全配置
3. [09-doris-backup-recovery](./09-doris-backup-recovery/) - 掌握备份恢复
4. [10-doris-monitoring](./10-doris-monitoring/) - 掌握监控告警

## 前置要求

### 必备工具

- MySQL Client >= 5.7
- Docker (用于容器部署)
- Kubernetes (用于K8s部署)
- Prometheus + Grafana (用于监控)

### 硬件要求

| 组件 | 最低配置 | 推荐配置 |
|------|----------|----------|
| CPU | 4核 | 8核+ |
| 内存 | 8GB | 16GB+ |
| 磁盘 | 100GB SSD | 500GB+ SSD |

## 常见问题

### Q: FE无法启动？

A: 检查日志：
```bash
cat fe/log/fe.log
cat fe/log/fe.out
```

### Q: BE无法添加到集群？

A: 检查网络连通性：
```bash
telnet fe_host 9030
telnet be_host 9050
```

### Q: 导入数据失败？

A: 查看导入错误：
```sql
SHOW LOAD WARNINGS;
```

### Q: 查询很慢？

A: 分析执行计划：
```sql
EXPLAIN SELECT * FROM table_name WHERE condition;
```

## 相关资源

- [Apache Doris官方文档](https://doris.apache.org/zh-CN/)
- [Apache Doris GitHub](https://github.com/apache/doris)
- [Doris社区](https://doris.apache.org/zh-CN/community)
