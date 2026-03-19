# PersistentVolume和PersistentVolumeClaim深度解析

## 6.1 PersistentVolume原理

### 6.1.1 PersistentVolume的核心概念

```
PersistentVolume的核心概念：

┌─────────────────────────────────────────────────────────────────┐
│  PersistentVolume是什么？                          │
└─────────────────────────────────────────────────────────────────┘

PersistentVolume（PV）是Kubernetes中用于存储资源的抽象：

1. 存储资源抽象
   ├── 抽象底层存储
   ├── 统一存储接口
   ├── 支持多种存储类型
   └── 支持多种存储驱动

2. 存储生命周期
   ├── 独立于Pod生命周期
   ├── 独立于节点生命周期
   ├── 支持数据持久化
   └── 支持数据迁移

3. 存储管理
   ├── 静态供应
   ├── 动态供应
   ├── 存储回收
   └── 存储扩容

4. 存储访问模式
   ├── ReadWriteOnce：单节点读写
   ├── ReadOnlyMany：多节点只读
   ├── ReadWriteMany：多节点读写
   └── ReadWriteOncePod：单Pod读写

PersistentVolume的优势：

1. 数据持久化
   ├── Pod删除数据不丢失
   ├── 节点故障数据不丢失
   ├── 集群重启数据不丢失
   └── 支持数据备份和恢复

2. 存储灵活性
   ├── 支持多种存储类型
   ├── 支持多种存储驱动
   ├── 支持多种存储协议
   └── 支持多种存储厂商

3. 存储管理
   ├── 自动化存储供应
   ├── 自动化存储回收
   ├── 自动化存储扩容
   └── 自动化存储备份

4. 存储隔离
   ├── 按Namespace隔离
   ├── 按应用隔离
   ├── 按环境隔离
   └── 按用户隔离
```

### 6.1.2 PersistentVolumeClaim原理

```
PersistentVolumeClaim原理：

┌─────────────────────────────────────────────────────────────────┐
│  PersistentVolumeClaim是什么？                  │
└─────────────────────────────────────────────────────────────────┘

PersistentVolumeClaim（PVC）是Kubernetes中用于请求存储资源的声明：

1. 存储请求
   ├── 请求存储容量
   ├── 请求访问模式
   ├── 请求存储类型
   └── 请求存储类

2. 存储绑定
   ├── 自动绑定PV
   ├── 手动绑定PV
   ├── 支持延迟绑定
   └── 支持绑定失败

3. 存储使用
   ├── 挂载到Pod
   ├── 作为存储卷
   ├── 支持读写
   └── 支持权限控制

4. 存储释放
   ├── 删除PVC
   ├── 释放PV
   ├── 回收存储
   └── 保留存储

PVC的优势：

1. 存储抽象
   ├── 用户无需关心底层存储
   ├── 用户只需声明存储需求
   ├── 系统自动匹配PV
   └── 简化存储管理

2. 存储隔离
   ├── 按Namespace隔离
   ├── 按应用隔离
   ├── 按环境隔离
   └── 按用户隔离

3. 存储灵活
   ├── 支持动态供应
   ├── 支持静态供应
   ├── 支持多种存储类型
   └── 支持多种访问模式

4. 存储安全
   ├── 支持权限控制
   ├── 支持加密存储
   ├── 支持访问控制
   └── 支持审计日志
```

### 6.1.3 StorageClass原理

```
StorageClass原理：

┌─────────────────────────────────────────────────────────────────┐
│  StorageClass是什么？                                 │
└─────────────────────────────────────────────────────────────────┘

StorageClass是Kubernetes中用于定义存储类的对象：

1. 存储类定义
   ├── 定义存储类型
   ├── 定义存储驱动
   ├── 定义存储参数
   └── 定义回收策略

2. 动态供应
   ├── 自动创建PV
   ├── 自动绑定PVC
   ├── 自动删除PV
   └── 自动回收存储

3. 存储参数
   ├── 存储驱动参数
   ├── 存储厂商参数
   ├── 存储性能参数
   └── 存储安全参数

4. 回收策略
   ├── Retain：保留存储
   ├── Delete：删除存储
   ├── Recycle：回收存储
   └── 自定义回收

StorageClass的优势：

1. 自动化存储供应
   ├── 自动创建PV
   ├── 自动绑定PVC
   ├── 自动删除PV
   └── 自动回收存储

2. 灵活的存储配置
   ├── 支持多种存储类型
   ├── 支持多种存储驱动
   ├── 支持多种存储参数
   └── 支持多种回收策略

3. 存储抽象
   ├── 用户无需关心底层存储
   ├── 用户只需选择存储类
   ├── 系统自动创建PV
   └── 简化存储管理

4. 存储优化
   ├── 支持存储分层
   ├── 支持存储压缩
   ├── 支持存储加密
   └── 支持存储备份
```

### 6.1.4 存储回收策略

```
存储回收策略：

┌─────────────────────────────────────────────────────────────────┐
│  存储回收策略                                    │
└─────────────────────────────────────────────────────────────────┘

1. Retain（保留）

特点：
├── 保留存储资源
├── 保留存储数据
├── 手动回收存储
└── 默认策略

工作流程：
├── PVC删除后PV状态变为Released
├── PV中的数据保留
├── PV不能被新PVC绑定
├── 需要手动删除PV
└── 需要手动回收存储

使用场景：
├── 重要数据
├── 需要保留数据
├── 需要手动管理
└── 需要审计数据

2. Delete（删除）

特点：
├── 删除存储资源
├── 删除存储数据
├── 自动回收存储
└── 动态供应默认

工作流程：
├── PVC删除后PV状态变为Released
├── 自动删除PV
├── 自动删除底层存储
├── 自动回收存储资源
└── 释放存储空间

使用场景：
├── 临时数据
├── 不需要保留数据
├── 自动管理
└── 节省存储空间

3. Recycle（回收）

特点：
├── 回收存储资源
├── 清空存储数据
├── 自动回收存储
└── 已废弃

工作流程：
├── PVC删除后PV状态变为Released
├── 自动清空存储数据
├── PV状态变为Available
├── PV可以被新PVC绑定
└── 自动回收存储

使用场景：
├── 临时数据
├── 不需要保留数据
├── 自动管理
└── 节省存储空间

注意：
├── 已废弃
├── 不推荐使用
├── 建议使用Delete
└── 建议使用Retain
```

---

## 6.2 PersistentVolume配置

### 6.2.1 本地存储PV配置

```yaml
# pv-local.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Local persistent volume"
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1
```

### 6.2.2 NFS存储PV配置

```yaml
# pv-nfs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "NFS persistent volume"
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-storage
  nfs:
    server: 192.168.1.100
    path: /export/data
```

### 6.2.3 AWS EBS存储PV配置

```yaml
# pv-aws-ebs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: aws-ebs-pv
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "AWS EBS persistent volume"
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: aws-ebs-storage
  awsElasticBlockStore:
    volumeID: vol-01234567890abcdef
    fsType: ext4
```

### 6.2.4 GCE PD存储PV配置

```yaml
# pv-gce-pd.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gce-pd-pv
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "GCE PD persistent volume"
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: gce-pd-storage
  gcePersistentDisk:
    pdName: my-disk
    fsType: ext4
```

---

## 6.3 PersistentVolumeClaim配置

### 6.3.1 PVC基本配置

```yaml
# pvc-basic.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application persistent volume claim"
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
  volumeMode: Filesystem
```

### 6.3.2 PVC动态供应配置

```yaml
# pvc-dynamic.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application persistent volume claim with dynamic provisioning"
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
  volumeMode: Filesystem
```

### 6.3.3 PVC只读配置

```yaml
# pvc-readonly.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application persistent volume claim with read-only access"
spec:
  accessModes:
  - ReadOnlyMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
  volumeMode: Filesystem
```

### 6.3.4 PVC块存储配置

```yaml
# pvc-block.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "Application persistent volume claim with block storage"
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd
  volumeMode: Block
```

---

## 6.4 StorageClass配置

### 6.4.1 本地存储StorageClass配置

```yaml
# storageclass-local.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
    description: "Local storage class"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
allowedTopologies:
- matchLabelExpressions:
  - key: kubernetes.io/hostname
    values:
    - node1
    - node2
    - node3
```

### 6.4.2 NFS存储StorageClass配置

```yaml
# storageclass-nfs.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-storage
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "NFS storage class"
provisioner: example.com/nfs
parameters:
  archiveOnDelete: "false"
reclaimPolicy: Retain
volumeBindingMode: Immediate
allowVolumeExpansion: true
mountOptions:
- hard
- nfsvers=4.1
```

### 6.4.3 AWS EBS存储StorageClass配置

```yaml
# storageclass-aws-ebs.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-ebs-storage
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "AWS EBS storage class"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
allowedTopologies:
- matchLabelExpressions:
  - key: topology.ebs.csi.aws.com/zone
    values:
    - us-west-1a
    - us-west-1b
```

### 6.4.4 GCE PD存储StorageClass配置

```yaml
# storageclass-gce-pd.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gce-pd-storage
  namespace: default
  labels:
    app: app
    environment: production
  annotations:
    description: "GCE PD storage class"
provisioner: pd.csi.storage.gke.io
parameters:
  type: pd-ssd
  fstype: ext4
  replication-type: regional-pd
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
allowedTopologies:
- matchLabelExpressions:
  - key: topology.gke.io/zone
    values:
    - us-central1-a
    - us-central1-b
```

---

## 6.5 PersistentVolume和PersistentVolumeClaim实战

### 6.5.1 创建PV和PVC

```bash
# 创建PV
kubectl apply -f pv-local.yaml

# 输出：
# persistentvolume/local-pv created

# 查看PV
kubectl get pv

# 输出：
# NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
# local-pv   10Gi       RWO            Retain           Available           local-storage             10s

# 创建PVC
kubectl apply -f pvc-basic.yaml

# 输出：
# persistentvolumeclaim/app-pvc created

# 查看PVC
kubectl get pvc

# 输出：
# NAME     STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# app-pvc  Bound    local-pv   10Gi       RWO            standard       10s

# 查看PV状态
kubectl get pv

# 输出：
# NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS    REASON   AGE
# local-pv   10Gi       RWO            Retain           Bound    default/app-pvc   local-storage            20s
```

### 6.5.2 使用PVC

```yaml
# pod-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
  namespace: default
  labels:
    app: pvc
    environment: production
spec:
  containers:
  - name: app
    image: nginx:1.25.0
    volumeMounts:
    - name: app-data
      mountPath: /data
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
  restartPolicy: Always
  volumes:
  - name: app-data
    persistentVolumeClaim:
      claimName: app-pvc
```

```bash
# 创建Pod
kubectl apply -f pod-pvc.yaml

# 输出：
# pod/pvc-pod created

# 查看Pod
kubectl get pods

# 输出：
# NAME      READY   STATUS    RESTARTS   AGE
# pvc-pod   1/1     Running   0          10s

# 进入Pod
kubectl exec -it pvc-pod -- /bin/bash

# 在Pod中写入数据
echo "Hello, World!" > /data/test.txt

# 退出Pod
exit

# 删除Pod
kubectl delete pod pvc-pod

# 输出：
# pod "pvc-pod" deleted

# 重新创建Pod
kubectl apply -f pod-pvc.yaml

# 输出：
# pod/pvc-pod created

# 进入Pod
kubectl exec -it pvc-pod -- /bin/bash

# 在Pod中读取数据
cat /data/test.txt

# 输出：
# Hello, World!

# 退出Pod
exit
```

### 6.5.3 动态供应

```bash
# 创建StorageClass
kubectl apply -f storageclass-aws-ebs.yaml

# 输出：
# storageclass.storage.k8s.io/aws-ebs-storage created

# 查看StorageClass
kubectl get storageclass

# 输出：
# NAME                PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
# aws-ebs-storage     ebs.csi.aws.com        Delete          WaitForFirstConsumer  true                   10s
# standard (default)  kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer  false                  5m

# 创建PVC
kubectl apply -f pvc-dynamic.yaml

# 输出：
# persistentvolumeclaim/app-pvc created

# 查看PVC
kubectl get pvc

# 输出：
# NAME     STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
# app-pvc  Pending   fast-ssd-pvc-01234567-89ab-cdef-0123-456789abcdef   0          RWO            fast-ssd          10s

# 等待PVC绑定
kubectl get pvc

# 输出：
# NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
# app-pvc  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            fast-ssd          30s

# 查看PV
kubectl get pv

# 输出：
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS     REASON   AGE
# pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            Delete           Bound    default/app-pvc   fast-ssd                 30s
```

### 6.5.4 扩容PVC

```bash
# 查看PVC
kubectl get pvc

# 输出：
# NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
# app-pvc  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            fast-ssd          1m

# 扩容PVC
kubectl patch pvc app-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# 输出：
# persistentvolumeclaim/app-pvc patched

# 查看PVC
kubectl get pvc

# 输出：
# NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
# app-pvc  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   20Gi       RWO            fast-ssd          2m

# 查看PV
kubectl get pv

# 输出：
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS     REASON   AGE
# pvc-01234567-89ab-cdef-0123-456789abcdef   20Gi       RWO            Delete           Bound    default/app-pvc   fast-ssd                 2m
```

### 6.5.5 删除PVC和PV

```bash
# 删除PVC
kubectl delete pvc app-pvc

# 输出：
# persistentvolumeclaim "app-pvc" deleted

# 查看PVC
kubectl get pvc

# 输出：
# No resources found in default namespace.

# 查看PV（回收策略为Delete）
kubectl get pv

# 输出：
# No resources found.

# 查看PV（回收策略为Retain）
kubectl get pv

# 输出：
# NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM            STORAGECLASS    REASON   AGE
# local-pv   10Gi       RWO            Retain           Released    default/app-pvc   local-storage            5m

# 手动删除PV
kubectl delete pv local-pv

# 输出：
# persistentvolume "local-pv" deleted

# 查看PV
kubectl get pv

# 输出：
# No resources found.
```

---

## 本章小结

- PersistentVolume（PV）是Kubernetes中用于存储资源的抽象
- PV独立于Pod和节点生命周期，支持数据持久化
- PersistentVolumeClaim（PVC）是Kubernetes中用于请求存储资源的声明
- PVC自动绑定PV，支持动态供应和静态供应
- StorageClass定义存储类，支持动态供应
- PV访问模式包括ReadWriteOnce、ReadOnlyMany、ReadWriteMany、ReadWriteOncePod
- 存储回收策略包括Retain、Delete、Recycle
- Retain策略保留存储资源，需要手动回收
- Delete策略删除存储资源，自动回收
- Recycle策略回收存储资源，已废弃
- 可以使用kubectl创建、查看、扩容、删除PV和PVC
- 可以使用kubectl describe查看PV和PVC详细信息

---

**下一章：StatefulSet和DaemonSet**
