# Doris存算分离 - 本地Docker部署

## 概述

本文档介绍如何使用Docker部署Apache Doris存算分离架构，模拟生产环境。本地部署适合开发测试和功能验证。

## 前置要求

### 环境要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 至少8GB内存
- 至少100GB可用磁盘空间

### 快速启动

```bash
cd 03-local-deployment-docker/codes
docker-compose up -d

# 等待服务启动
sleep 30

# 验证服务状态
docker-compose ps
```

## 架构说明

本地Docker部署架构：

```
┌─────────────────────────────────────────────────────────┐
│                     Docker Network                      │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │    FE-1    │  │    FE-2    │  │    FE-3    │    │
│  │  (Leader)  │  │ (Follower) │  │ (Observer) │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ Compute-1  │  │ Compute-2  │  │ Compute-3  │    │
│  │ (计算+缓存) │  │ (计算+缓存) │  │ (计算+缓存) │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  ┌─────────────┐                                       │
│  │   MinIO     │                                       │
│  │  (对象存储) │                                       │
│  └─────────────┘                                       │
└─────────────────────────────────────────────────────────┘
```

## 配置说明

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| FE_SERVERS | FE节点列表 | fe1:9010,fe2:9010,fe3:9010 |
| FE_ID | 当前FE的ID | - |
| BE_ADDRS | 计算节点地址列表 | compute1:9050,compute2:9050,compute3:9050 |
| MINIO_ENDPOINT | MinIO服务地址 | minio:9000 |
| MINIO_ACCESS_KEY | MinIO访问密钥 | minioadmin |
| MINIO_SECRET_KEY | MinIO密钥 | minioadmin |
| MINIO_BUCKET | 存储桶名称 | doris-data |

### Docker Compose配置

```yaml
# docker-compose.yaml
version: '3.8'

services:
  # MinIO 对象存储
  minio:
    image: minio/minio:latest
    container_name: doris-minio
    hostname: minio
    ports:
      - "9000:9000"   # API端口
      - "9001:9001"   # Console端口
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - doris-net

  # FE节点1 (Leader)
  fe1:
    image: apache/doris:2.1.0
    container_name: doris-fe1
    hostname: fe1
    ports:
      - "8030:8030"
      - "9030:9030"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      FE_ID: 1
      PRIORITY_NETWORKS: 172.20.0.0/16
    volumes:
      - fe1-data:/opt/apache-doris/fe/meta
      - fe1-log:/opt/apache-doris/fe/log
    command: bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon
    depends_on:
      - minio
    networks:
      - doris-net

  # FE节点2 (Follower)
  fe2:
    image: apache/doris:2.1.0
    container_name: doris-fe2
    hostname: fe2
    ports:
      - "8031:8030"
      - "9031:9030"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      FE_ID: 2
      PRIORITY_NETWORKS: 172.20.0.0/16
    volumes:
      - fe2-data:/opt/apache-doris/fe/meta
      - fe2-log:/opt/apache-doris/fe/log
    command: bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon
    depends_on:
      - minio
    networks:
      - doris-net

  # FE节点3 (Observer)
  fe3:
    image: apache:doris:2.1.0
    container_name: doris-fe3
    hostname: fe3
    ports:
      - "8032:8030"
      - "9032:9030"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      FE_ID: 3
      PRIORITY_NETWORKS: 172.20.0.0/16
    volumes:
      - fe3-data:/opt/apache-doris/fe/meta
      - fe3-log:/opt/apache-doris/fe/log
    command: bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon
    depends_on:
      - minio
    networks:
      - doris-net

  # 计算节点1
  compute1:
    image: apache/doris:2.1.0
    container_name: doris-compute1
    hostname: compute1
    ports:
      - "8040:8040"
      - "9050:9050"
      - "9060:9060"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      BE_ADDRS: compute1:9050,compute2:9050,compute3:9050
      PRIORITY_NETWORKS: 172.20.0.0/16
      # 对象存储配置
      OBJECT_STORAGE_ENDPOINT: minio:9000
      OBJECT_STORAGE_REGION: us-east-1
      OBJECT_STORAGE_BUCKET: doris-data
      OBJECT_STORAGE_ACCESS_KEY: minioadmin
      OBJECT_STORAGE_SECRET_KEY: minioadmin
      OBJECT_STORAGE_USE_HTTPS: false
      # 缓存配置
      STORAGE_ROOT_PATH: /mnt/disk1/doris_cloud_cache
      CACHE_FILE_SIZE: 20
      CACHE_TTL_SECONDS: 86400
    volumes:
      - compute1-cache:/mnt/disk1/doris_cloud_cache
      - compute1-log:/opt/apache-doris/be/log
    command: bash /opt/apache-doris/be/bin/start_be.sh --daemon
    depends_on:
      - fe1
      - minio
    networks:
      - doris-net

  # 计算节点2
  compute2:
    image: apache/doris:2.1.0
    container_name: doris-compute2
    hostname: compute2
    ports:
      - "8041:8040"
      - "9051:9050"
      - "9061:9060"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      BE_ADDRS: compute1:9050,compute2:9050,compute3:9050
      PRIORITY_NETWORKS: 172.20.0.0/16
      OBJECT_STORAGE_ENDPOINT: minio:9000
      OBJECT_STORAGE_REGION: us-east-1
      OBJECT_STORAGE_BUCKET: doris-data
      OBJECT_STORAGE_ACCESS_KEY: minioadmin
      OBJECT_STORAGE_SECRET_KEY: minioadmin
      OBJECT_STORAGE_USE_HTTPS: false
      STORAGE_ROOT_PATH: /mnt/disk1/doris_cloud_cache
      CACHE_FILE_SIZE: 20
      CACHE_TTL_SECONDS: 86400
    volumes:
      - compute2-cache:/mnt/disk1/doris_cloud_cache
      - compute2-log:/opt/apache-doris/be/log
    command: bash /opt/apache-doris/be/bin/start_be.sh --daemon
    depends_on:
      - fe1
      - minio
    networks:
      - doris-net

  # 计算节点3
  compute3:
    image: apache/doris:2.1.0
    container_name: doris-compute3
    hostname: compute3
    ports:
      - "8042:8040"
      - "9052:9050"
      - "9062:9060"
    environment:
      FE_SERVERS: fe1:9010,fe2:9010,fe3:9010
      BE_ADDRS: compute1:9050,compute2:9050,compute3:9050
      PRIORITY_NETWORKS: 172.20.0.0/16
      OBJECT_STORAGE_ENDPOINT: minio:9000
      OBJECT_STORAGE_REGION: us-east-1
      OBJECT_STORAGE_BUCKET: doris-data
      OBJECT_STORAGE_ACCESS_KEY: minioadmin
      OBJECT_STORAGE_SECRET_KEY: minioadmin
      OBJECT_STORAGE_USE_HTTPS: false
      STORAGE_ROOT_PATH: /mnt/disk1/doris_cloud_cache
      CACHE_FILE_SIZE: 20
      CACHE_TTL_SECONDS: 86400
    volumes:
      - compute3-cache:/mnt/disk1/doris_cloud_cache
      - compute3-log:/opt/apache-doris/be/log
    command: bash /opt/apache-doris/be/bin/start_be.sh --daemon
    depends_on:
      - fe1
      - minio
    networks:
      - doris-net

volumes:
  minio-data:
  fe1-data:
  fe2-data:
  fe3-data:
  fe1-log:
  fe2-log:
  fe3-log:
  compute1-cache:
  compute2-cache:
  compute3-cache:
  compute1-log:
  compute2-log:
  compute3-log:

networks:
  doris-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## 部署步骤

### 1. 创建网络

```bash
docker network create doris-net --driver bridge --subnet=172.20.0.0/16
```

### 2. 启动MinIO

```bash
docker run -d \
    --name doris-minio \
    --hostname minio \
    --network doris-net \
    -p 9000:9000 \
    -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    -v minio-data:/data \
    minio/minio server /data --console-address ":9001"
```

### 3. 创建存储桶

```bash
# 安装mc客户端
docker run --rm -it --network doris-net \
    minio/mc:latest bash

# 配置MinIO连接
mc alias set myminio http://minio:9000 minioadmin minioadmin

# 创建存储桶
mc mb myminio/doris-data --ignore-existing

# 设置存储桶策略（允许公开访问）
mc anonymous set download myminio/doris-data
```

### 4. 启动FE节点

```bash
# 启动FE1 (Leader)
docker run -d \
    --name doris-fe1 \
    --hostname fe1 \
    --network doris-net \
    -p 8030:8030 \
    -p 9030:9030 \
    -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
    -e FE_ID=1 \
    -e PRIORITY_NETWORKS="172.20.0.0/16" \
    -v fe1-data:/opt/apache-doris/fe/meta \
    -v fe1-log:/opt/apache-doris/fe/log \
    apache/doris:2.1.0 \
    bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon

# 等待FE1启动
sleep 20

# 启动FE2 (Follower)
docker run -d \
    --name doris-fe2 \
    --hostname fe2 \
    --network doris-net \
    -p 8031:8030 \
    -p 9031:9030 \
    -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
    -e FE_ID=2 \
    -e PRIORITY_NETWORKS="172.20.0.0/16" \
    -v fe2-data:/opt/apache-doris/fe/meta \
    -v fe2-log:/opt/apache-doris/fe/log \
    apache/doris:2.1.0 \
    bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon

# 启动FE3 (Observer)
docker run -d \
    --name doris-fe3 \
    --hostname fe3 \
    --network doris-net \
    -p 8032:8030 \
    -p 9032:9030 \
    -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
    -e FE_ID=3 \
    -e PRIORITY_NETWORKS="172.20.0.0/16" \
    -v fe3-data:/opt/apache-doris/fe/meta \
    -v fe3-log:/opt/apache-doris/fe/log \
    apache/doris:2.1.0 \
    bash /opt/apache-doris/fe/bin/start_fe.sh --helper fe1:9010 --daemon

# 等待FE集群就绪
sleep 30
```

### 5. 启动计算节点

```bash
# 启动计算节点1
docker run -d \
    --name doris-compute1 \
    --hostname compute1 \
    --network doris-net \
    -p 8040:8040 \
    -p 9050:9050 \
    -p 9060:9060 \
    -e FE_SERVERS="fe1:9010,fe2:9010,fe3:9010" \
    -e BE_ADDRS="compute1:9050,compute2:9050,compute3:9050" \
    -e PRIORITY_NETWORKS="172.20.0.0/16" \
    -e OBJECT_STORAGE_ENDPOINT="minio:9000" \
    -e OBJECT_STORAGE_REGION="us-east-1" \
    -e OBJECT_STORAGE_BUCKET="doris-data" \
    -e OBJECT_STORAGE_ACCESS_KEY="minioadmin" \
    -e OBJECT_STORAGE_SECRET_KEY="minioadmin" \
    -e OBJECT_STORAGE_USE_HTTPS="false" \
    -e STORAGE_ROOT_PATH="/mnt/disk1/doris_cloud_cache" \
    -e CACHE_FILE_SIZE="20" \
    -e CACHE_TTL_SECONDS="86400" \
    -v compute1-cache:/mnt/disk1/doris_cloud_cache \
    -v compute1-log:/opt/apache-doris/be/log \
    apache/doris:2.1.0 \
    bash /opt/apache-doris/be/bin/start_be.sh --daemon

# 启动计算节点2和3（类似，端口递增）
```

### 6. 注册计算节点

```bash
# 连接到FE
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 添加计算节点
ALTER SYSTEM ADD BACKEND 'compute1:9050';
ALTER SYSTEM ADD BACKEND 'compute2:9050';
ALTER SYSTEM ADD BACKEND 'compute3:9050';

# 查看节点状态
SHOW BACKENDS\G
```

## 验证部署

### 1. 检查集群状态

```bash
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 查看FE状态
SHOW FRONTENDS;

# 查看BE状态
SHOW BACKENDS;

# 查看计算节点
SHOW COMPUTE NODES;
```

### 2. 创建测试表

```sql
CREATE DATABASE test_separation;
USE test_separation;

CREATE TABLE test_table (
    user_id BIGINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    age INT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) DUPLICATE KEY(user_id, username)
DISTRIBUTED BY HASH(user_id) BUCKETS 10
PROPERTIES (
    "storage_medium" = "SSD"
);

-- 插入测试数据
INSERT INTO test_table VALUES
(1, 'user1', 'user1@example.com', 25, NOW()),
(2, 'user2', 'user2@example.com', 30, NOW()),
(3, 'user3', 'user3@example.com', 28, NOW());

-- 查询数据
SELECT * FROM test_table;
```

### 3. 验证对象存储

```bash
# 查看MinIO中的数据
docker run --rm -it --network doris-net \
    minio/mc:latest bash

mc alias set myminio http://minio:9000 minioadmin minioadmin
mc ls myminio/doris-data/
```

## 清理

```bash
# 停止所有容器
docker-compose down

# 或者逐个停止
docker stop doris-compute3 doris-compute2 doris-compute1
docker stop doris-fe3 doris-fe2 doris-fe1
docker stop doris-minio

# 删除容器
docker rm doris-compute3 doris-compute2 doris-compute1
docker rm doris-fe3 doris-fe2 doris-fe1
docker rm doris-minio

# 删除数据卷
docker volume rm $(docker volume ls -qf name=doris)
```

## 常见问题

### Q: FE启动失败？

A: 检查日志：
```bash
docker logs doris-fe1
cat fe1-log/fe.log
```

### Q: 计算节点无法连接到FE？

A: 检查网络连通性：
```bash
docker exec doris-compute1 ping fe1
```

### Q: 对象存储访问失败？

A: 验证MinIO配置：
```bash
docker logs doris-minio
```
