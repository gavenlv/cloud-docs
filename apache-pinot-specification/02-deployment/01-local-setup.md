# Pinot 本地开发环境搭建

## 概述

本文档介绍如何在本地快速搭建 Apache Pinot 开发环境，包括 Docker 方式、手动安装方式和 Kubernetes 方式。

---

## 1. Docker 方式（推荐）

### 1.1 快速启动

```bash
# 拉取 Pinot 镜像
docker pull apachepinot/pinot:latest

# 启动 QuickStart（包含示例数据）
docker run -p 9000:9000 apachepinot/pinot:latest QuickStart -type batch

# 访问 Pinot Controller UI
open http://localhost:9000
```

### 1.2 Docker Compose 部署

```yaml
# docker-compose.yml
version: '3.7'

services:
  zookeeper:
    image: zookeeper:3.9
    hostname: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  pinot-controller:
    image: apachepinot/pinot:latest
    command: StartController
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      JAVA_OPTS: "-Xms1G -Xmx1G -Dlog4j2.configurationFile=/opt/pinot/conf/log4j2.xml"
      PINOT_ZK_SERVER: zookeeper:2181
    depends_on:
      - zookeeper

  pinot-broker:
    image: apachepinot/pinot:latest
    command: StartBroker
    restart: unless-stopped
    ports:
      - "8099:8099"
    environment:
      JAVA_OPTS: "-Xms1G -Xmx1G -Dlog4j2.configurationFile=/opt/pinot/conf/log4j2.xml"
      PINOT_ZK_SERVER: zookeeper:2181
    depends_on:
      - pinot-controller

  pinot-server:
    image: apachepinot/pinot:latest
    command: StartServer
    restart: unless-stopped
    ports:
      - "8098:8098"
      - "8097:8097"
    environment:
      JAVA_OPTS: "-Xms2G -Xmx2G -Dlog4j2.configurationFile=/opt/pinot/conf/log4j2.xml"
      PINOT_ZK_SERVER: zookeeper:2181
    depends_on:
      - pinot-broker

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    depends_on:
      - zookeeper
```

```bash
# 启动服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f pinot-controller

# 停止服务
docker-compose down
```

### 1.3 完整开发环境

```yaml
# docker-compose-full.yml
version: '3.7'

services:
  zookeeper:
    image: zookeeper:3.9
    hostname: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  pinot-controller:
    image: apachepinot/pinot:latest
    command: StartController -zkAddress zookeeper:2181
    ports:
      - "9000:9000"
    environment:
      JAVA_OPTS: "-Xms1G -Xmx1G"

  pinot-broker:
    image: apachepinot/pinot:latest
    command: StartBroker -zkAddress zookeeper:2181
    ports:
      - "8099:8099"
    environment:
      JAVA_OPTS: "-Xms1G -Xmx1G"

  pinot-server:
    image: apachepinot/pinot:latest
    command: StartServer -zkAddress zookeeper:2181
    ports:
      - "8098:8098"
    environment:
      JAVA_OPTS: "-Xms2G -Xmx2G"

  pinot-minion:
    image: apachepinot/pinot:latest
    command: StartMinion -zkAddress zookeeper:2181
    environment:
      JAVA_OPTS: "-Xms512M -Xmx512M"

  # 可选：可视化工具
  superset:
    image: apache/superset:latest
    ports:
      - "8088:8088"
    environment:
      SUPERSET_SECRET_KEY: "your-secret-key"
```

---

## 2. 手动安装

### 2.1 环境要求

```bash
# Java 11+
java -version

# Maven 3.6+
mvn -version

# Git
git --version
```

### 2.2 编译安装

```bash
# 克隆源码
git clone https://github.com/apache/pinot.git
cd pinot

# 编译（跳过测试）
mvn clean install -DskipTests -Pbin-dist

# 进入发行版目录
cd pinot-distribution/target/apache-pinot-*/apache-pinot-*/

# 启动 ZooKeeper
bin/pinot-admin.sh StartZookeeper &

# 启动 Controller
bin/pinot-admin.sh StartController -zkAddress localhost:2181 &

# 启动 Broker
bin/pinot-admin.sh StartBroker -zkAddress localhost:2181 &

# 启动 Server
bin/pinot-admin.sh StartServer -zkAddress localhost:2181 &
```

### 2.3 目录结构

```
apache-pinot-*/
├── bin/                          # 启动脚本
│   ├── pinot-admin.sh            # 管理命令
│   ├── pinot-service.sh          # 服务启动
│   └── pinot-quick-start.sh      # 快速启动
├── conf/                         # 配置文件
│   ├── pinot-controller.conf     # Controller 配置
│   ├── pinot-broker.conf         # Broker 配置
│   ├── pinot-server.conf         # Server 配置
│   └── log4j2.xml               # 日志配置
├── lib/                          # 依赖库
├── plugins/                      # 插件
└── examples/                     # 示例数据
    ├── batch/                    # 批量摄入示例
    └── stream/                   # 流式摄入示例
```

---

## 3. Kubernetes 部署

### 3.1 使用 Helm 部署

```bash
# 添加 Pinot Helm 仓库
helm repo add pinot https://raw.githubusercontent.com/apache/pinot/master/kubernetes/helm
helm repo update

# 查看配置选项
helm show values pinot/pinot

# 安装 Pinot（开发环境）
helm install pinot pinot/pinot \
  --set cluster.name=pinot \
  --set controller.replicaCount=1 \
  --set broker.replicaCount=1 \
  --set server.replicaCount=2

# 查看状态
kubectl get pods -l app=pinot

# 端口转发访问 UI
kubectl port-forward svc/pinot-controller 9000:9000
```

### 3.2 自定义 Helm 配置

```yaml
# pinot-values.yaml
cluster:
  name: pinot

controller:
  replicaCount: 2
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  persistence:
    enabled: true
    size: 10Gi

broker:
  replicaCount: 2
  resources:
    requests:
      cpu: 1000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi

server:
  replicaCount: 3
  resources:
    requests:
      cpu: 2000m
      memory: 8Gi
    limits:
      cpu: 8000m
      memory: 16Gi
  persistence:
    enabled: true
    size: 100Gi

zookeeper:
  enabled: true
  replicaCount: 3
  persistence:
    enabled: true
    size: 10Gi

kafka:
  enabled: true
  replicaCount: 3
```

```bash
# 使用自定义配置安装
helm install pinot pinot/pinot -f pinot-values.yaml
```

### 3.3 原生 Kubernetes 部署

```yaml
# pinot-controller.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pinot-controller
  namespace: pinot
spec:
  serviceName: pinot-controller
  replicas: 2
  selector:
    matchLabels:
      app: pinot-controller
  template:
    metadata:
      labels:
        app: pinot-controller
    spec:
      containers:
      - name: pinot-controller
        image: apachepinot/pinot:latest
        command: ["StartController"]
        env:
        - name: JAVA_OPTS
          value: "-Xms1G -Xmx1G"
        - name: PINOT_ZK_SERVER
          value: "zookeeper:2181"
        ports:
        - containerPort: 9000
          name: http
        resources:
          requests:
            cpu: 1000m
            memory: 2Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        volumeMounts:
        - name: data
          mountPath: /var/pinot/controller
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi

---
apiVersion: v1
kind: Service
metadata:
  name: pinot-controller
  namespace: pinot
spec:
  selector:
    app: pinot-controller
  ports:
  - port: 9000
    targetPort: 9000
    name: http
  type: ClusterIP
```

```bash
# 创建命名空间
kubectl create namespace pinot

# 部署组件
kubectl apply -f pinot-controller.yaml
kubectl apply -f pinot-broker.yaml
kubectl apply -f pinot-server.yaml

# 查看状态
kubectl get pods -n pinot
```

---

## 4. 验证安装

### 4.1 检查服务状态

```bash
# 检查 Controller
curl http://localhost:9000/health

# 查看集群信息
curl http://localhost:9000/cluster/info

# 查看表列表
curl http://localhost:9000/tables

# 查看 Broker 路由
curl http://localhost:8099/debug/routingTable
```

### 4.2 创建测试表

```bash
# 1. 创建 Schema
cat > user_events_schema.json << 'EOF'
{
  "schemaName": "user_events",
  "dimensionFieldSpecs": [
    {"name": "user_id", "dataType": "STRING"},
    {"name": "event_type", "dataType": "STRING"},
    {"name": "country", "dataType": "STRING"}
  ],
  "metricFieldSpecs": [
    {"name": "value", "dataType": "DOUBLE"}
  ],
  "dateTimeFieldSpecs": [
    {
      "name": "timestamp",
      "dataType": "LONG",
      "format": "1:MILLISECONDS:EPOCH",
      "granularity": "1:HOURS"
    }
  ]
}
EOF

curl -X POST -H "Content-Type: application/json" \
  -d @user_events_schema.json \
  http://localhost:9000/schemas

# 2. 创建 Table
cat > user_events_table.json << 'EOF'
{
  "tableName": "user_events",
  "tableType": "OFFLINE",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "1"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP"
  },
  "tenants": {
    "broker": "DefaultTenant",
    "server": "DefaultTenant"
  }
}
EOF

curl -X POST -H "Content-Type: application/json" \
  -d @user_events_table.json \
  http://localhost:9000/tables

# 3. 验证表创建
curl http://localhost:9000/tables/user_events
```

### 4.3 测试查询

```bash
# 查询表数据
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT * FROM user_events LIMIT 10"}' \
  http://localhost:8099/query/sql
```

---

## 5. 常见问题

### 5.1 端口冲突

```bash
# 检查端口占用
lsof -i :9000
lsof -i :8099
lsof -i :8098

# 修改端口（启动参数）
bin/pinot-admin.sh StartController \
  -zkAddress localhost:2181 \
  -controllerPort 9001
```

### 5.2 内存不足

```bash
# 调整 JVM 内存
export JAVA_OPTS="-Xms512M -Xmx512M"

# Docker 方式
docker run -e JAVA_OPTS="-Xms512M -Xmx512M" apachepinot/pinot:latest QuickStart
```

### 5.3 ZooKeeper 连接失败

```bash
# 检查 ZooKeeper 状态
echo ruok | nc localhost 2181

# 查看 ZooKeeper 日志
docker-compose logs zookeeper
```

---

## 参考链接

- [Pinot Docker 部署](https://docs.pinot.apache.org/basics/getting-started/running-pinot-in-docker)
- [Pinot Kubernetes 部署](https://docs.pinot.apache.org/basics/getting-started/kubernetes-setup)
- [Pinot Helm Chart](https://github.com/apache/pinot/tree/master/kubernetes/helm)
