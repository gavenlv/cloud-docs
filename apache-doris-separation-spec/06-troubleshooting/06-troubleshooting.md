# Doris存算分离 - 故障排除

## 概述

本文档汇总了Doris存算分离部署中的常见问题及其解决方案。

## FE问题

### 1. FE无法启动

**症状**: FE Pod一直处于CrashLoopBackOff状态

**排查步骤**:
```bash
# 查看FE日志
kubectl logs -n doris doris-fe-0 --previous

# 检查FE配置
kubectl exec -it doris-fe-0 -n doris -- cat /opt/apache-doris/fe/conf/fe.conf

# 检查端口占用
kubectl exec -it doris-fe-0 -n doris -- netstat -tlnp | grep 9030
```

**常见原因**:
1. 端口被占用
2. 配置文件错误
3. 磁盘空间不足

**解决方案**:
```bash
# 清理日志
kubectl exec -it doris-fe-0 -n doris -- rm -rf /opt/apache-doris/fe/log/*

# 重启FE
kubectl rollout restart statefulset/doris-fe -n doris
```

### 2. FE Leader选举失败

**症状**: FE集群中没有任何Leader

**排查步骤**:
```bash
# 查看FE状态
kubectl exec -it doris-fe-0 -n doris -- mysql -h doris-fe-0 -P 9030 -uroot -e "SHOW FRONTENDS;"

# 检查网络连通性
kubectl exec -it doris-fe-0 -n doris -- ping doris-fe-1
```

**解决方案**:
```sql
-- 手动设置Leader
ALTER SYSTEM SET FRONTEND ("address" = "fe1:9010", "vote" = "true");
```

## 计算节点问题

### 1. 计算节点无法注册

**症状**: 计算节点状态一直为Dead

**排查步骤**:
```bash
# 查看BE日志
kubectl logs -n doris doris-compute-0 --tail=200 | grep -i error

# 检查网络连通性
kubectl exec -it doris-fe-0 -n doris -- ping doris-compute-0

# 检查FE连接配置
kubectl exec -it doris-compute-0 -n doris -- env | grep FE
```

**解决方案**:
```bash
# 删除错误的BE节点
mysql -h doris-fe -P 9030 -uroot -p -e "ALTER SYSTEM DROP BACKEND 'old_backend_ip:9050';"

# 重新添加BE
mysql -h doris-fe -P 9030 -uroot -p -e "ALTER SYSTEM ADD BACKEND 'doris-compute-0.doris-compute.doris.svc.cluster.local:9050';"
```

### 2. 计算节点CPU/内存使用率高

**症状**: 计算节点负载异常高

**排查步骤**:
```bash
# 查看资源使用
kubectl top pods -n doris -l app=doris,component=compute

# 查看BE进程
kubectl exec -it doris-compute-0 -n doris -- ps aux | grep be
```

**解决方案**:
```bash
# 扩容（增加计算节点）
kubectl scale statefulset doris-compute -n doris --replicas=5

# 或者升级节点规格
kubectl patch statefulset doris-compute -n doris -p '{"spec":{"template":{"spec":{"containers":[{"name":"compute","resources":{"limits":{"cpu":"8","memory":"16Gi"}}}]}}}}'
```

## 对象存储问题

### 1. 无法连接对象存储

**症状**: BE日志显示连接对象存储失败

**排查步骤**:
```bash
# 查看BE日志
kubectl logs -n doris doris-compute-0 --tail=100 | grep -i "object_storage\|s3\|minio\|gcs"

# 测试网络连通性
kubectl exec -it doris-compute-0 -n doris -- nc -zv minio 9000

# 检查凭证配置
kubectl exec -it doris-compute-0 -n doris -- env | grep -i "object_storage\|minio"
```

**解决方案**:
```bash
# 如果使用MinIO，检查服务
kubectl get svc -n doris minio

# 如果使用GCS，检查Service Account
kubectl get secret -n doris gcs-credentials
```

### 2. 对象存储访问延迟高

**症状**: 查询延迟明显增加

**排查步骤**:
```bash
# 检查网络带宽
kubectl exec -it doris-compute-0 -n doris -- wget -O /dev/null http://minio:9000

# 检查缓存命中率
mysql -h doris-fe -P 9030 -uroot -p -e "SHOW PROC '/backends';" | grep -i cache
```

**解决方案**:
```sql
-- 增加本地缓存大小
ALTER SYSTEM SET BACKEND "compute_ip:9050" ("config" = ("cache_file_size" = "50"));

-- 预热缓存
INSERT INTO target_table SELECT * FROM source_table LIMIT 10000;
```

### 3. 写入速度慢

**症状**: 数据导入速度明显下降

**排查步骤**:
```bash
# 检查网络带宽
kubectl exec -it doris-compute-0 -n doris -- iperf3 -c minio

# 检查对象存储负载
# 登录MinIO Console查看
```

**解决方案**:
```sql
-- 调整写入并发
SET GLOBAL parallel_fragment_exec_instance_num = 8;

-- 调整batch size
SET GLOBAL batch_size = 16384;
```

## 网络问题

### 1. Pod间无法通信

**症状**: FE无法连接BE

**排查步骤**:
```bash
# 检查网络策略
kubectl get networkpolicy -n doris

# 测试DNS解析
kubectl exec -it doris-fe-0 -n doris -- nslookup doris-compute-0

# 测试端口连通性
kubectl exec -it doris-fe-0 -n doris -- nc -zv doris-compute-0 9050
```

**解决方案**:
```yaml
# 创建网络策略允许所有流量（测试环境）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all
  namespace: doris
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 2. Service DNS解析失败

**症状**: Pod无法通过Service名称访问其他Pod

**排查步骤**:
```bash
# 检查CoreDNS状态
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 测试DNS
kubectl exec -it doris-fe-0 -n doris -- nslookup kubernetes.default
```

**解决方案**:
```bash
# 重启CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

## 存储问题

### 1. PVC挂载失败

**症状**: Pod一直处于Pending状态

**排查步骤**:
```bash
# 查看PVC状态
kubectl get pvc -n doris

# 查看PV状态
kubectl get pv | grep doris

# 查看StorageClass
kubectl get storageclass
```

**解决方案**:
```bash
# 删除旧的PVC和PV
kubectl delete pvc -n doris --all
kubectl delete pv --all

# 重新创建
kubectl apply -f storage.yaml -n doris
```

### 2. 磁盘空间不足

**症状**: BE日志显示写入失败

**排查步骤**:
```bash
# 查看磁盘使用
kubectl exec -it doris-compute-0 -n doris -- df -h

# 清理旧数据
kubectl exec -it doris-compute-0 -n doris -- rm -rf /opt/apache-doris/be/storage/data/*
```

**解决方案**:
```sql
-- 清理冷数据
ALTER TABLE table_name DROP PARTITION partition_name;

-- 扩容存储
kubectl patch pvc doris-cloud-cache -n doris -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'
```

## 性能问题

### 1. 查询超时

**症状**: 查询经常报timeout错误

**排查步骤**:
```sql
-- 查看慢查询
SHOW FRONTEND CONFIG ("query_log_size");
SHOW VARIABLES LIKE '%timeout%';

-- 分析执行计划
EXPLAIN SELECT * FROM table_name WHERE condition;
```

**解决方案**:
```sql
-- 增加查询超时时间
SET GLOBAL query_timeout = 3600;

-- 增加执行内存
SET GLOBAL exec_mem_limit = 8589934592;
```

### 2. 缓存命中率低

**症状**: 相同查询每次都很慢

**排查步骤**:
```bash
# 查看缓存统计
kubectl exec -it doris-compute-0 -n doris -- mysql -h127.1 -P 9030 -uroot -p -e "SHOW PROC '/backends';"
```

**解决方案**:
```sql
-- 增加缓存大小
ALTER SYSTEM SET BACKEND "compute_ip:9050" ("config" = ("cache_file_size" = "100"));

-- 预热热点数据
INSERT INTO target_table SELECT * FROM source_table;
```

## 常见错误码

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| E1001 | BE节点不可用 | 检查BE进程状态和网络 |
| E1002 | 写入失败 | 检查对象存储连接 |
| E1003 | Tablet创建失败 | 检查磁盘空间 |
| E2001 | 查询超时 | 增加超时时间 |
| E2002 | 内存不足 | 增加节点内存 |
| E3001 | 认证失败 | 检查对象存储凭证 |
| E3002 | 网络不可达 | 检查网络策略 |

## 日志位置

| 组件 | 日志位置 | 说明 |
|------|----------|------|
| FE | /opt/apache-doris/fe/log/fe.log | FE主日志 |
| BE | /opt/apache-doris/be/log/be.INFO | BE信息日志 |
| BE | /opt/apache-doris/be/log/be.WARNING | BE警告日志 |
| BE | /opt/apache-doris/be/log/be.ERROR | BE错误日志 |

## 调试命令

```bash
# 查看FE状态
kubectl exec -it doris-fe-0 -n doris -- mysql -h127.1 -P 9030 -uroot -p -e "SHOW FRONTENDS;"

# 查看BE状态
kubectl exec -it doris-fe-0 -n doris -- mysql -h127.1 -P 9030 -uroot -p -e "SHOW BACKENDS;"

# 查看BE配置
kubectl exec -it doris-compute-0 -n doris -- mysql -h127.1 -P 9030 -uroot -p -e "SHOW BACKEND CONFIG;"

# 测试查询
kubectl exec -it doris-fe-0 -n doris -- mysql -h127.1 -P 9030 -uroot -p -e "SELECT 1;"

# 查看进程
kubectl exec -it doris-fe-0 -n doris -- ps aux | grep java

# 查看端口监听
kubectl exec -it doris-compute-0 -n doris -- netstat -tlnp

# 查看网络连接
kubectl exec -it doris-compute-0 -n doris -- netstat -tnp
```
