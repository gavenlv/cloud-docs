# Doris安装部署

## 概述

本文档介绍Apache Doris的各种安装部署方式，包括单机部署、集群部署、Docker部署和Kubernetes部署。

## 环境要求

### 硬件要求

| 组件 | 最低配置 | 推荐配置 |
|------|----------|----------|
| CPU | 4核 | 8核+ |
| 内存 | 8GB | 16GB+ |
| 磁盘 | 100GB SSD | 500GB+ SSD |
| 网络 | 1Gbps | 10Gbps |

### 软件要求

- Linux内核版本：3.10+
- glibc版本：2.17+
- Java JDK 8+（用于编译）

## 单机部署

### 1. 下载安装包

```bash
# 下载Doris二进制包
wget https://apache-doris.releases.oss-cn-beijing.aliyuncs.com/apache-doris-2.0.0-bin-x86_64.tar.xz

# 解压
tar -xvf apache-doris-2.0.0-bin-x86_64.tar.xz
cd apache-doris-2.0.0-bin-x86_64
```

### 2. 配置FE

```bash
# 进入FE目录
cd fe

# 修改配置文件
cat > conf/fe.conf << EOF
# 添加以下配置
priority_networks = 192.168.1.1/24
EOF
```

### 3. 启动FE

```bash
# 启动FE
sh bin/start_fe.sh --daemon

# 检查FE状态
mysql -h 127.0.0.1 -P 9030 -uroot
SHOW FRONTENDS;
```

### 4. 配置和启动BE

```bash
# 进入BE目录
cd ../be

# 修改配置文件
cat > conf/be.conf << EOF
# 添加以下配置
priority_networks = 192.168.1.1/24
EOF

# 添加BE到集群
mysql -h 127.0.0.1 -P 9030 -uroot -p'' -e "ALTER SYSTEM ADD BACKEND '192.168.1.1:9050';"

# 启动BE
sh bin/start_be.sh --daemon
```

### 5. 验证部署

```bash
# 连接Doris
mysql -h 127.0.0.1 -P 9030 -uroot -p''

# 创建测试数据库
CREATE DATABASE test;

# 验证BE状态
SHOW BACKENDS\G
```

## Docker部署

### 1. 启动FE容器

```bash
docker run -it \
  --name doris-fe \
  -p 8030:8030 \
  -p 9030:9030 \
  -v /data/doris/fe:/opt/apache-doris/fe doris \
  apache/doris:latest_fe
```

### 2. 启动BE容器

```bash
docker run -it \
  --name doris-be \
  -p 8040:8040 \
  -p 9050:9050 \
  -p 9060:9060 \
  -v /data/doris/be:/opt/apache-doris/be \
  --env FE_HOST="fe_ip" \
  apache/doris:latest_be
```

### 3. Docker Compose部署

```yaml
version: '3.8'

services:
  fe:
    image: apache/doris:latest_fe
    container_name: doris-fe
    ports:
      - "8030:8030"
      - "9030:9030"
    volumes:
      - ./data/fe:/opt/apache-doris/fe
    environment:
      - FE_SERVERS=fe1:127.0.0.1:9010

  be:
    image: apache/doris:latest_be
    container_name: doris-be
    ports:
      - "8040:8040"
      - "9050:9050"
      - "9060:9060"
    volumes:
      - ./data/be:/opt/apache-doris/be
    environment:
      - FE_HOSTS=127.0.0.1:9030
    depends_on:
      - fe
```

## Kubernetes部署

### 1. 使用Operator部署

```yaml
apiVersion: doris.apache.org/v1alpha1
kind: DorisCluster
metadata:
  name: doris-cluster
spec:
  feSpec:
    replicas: 3
    image: apache/doris:latest_fe
    resources:
      requests:
        cpu: 2
        memory: 4Gi
  beSpec:
    replicas: 3
    image: apache/doris:latest_be
    resources:
      requests:
        cpu: 4
        memory: 8Gi
```

### 2. 部署命令

```bash
# 安装Doris Operator
kubectl apply -f https://raw.githubusercontent.com/apache/doris/master-operator/main.yaml

# 创建Doris集群
kubectl apply -f doris-cluster.yaml

# 查看集群状态
kubectl get doriscluster
kubectl get pods -l "doris.apache.org/cluster=doris-cluster"
```

## 集群部署

### 1. FE集群部署

```bash
# FE配置
cat > fe/conf/fe.conf << EOF
priority_networks = 192.168.1.0/24
EOF

# 启动第一个FE（Leader）
sh bin/start_fe.sh --helper 192.168.1.1:9010 --daemon

# 启动其他FE（Follower）
sh bin/start_fe.sh --helper 192.168.1.1:9010 --daemon

# 添加Follower
mysql -h 192.168.1.1 -P 9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER '192.168.1.2:9010';"
mysql -h 192.168.1.1 -P 9030 -uroot -e "ALTER SYSTEM ADD FOLLOWER '192.168.1.3:9010';"
```

### 2. BE集群部署

```bash
# 配置BE
cat > be/conf/be.conf << EOF
priority_networks = 192.168.1.0/24
EOF

# 添加BE到集群
mysql -h 192.168.1.1 -P 9030 -uroot -e "ALTER SYSTEM ADD BACKEND '192.168.1.4:9050';"
mysql -h 192.168.1.1 -P 9030 -uroot -e "ALTER SYSTEM ADD BACKEND '192.168.1.5:9050';"
mysql -h 192.168.1.1 -P 9030 -uroot -e "ALTER SYSTEM ADD BACKEND '192.168.1.6:9050';"

# 启动BE
sh bin/start_be.sh --daemon
```

## 常见问题

### Q: FE启动失败？

A: 检查日志：
```bash
cat fe/log/fe.log
cat fe/log/fe.out
```

### Q: BE无法添加到集群？

A: 检查网络连通性：
```bash
telnet 192.168.1.1 9030
telnet 192.168.1.1 9050
```

### Q: 端口被占用？

A: 修改配置文件中的端口：
```bash
# 修改BE端口
cat > be/conf/be.conf << EOF
be_port = 9050
webserver_port = 8040
heartbeat_service_port = 9050
brpc_port = 9060
EOF
```
