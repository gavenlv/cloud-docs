# Pinot 扩缩容指南

## 概述

本文档介绍 Apache Pinot 的水平扩展和垂直扩展策略。

---

## 1. 扩展策略

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 扩展策略                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  水平扩展（Scale Out）                                                   │
│  ─────────────────────────────                                          │
│  ├── 增加 Broker 节点：提高查询并发                                      │
│  ├── 增加 Server 节点：提高存储容量和查询吞吐量                          │
│  ├── 增加 Minion 节点：提高后台任务处理能力                              │
│  └── 特点：无单点瓶颈，线性扩展                                         │
│                                                                          │
│  垂直扩展（Scale Up）                                                    │
│  ─────────────────────────────                                          │
│  ├── 增加 CPU：提高单节点处理能力                                        │
│  ├── 增加内存：提高缓存命中率                                            │
│  ├── 增加磁盘：提高存储容量                                              │
│  └── 特点：简单快速，有上限                                             │
│                                                                          │
│  自动扩展                                                                │
│  ─────────────────                                                      │
│  ├── HPA（Kubernetes Horizontal Pod Autoscaler）                         │
│  ├── 基于 CPU/内存阈值                                                   │
│  ├── 基于查询延迟                                                        │
│  └── 基于队列深度                                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Broker 扩容

### 2.1 扩容场景

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Broker 扩容场景                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  触发条件：                                                              │
│  ─────────────────                                                      │
│  ├── 查询延迟增加（P99 > 阈值）                                          │
│  ├── CPU 使用率持续高位（> 80%）                                         │
│  ├── 内存使用率持续高位（> 80%）                                         │
│  └── 连接数接近上限                                                      │
│                                                                          │
│  扩容影响：                                                              │
│  ─────────────────                                                      │
│  ├── 无数据迁移                                                          │
│  ├── 查询自动路由到新节点                                                │
│  ├── 扩容期间服务不中断                                                  │
│  └── 扩容后查询并发能力提升                                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Kubernetes 扩容

```bash
# 手动扩容
kubectl scale deployment pinot-broker --replicas=4 -n pinot

# 查看扩容状态
kubectl get pods -l app=pinot-broker -n pinot

# HPA 配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pinot-broker-hpa
  namespace: pinot
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pinot-broker
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

---

## 3. Server 扩容

### 3.1 扩容场景

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Server 扩容场景                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  触发条件：                                                              │
│  ─────────────────                                                      │
│  ├── 磁盘使用率 > 80%                                                    │
│  ├── 查询扫描数据量过大                                                  │
│  ├── Segment 加载时间过长                                                │
│  └── 内存不足以缓存热数据                                                │
│                                                                          │
│  扩容影响：                                                              │
│  ─────────────────                                                      │
│  ├── 新 Segment 会分配到新节点                                           │
│  ├── 现有 Segment 可选择性迁移                                           │
│  ├── 扩容期间查询可能受影响                                              │
│  └── 需要重新平衡数据                                                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 数据重新平衡

```bash
# 触发重新平衡
curl -X POST \
  http://pinot-controller:9000/tables/{tableName}/rebalance \
  -H "Content-Type: application/json" \
  -d '{
    "dryRun": false,
    "reassignInstances": true,
    "includeConsuming": true,
    "bootstrap": false,
    "downtime": false
  }'

# 干运行（查看影响）
curl -X POST \
  http://pinot-controller:9000/tables/{tableName}/rebalance \
  -H "Content-Type: application/json" \
  -d '{
    "dryRun": true,
    "reassignInstances": true,
    "includeConsuming": true
  }'
```

### 3.3 Kubernetes 扩容

```bash
# 扩容 Server
kubectl scale statefulset pinot-server --replicas=5 -n pinot

# 等待新 Pod 就绪
kubectl rollout status statefulset pinot-server -n pinot

# 触发重新平衡
curl -X POST \
  http://pinot-controller:9000/tables/user_events/rebalance \
  -H "Content-Type: application/json" \
  -d '{
    "dryRun": false,
    "reassignInstances": true,
    "includeConsuming": true
  }'
```

---

## 4. 存储扩容

### 4.1 磁盘扩容

```bash
# Kubernetes PVC 扩容（需要 StorageClass 支持）
kubectl patch pvc data-pinot-server-0 \
  -n pinot \
  -p '{"spec":{"resources":{"requests":{"storage":"1Ti"}}}}'

# 验证扩容
kubectl get pvc data-pinot-server-0 -n pinot

# 重启 Pod 使扩容生效
kubectl delete pod pinot-server-0 -n pinot
```

### 4.2 数据归档

```json
{
  "tableName": "user_events",
  "tableType": "OFFLINE",
  "segmentsConfig": {
    "retentionTimeUnit": "DAYS",
    "retentionTimeValue": "90"
  }
}
```

---

## 5. 性能调优

### 5.1 JVM 调优

```bash
# Server JVM 配置
export JAVA_OPTS="
  -Xms32G -Xmx32G
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:+ParallelRefProcEnabled
  -XX:InitiatingHeapOccupancyPercent=35
  -XX:G1HeapRegionSize=16m
  -XX:+PrintGCDetails
  -XX:+PrintGCDateStamps
  -Xloggc:/var/log/pinot/gc.log
"
```

### 5.2 查询调优

```json
{
  "tableIndexConfig": {
    "invertedIndexColumns": ["user_id", "country"],
    "sortedColumn": ["timestamp"],
    "starTreeIndexConfigs": [
      {
        "dimensionsSplitOrder": ["country", "event_type"],
        "functionColumnPairs": ["SUM__revenue", "COUNT__*"]
      }
    ]
  }
}
```

---

## 参考链接

- [Pinot Scaling](https://docs.pinot.apache.org/operators/operating-pinot/scaling-pinot)
- [Pinot Rebalance](https://docs.pinot.apache.org/operators/operating-pinot/rebalance)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
