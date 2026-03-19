# Kubernetes专家之路：从原理到实战

## 本章导学

**这不是一本入门手册。**

市面上99%的Kubernetes教程都在告诉你"怎么用"——写什么命令、输什么参数。但如果你不知道"为什么"，你永远只能照猫画虎，遇到实际问题就束手无策。

**学完本章后，你将能够：**

- 从**底层原理**理解Kubernetes的架构设计
- 从**控制平面**理解集群管理机制
- 从**数据平面**理解Pod调度和运行
- 从**存储系统**理解etcd的数据一致性
- 从**调度算法**理解资源分配策略
- 从**网络模型**理解Pod间通信

**学习方法：**

每一节都会按照这个结构展开：
```
原理 → 架构 → 协议细节 → 实际代码 → 验证 → 常见误区
```

让我们开始。

---

# 第一部分：Kubernetes核心原理

## 1.1 Kubernetes为什么需要容器编排？

当你运行`kubectl create deployment`时，Kubernetes如何管理成千上万的容器？如何保证高可用？如何实现自动扩缩容？

### 1.1.1 容器编排的本质

```
容器编排解决的问题：

┌─────────────────────────────────────────────────────────────────┐
│  问题：手动管理容器的挑战                             │
└─────────────────────────────────────────────────────────────────┘

手动管理容器的挑战：

1. 容器生命周期管理
   ├── 需要手动创建和删除容器
   ├── 需要手动监控容器状态
   ├── 需要手动重启失败的容器
   └── 需要手动管理容器更新

2. 资源调度
   ├── 需要手动选择运行节点
   ├── 需要手动考虑资源限制
   ├── 需要手动处理资源不足
   └── 需要手动优化资源利用

3. 服务发现
   ├── 需要手动配置容器间通信
   ├── 需要手动处理容器IP变化
   ├── 需要手动配置负载均衡
   └── 需要手动处理服务故障

4. 存储管理
   ├── 需要手动挂载存储卷
   ├── 需要手动处理存储故障
   ├── 需要手动备份和恢复数据
   └── 需要手动管理存储容量

5. 配置管理
   ├── 需要手动注入配置
   ├── 需要手动管理敏感数据
   ├── 需要手动更新配置
   └── 需要手动处理配置错误

6. 自动扩缩容
   ├── 需要手动监控负载
   ├── 需要手动增加容器数量
   ├── 需要手动减少容器数量
   └── 需要手动处理扩缩容失败

┌─────────────────────────────────────────────────────────────────┐
│  解决方案：Kubernetes容器编排                           │
└─────────────────────────────────────────────────────────────────┘

Kubernetes提供的功能：

1. 自动化部署和回滚
   ├── 自动部署应用
   ├── 自动滚动更新
   ├── 自动回滚失败更新
   └── 支持多种更新策略

2. 自动扩缩容
   ├── 基于CPU使用率自动扩容
   ├── 基于内存使用率自动扩容
   ├── 基于自定义指标自动扩容
   └── 支持手动和自动扩缩容

3. 服务发现和负载均衡
   ├── 自动分配Pod IP
   ├── 自动创建Service
   ├── 自动负载均衡流量
   └── 支持多种服务类型

4. 存储编排
   ├── 自动挂载存储卷
   ├── 自动处理存储故障
   ├── 支持多种存储类型
   └── 支持动态供应

5. 自我修复
   ├── 自动重启失败的容器
   ├── 自动替换不健康的节点
   ├── 自动重新调度失败的Pod
   └── 支持多种健康检查

6. 配置和密钥管理
   ├── 自动注入配置
   ├── 自动管理敏感数据
   ├── 支持配置热更新
   └── 支持多种配置方式
```

### 1.1.2 Kubernetes架构原理

```
Kubernetes架构：

┌─────────────────────────────────────────────────────────────────┐
│  Kubernetes架构图                                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  控制平面（Control Plane）                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ API Server (kube-apiserver)                    │    │
│  │  ├── RESTful API接口                            │    │
│  │  ├── 认证和授权                                │    │
│  │  ├── 准入控制                                   │    │
│  │  └── 数据验证                                   │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ etcd (分布式键值存储)                         │    │
│  │  ├── 集群状态存储                              │    │
│  │  ├── 配置数据存储                              │    │
│  │  ├── Raft一致性协议                            │    │
│  │  └── 数据备份和恢复                            │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Scheduler (kube-scheduler)                      │    │
│  │  ├── Pod调度                                   │    │
│  │  ├── 资源分配                                 │    │
│  │  ├── 亲和性和反亲和性                           │    │
│  │  └── 优先级和抢占                              │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Controller Manager (kube-controller-manager)       │    │
│  │  ├── Node Controller                           │    │
│  │  ├── Replication Controller                     │    │
│  │  ├── Endpoints Controller                       │    │
│  │  ├── Service Account & Token Controller          │    │
│  │  └── Namespace Controller                       │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Cloud Controller Manager (cloud-controller-manager) │    │
│  │  ├── Node Controller                           │    │
│  │  ├── Route Controller                          │    │
│  │  ├── Service Controller                         │    │
│  │  └── Volume Controller                         │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│  数据平面（Data Plane）                                 │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Kubelet (节点代理)                              │    │
│  │  ├── Pod生命周期管理                            │    │
│  │  ├── 容器运行时接口（CRI）                    │    │
│  │  ├── 健康检查                                  │    │
│  │  └── 资源监控                                  │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Kube-proxy (网络代理)                           │    │
│  │  ├── Service负载均衡                            │    │
│  │  ├── 网络规则管理                              │    │
│  │  ├── iptables/IPVS模式                          │    │
│  │  └── 网络策略执行                              │    │
│  └──────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Container Runtime (容器运行时)                   │    │
│  │  ├── Docker                                    │    │
│  │  ├── containerd                                │    │
│  │  ├── CRI-O                                     │    │
│  │  └── 其他CRI兼容运行时                          │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1.3 控制平面组件详解

#### API Server

```
API Server原理：

┌─────────────────────────────────────────────────────────────────┐
│  API Server工作原理                                    │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. RESTful API接口
   ├── 提供标准的RESTful API
   ├── 支持JSON/YAML格式
   ├── 支持Watch机制
   └── 支持批量操作

2. 认证和授权
   ├── 支持多种认证方式（证书、Token、OIDC等）
   ├── 支持RBAC授权
   ├── 支持ABAC授权
   └── 支持Node授权

3. 准入控制
   ├── 验证资源配置
   ├── 修改资源配置
   ├── 自定义准入控制
   └── 支持动态配置

4. 数据验证
   ├── 验证资源定义
   ├── 验证资源关系
   ├── 验证资源状态
   └── 验证资源权限

工作流程：

1. 接收请求
   ├── 接收HTTP请求
   ├── 解析请求内容
   ├── 验证请求格式
   └── 提取请求参数

2. 认证
   ├── 验证客户端身份
   ├── 支持多种认证方式
   ├── 生成用户信息
   └── 传递给授权模块

3. 授权
   ├── 验证用户权限
   ├── 检查RBAC规则
   ├── 检查ABAC规则
   └── 决定是否允许访问

4. 准入控制
   ├── 验证资源配置
   ├── 修改资源配置
   ├── 执行自定义逻辑
   └── 决定是否允许创建

5. 数据存储
   ├── 将资源数据写入etcd
   ├── 更新资源状态
   ├── 触发事件通知
   └── 返回操作结果
```

#### etcd

```
etcd原理：

┌─────────────────────────────────────────────────────────────────┐
│  etcd分布式键值存储原理                              │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. 分布式存储
   ├── 分布式键值存储
   ├── 强一致性保证
   ├── 高可用性
   └── 水平扩展

2. Raft一致性协议
   ├── Leader选举
   ├── 日志复制
   ├── 一致性保证
   └── 故障恢复

3. 数据备份和恢复
   ├── 快照备份
   ├── 增量备份
   ├── 数据恢复
   └── 灾难恢复

4. Watch机制
   ├── 实时监控数据变化
   ├── 事件通知
   ├── 历史版本
   └── 过滤条件

数据结构：

1. 集群状态
   ├── Node信息
   ├── Pod信息
   ├── Service信息
   └── 其他资源信息

2. 配置数据
   ├── ConfigMap
   ├── Secret
   ├── Deployment配置
   └── 其他配置数据

3. 元数据
   ├── 资源版本
   ├── 资源注解
   ├── 资源标签
   └── 其他元数据

Raft一致性协议：

1. Leader选举
   ├── 节点启动时选举Leader
   ├── Leader处理所有写请求
   ├── Follower复制Leader的日志
   └── Leader故障时重新选举

2. 日志复制
   ├── Leader接收写请求
   ├── Leader将日志追加到本地
   ├── Leader将日志复制到Follower
   ├── Follower确认日志复制
   └── Leader提交日志

3. 一致性保证
   ├── 强一致性
   ├── 线性一致性
   ├── 读写一致性
   └── 会话一致性
```

#### Scheduler

```
Scheduler原理：

┌─────────────────────────────────────────────────────────────────┐
│  Scheduler调度原理                                    │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. Pod调度
   ├── 为Pod选择合适的节点
   ├── 考虑资源需求
   ├── 考虑约束条件
   └── 优化资源利用

2. 资源分配
   ├── CPU资源分配
   ├── 内存资源分配
   ├── 存储资源分配
   └── 网络资源分配

3. 亲和性和反亲和性
   ├── 节点亲和性
   ├── Pod亲和性
   ├── Pod反亲和性
   └── 拓扑分布约束

4. 优先级和抢占
   ├── Pod优先级
   ├── 抢占机制
   ├── 资源预留
   └── QoS保证

调度流程：

1. 监听未调度的Pod
   ├── 通过Informer监听Pod事件
   ├── 过滤未调度的Pod
   ├── 加入调度队列
   └── 按优先级排序

2. 过滤节点
   ├── 检查节点资源是否满足
   ├── 检查节点标签是否匹配
   ├── 检查节点污点是否容忍
   └── 检查其他约束条件

3. 打分节点
   ├── 计算资源利用率
   ├── 计算亲和性得分
   ├── 计算反亲和性得分
   └── 计算其他策略得分

4. 选择节点
   ├── 选择得分最高的节点
   ├── 处理得分相同的情况
   ├── 考虑随机性
   └── 绑定Pod到节点

5. 更新状态
   ├── 更新Pod的调度状态
   ├── 更新节点的资源使用
   ├── 触发Kubelet创建Pod
   └── 记录调度日志

调度算法：

1. 资源请求和限制
   ├── Request：Pod请求的最小资源
   ├── Limit：Pod允许的最大资源
   ├── QoS：服务质量等级
   └── 资源超卖策略

2. 亲和性和反亲和性
   ├── Node Affinity：Pod对节点的偏好
   ├── Pod Affinity：Pod对其他Pod的偏好
   ├── Pod Anti-Affinity：Pod对其他Pod的排斥
   └── Taints and Tolerations：节点的污点和Pod的容忍

3. 优先级和抢占
   ├── PriorityClass：Pod的优先级类
   ├── Preemption：高优先级Pod抢占低优先级Pod
   ├── System Priority：系统Pod的优先级
   └── Default Priority：默认优先级
```

#### Controller Manager

```
Controller Manager原理：

┌─────────────────────────────────────────────────────────────────┐
│  Controller Manager工作原理                             │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. Node Controller
   ├── 监控节点状态
   ├── 处理节点故障
   ├── 标记不可用节点
   └── 驱逐节点上的Pod

2. Replication Controller
   ├── 监控ReplicaSet状态
   ├── 确保Pod副本数
   ├── 创建缺失的Pod
   └── 删除多余的Pod

3. Endpoints Controller
   ├── 监控Service和Pod
   ├── 更新Service的Endpoints
   ├── 维护Pod IP列表
   └── 处理Pod变化

4. Service Account & Token Controller
   ├── 创建Service Account
   ├── 生成Token
   ├── 更新Secret
   └── 管理访问凭证

5. Namespace Controller
   ├── 监控Namespace
   ├── 删除Namespace中的资源
   ├── 清理最终状态
   └── 处理删除失败

工作模式：

1. 控制循环
   ├── 监听资源变化
   ├── 对比期望状态和实际状态
   ├── 执行调整操作
   └── 持续运行

2. 事件驱动
   ├── 通过Informer监听事件
   ├── 处理资源变化事件
   ├── 触发控制循环
   └── 执行相应操作

3. 最终一致性
   ├── 不保证立即达到期望状态
   ├── 持续调整直到达到期望状态
   ├── 处理并发修改
   └── 保证最终一致性
```

### 1.1.4 数据平面组件详解

#### Kubelet

```
Kubelet原理：

┌─────────────────────────────────────────────────────────────────┐
│  Kubelet工作原理                                       │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. Pod生命周期管理
   ├── 接收Pod创建请求
   ├── 调用容器运行时创建容器
   ├── 监控容器状态
   └── 报告Pod状态

2. 容器运行时接口（CRI）
   ├── 支持多种容器运行时
   ├── 标准化容器操作
   ├── 支持容器镜像拉取
   └── 支持容器资源管理

3. 健康检查
   ├── Liveness Probe
   ├── Readiness Probe
   ├── Startup Probe
   └── 处理健康检查失败

4. 资源监控
   ├── 监控CPU使用率
   ├── 监控内存使用率
   ├── 监控磁盘使用率
   └── 监控网络使用率

工作流程：

1. 接收Pod配置
   ├── 从API Server获取Pod配置
   ├── 解析Pod配置
   ├── 验证Pod配置
   └── 准备创建Pod

2. 创建Pod
   ├── 创建Pod的目录结构
   ├── 拉取容器镜像
   ├── 创建容器运行时配置
   ├── 调用CRI创建容器
   └── 启动容器

3. 监控Pod
   ├── 监控容器状态
   ├── 执行健康检查
   ├── 收集资源使用情况
   └── 报告Pod状态

4. 更新Pod
   ├── 接收Pod更新请求
   ├── 对比新旧配置
   ├── 执行滚动更新
   └── 报告更新状态

5. 删除Pod
   ├── 接收Pod删除请求
   ├── 停止容器
   ├── 清理容器资源
   └── 报告删除状态
```

#### Kube-proxy

```
Kube-proxy原理：

┌─────────────────────────────────────────────────────────────────┐
│  Kube-proxy工作原理                                     │
└─────────────────────────────────────────────────────────────────┘

核心功能：

1. Service负载均衡
   ├── 监控Service和Endpoints
   ├── 更新负载均衡规则
   ├── 分发流量到Pod
   └── 支持多种负载均衡算法

2. 网络规则管理
   ├── 管理iptables规则
   ├── 管理IPVS规则
   ├── 管理nftables规则
   └── 支持多种网络模式

3. 网络策略执行
   ├── 监控NetworkPolicy
   ├── 应用网络规则
   ├── 控制Pod间通信
   └── 执行安全策略

工作模式：

1. iptables模式
   ├── 使用iptables实现负载均衡
   ├── 随机选择Pod
   ├── 性能一般
   └── 适合小规模集群

2. IPVS模式
   ├── 使用IPVS实现负载均衡
   ├── 支持多种负载均衡算法
   ├── 性能较好
   └── 适合大规模集群

3. nftables模式
   ├── 使用nftables实现负载均衡
   ├── 支持更复杂的规则
   ├── 性能较好
   └── 适合复杂网络场景

负载均衡算法：

1. 随机（Random）
   ├── 随机选择Pod
   ├── 简单高效
   ├── 适合无状态应用
   └── iptables模式默认

2. 轮询（Round Robin）
   ├── 依次选择Pod
   ├── 负载均衡
   ├── 适合无状态应用
   └── IPVS模式默认

3. 最少连接（Least Connection）
   ├── 选择连接数最少的Pod
   ├── 动态负载均衡
   ├── 适合长连接应用
   └── IPVS模式支持

4. 源地址哈希（Source Hashing）
   ├── 根据源地址选择Pod
   ├── 会话保持
   ├── 适合有状态应用
   └── IPVS模式支持
```

---

## 1.2 Kubernetes实战：搭建集群

### 1.2.1 使用Minikube搭建本地集群

```bash
# 安装Minikube
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Windows
# 从 https://minikube.sigs.k8s.io/docs/start/ 下载安装程序

# 启动Minikube集群
minikube start

# 输出：
# 😄  minikube v1.30.1 on Darwin 13.4.0 (arm64)
# ✨  Automatically selected the docker driver. Other choices: hyperkit, vmwarefusion, virtualbox
# 👍  Starting control plane node minikube in cluster minikube
# 🚜  Pulling base image ...
# 🔄  Restarting existing docker container for "minikube" ...
# 🐳  Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
#     ▪ Generating certificates and keys ...
#     ▪ Booting up control plane ...
#     ▪ Configuring RBAC rules ...
# 🔎  Verifying Kubernetes components...
#     ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
# 🔌  Enabling addons: default-storageclass, storage-provisioner
# 🏄  Done! kubectl is now configured to use "minikube" cluster with "docker" driver by default

# 验证集群状态
kubectl cluster-info

# 输出：
# Kubernetes control plane is running at https://127.0.0.1:6443
# CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# 查看节点
kubectl get nodes

# 输出：
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   5m    v1.26.3

# 查看Pod
kubectl get pods --all-namespaces

# 输出：
# NAMESPACE     NAME                               READY   STATUS    RESTARTS   AGE
# kube-system   coredns-787d4945fb-7j8kx          1/1     Running   0          5m
# kube-system   etcd-minikube                       1/1     Running   0          5m
# kube-system   kube-apiserver-minikube            1/1     Running   0          5m
# kube-system   kube-controller-manager-minikube   1/1     Running   0          5m
# kube-system   kube-proxy-7v9xh                   1/1     Running   0          5m
# kube-system   kube-scheduler-minikube            1/1     Running   0          5m
# kube-system   storage-provisioner                1/1     Running   0          5m

# 查看集群信息
kubectl cluster-info dump

# 输出：
# Dumping cluster information to /tmp/cluster-info-20240115-103000
```

### 1.2.2 使用kubeadm搭建生产集群

```bash
# 在所有节点上安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 在所有节点上安装kubeadm、kubelet、kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 启动kubelet
sudo systemctl enable --now kubelet

# 在Master节点上初始化集群
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# 输出：
# [init] Using Kubernetes version: v1.26.3
# [preflight] Running pre-flight checks
# [preflight] Pulling images required for setting up a Kubernetes cluster
# [preflight] This might take a minute or two, depending on the speed of your internet connection
# [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
# [certs] Using certificateDir folder "/etc/kubernetes/pki"
# [certs] Generating "ca" certificate and key
# [certs] Generating "apiserver" certificate and key
# [certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local localhost] and IPs [10.96.0.1 192.168.1.100]
# [certs] Generating "apiserver-kubelet-client" certificate and key
# [certs] Generating "front-proxy-ca" certificate and key
# [certs] Generating "front-proxy-client" certificate and key
# [certs] Generating "etcd/ca" certificate and key
# [certs] Generating "etcd/server" certificate and key
# [certs] etcd/server serving cert is signed for DNS names [localhost] and IPs [192.168.1.100 127.0.0.1 ::1]
# [certs] Generating "etcd/peer" certificate and key
# [certs] etcd/peer serving cert is signed for DNS names [localhost] and IPs [192.168.1.100 127.0.0.1 ::1]
# [certs] Generating "etcd/healthcheck-client" certificate and key
# [certs] Generating "apiserver-etcd-client" certificate and key
# [certs] Generating "sa" key and public key
# [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
# [kubeconfig] Writing "admin.conf" kubeconfig file
# [kubeconfig] Writing "kubelet.conf" kubeconfig file
# [kubeconfig] Writing "controller-manager.conf" kubeconfig file
# [kubeconfig] Writing "scheduler.conf" kubeconfig file
# [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
# [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
# [kubelet-start] Starting the kubelet
# [control-plane] Using manifest folder "/etc/kubernetes/manifests"
# [control-plane] Creating static Pod manifest for "kube-apiserver"
# [control-plane] Creating static Pod manifest for "kube-controller-manager"
# [control-plane] Creating static Pod manifest for "kube-scheduler"
# [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
# [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
# [apiclient] All control plane components are healthy after 15.001538 seconds
# [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
# [kubelet] Creating a ConfigMap "kubelet" in namespace kube-system with the configuration for the kubelets in the cluster
# [upload-certs] Skipping phase upload-certs as no certificates are provided
# [mark-control-plane] Marking the node master as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
# [mark-control-plane] Marking the node master as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
# [bootstrap-token] Using token: abcdef.01234567890abcdef
# [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Rules
# [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
# [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
# [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
# [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
# [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
# [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
# [addons] Applied essential addon: CoreDNS
# [addons] Applied essential addon: kube-proxy

# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.1.100:6443 --token abcdef.01234567890abcdef \
#  --discovery-token-ca-cert-hash sha256:01234567890abcdef01234567890abcdef01234567890abcdef01234567890abcdef

# 配置kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装Pod网络插件（以Calico为例）
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 输出：
# configmap/calico-config created
# customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/calicoapiservers.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
# customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
# ...

# 在Worker节点上加入集群
sudo kubeadm join 192.168.1.100:6443 --token abcdef.01234567890abcdef \
  --discovery-token-ca-cert-hash sha256:01234567890abcdef01234567890abcdef01234567890abcdef01234567890abcdef

# 输出：
# [preflight] Running pre-flight checks
# [preflight] Reading configuration from the cluster...
# [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
# [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
# [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
# [kubelet-start] Starting the kubelet
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.

# 在Master节点上查看节点
kubectl get nodes

# 输出：
# NAME     STATUS   ROLES           AGE   VERSION
# master    Ready    control-plane   10m   v1.26.3
# worker1   Ready    <none>          5m    v1.26.3
# worker2   Ready    <none>          5m    v1.26.3
```

### 1.2.3 集群验证

```bash
# 查看集群信息
kubectl cluster-info

# 输出：
# Kubernetes control plane is running at https://192.168.1.100:6443
# CoreDNS is running at https://192.168.1.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# 查看节点
kubectl get nodes -o wide

# 输出：
# NAME     STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
# master    Ready    control-plane   10m   v1.26.3   192.168.1.100  <none>        Ubuntu 22.04.2 LTS   5.15.0-72-generic   docker://23.0.2
# worker1   Ready    <none>          5m    v1.26.3   192.168.1.101  <none>        Ubuntu 22.04.2 LTS   5.15.0-72-generic   docker://23.0.2
# worker2   Ready    <none>          5m    v1.26.3   192.168.1.102  <none>        Ubuntu 22.04.2 LTS   5.15.0-72-generic   docker://23.0.2

# 查看命名空间
kubectl get namespaces

# 输出：
# NAME              STATUS   AGE
# default           Active   10m
# kube-node-lease   Active   10m
# kube-public       Active   10m
# kube-system       Active   10m

# 查看Pod
kubectl get pods --all-namespaces

# 输出：
# NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
# kube-system   calico-kube-controllers-5d6d4d7b6b-7j8kx      1/1     Running   0          5m
# kube-system   calico-node-7v9xh                           1/1     Running   0          5m
# kube-system   calico-node-8k0l2                           1/1     Running   0          5m
# kube-system   calico-node-9m3n4                           1/1     Running   0          5m
# kube-system   coredns-787d4945fb-7j8kx                  1/1     Running   0          10m
# kube-system   coredns-787d4945fb-9k0l2                  1/1     Running   0          10m
# kube-system   etcd-master                                  1/1     Running   0          10m
# kube-system   kube-apiserver-master                       1/1     Running   0          10m
# kube-system   kube-controller-manager-master              1/1     Running   0          10m
# kube-system   kube-proxy-7v9xh                            1/1     Running   0          5m
# kube-system   kube-proxy-8k0l2                            1/1     Running   0          5m
# kube-system   kube-proxy-9m3n4                            1/1     Running   0          5m
# kube-system   kube-scheduler-master                       1/1     Running   0          10m

# 查看Service
kubectl get services --all-namespaces

# 输出：
# NAMESPACE     NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
# default       kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP                  10m
# kube-system   kube-dns     ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   10m

# 查看集群事件
kubectl get events --all-namespaces

# 输出：
# LAST SEEN   TYPE      REASON              OBJECT                      MESSAGE
# 5m          Normal    Scheduled           pod/coredns-787d4945fb-7j8kx   Successfully assigned default/coredns-787d4945fb-7j8kx to master
# 5m          Normal    Pulling             pod/coredns-787d4945fb-7j8kx   Pulling image "registry.k8s.io/coredns/coredns:v1.9.3"
# 4m          Normal    Pulled              pod/coredns-787d4945fb-7j8kx   Successfully pulled image "registry.k8s.io/coredns/coredns:v1.9.3" in 15.001538s
# 4m          Normal    Created             pod/coredns-787d4945fb-7j8kx   Created container coredns
# 4m          Normal    Started             pod/coredns-787d4945fb-7j8kx   Started container coredns
# ...
```

---

## 本章小结

- Kubernetes是容器编排平台，解决容器管理、调度、服务发现等问题
- Kubernetes架构分为控制平面和数据平面
- 控制平面包括API Server、etcd、Scheduler、Controller Manager
- 数据平面包括Kubelet、Kube-proxy、Container Runtime
- API Server提供RESTful API接口，处理认证、授权、准入控制
- etcd是分布式键值存储，使用Raft协议保证一致性
- Scheduler负责Pod调度，考虑资源、亲和性、优先级等因素
- Controller Manager负责维护集群状态，包括Node、ReplicaSet、Endpoints等控制器
- Kubelet是节点代理，负责Pod生命周期管理
- Kube-proxy是网络代理，负责Service负载均衡
- 可以使用Minikube搭建本地集群，使用kubeadm搭建生产集群

---

**下一章：Pod管理**
