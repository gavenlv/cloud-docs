# Kubernetes Operator 深度解析

## 1. Operator 的本质

### 1.1 从控制理论看 Operator

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator 的本质 = 控制论中的反馈控制系统                          │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   参考输入    │  (Desired State / Spec)
                    │  期望状态     │
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────┐
              │      比较器 (Compare)    │  ← Reconcile 核心逻辑
              │                        │
              │  error = desired - actual │
              └───────────┬────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             ▼             │
            │  ┌─────────────────┐     │
            │  │   控制器/执行器   │     │  ← 调用 K8s API 执行操作
            │  │  (Controller)   │     │     创建 Pod、Service 等
            │  └────────┬────────┘     │
            │           │              │
            │           ▼              │
            │  ┌─────────────────┐     │
            │  │  受控系统 (Plant) │     │  ← Kubernetes 集群
            │  │  Pods, PVC, ...  │     │     实际运行的状态
            │  └────────┬────────┘     │
            │           │              │
            │           ▼              │
            │  ┌─────────────────┐     │
            │  │   传感器 (Sense)  │     │  ← Informer / Watcher
            │  │  读取实际状态     │     │     监听资源变化事件
            │  └────────┬────────┘     │
            │           │              │
            └───────────┴──────────────┘
                          │
                   实际输出 (Actual State / Status)
                          │
                          └──→ 反馈回比较器

关键洞察：
- Operator 不是"脚本"，而是一个**持续运行的闭环控制系统**
- 它不关心"怎么做一次"，而是**持续保证状态正确**
- 这就是为什么叫 Reconcile（协调）而不是 Execute（执行）
```

### 1.2 为什么需要 Operator

```
┌─────────────────────────────────────────────────────────────────┐
│  问题：Kubernetes 原生能管理什么？                                │
└─────────────────────────────────────────────────────────────────┘

Kubernetes 内置控制器管理的都是**无状态或简单有状态**的资源：

┌──────────────────┬────────────────┬────────────────────────────┐
│     资源类型       │   状态复杂度     │        管理能力             │
├──────────────────┼────────────────┼────────────────────────────┤
│ Deployment       │ 无状态          │ ✅ 副本数、滚动更新、回滚     │
│ ReplicaSet       │ 无状态          │ ✅ Pod副本管理               │
│ StatefulSet      │ 有序标识         │ ⚠️ 有序部署，但不理解应用语义  │
│ DaemonSet        │ 无状态          │ ✅ 每节点一个Pod             │
│ Job/CronJob      │ 任务型          │ ✅ 一次性/定时任务            │
└──────────────────┴────────────────┴────────────────────────────┘

问题来了：PostgreSQL 怎么办？

┌─────────────────────────────────────────────────────────────────┐
│  PostgreSQL 在 K8s 中运行的挑战                                  │
└─────────────────────────────────────────────────────────────────┘

StatefulSet 能做的：
  ✅ 给每个 Pod 固定名称（pg-0, pg-1, pg-2）
  ✅ 有序启动和停止
  ✅ 稳定的网络标识符
  ✅ 绑定 PV（持久化存储）

StatefulSet **做不到**的：
  ❌ 不知道谁是 Primary，谁是 Replica
  ❌ 不知道如何做主从切换（Failover）
  ❌ 不知道如何初始化数据库集群
  ❌ 不知道如何做备份和恢复
  ❌ 不知道如何做流复制配置
  ❌ 不知道何时该扩容、何时不能扩容
  ❌ 不知道如何安全地升级版本

这些都需要 **领域知识（Domain Knowledge）**

┌─────────────────────────────────────────────────────────────────┐
│  Operator = 控制循环 + 领域知识                                   │
└─────────────────────────────────────────────────────────────────┘

Kubernetes 提供了：
  - 控制循环框架（controller-runtime）
  - API扩展机制（CRD）
  - 事件驱动架构（Informer/Watcher）

Operator 开发者提供的是：
  - 领域知识（PostgreSQL的主从复制怎么配？备份怎么做？）
  - 业务逻辑（什么时候该 Failover？怎么判断主库挂了？）

两者结合 → 自动化的应用生命周期管理
```

### 1.3 Operator 解决的核心问题

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator 解决的四大核心问题                                      │
└─────────────────────────────────────────────────────────────────┘

问题1: 应用部署不是一次性的事
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  传统方式:  kubectl apply → 结束                                 │
│                                                                  │
│  Operator:  kubectl apply → 持续监控 → 自动修复                  │
│                                                                  │
│  场景:                                                           │
│  - Pod被删除了 → 自动重建                                        │
│  - 配置变了 → 自动滚动更新                                       │
│  - 存储满了 → 自动告警并处理                                     │
│  - 主节点挂了 → 自动故障转移                                     │
└─────────────────────────────────────────────────────────────────┘

问题2: 运维知识应该代码化
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  传统方式: SOP文档 → 人工执行 → 容易出错                         │
│                                                                  │
│  Operator: 运维经验 → 写成代码 → 自动执行                       │
│                                                                  │
│  例如 PostgreSQL 主从切换的SOP:                                   │
│  1. 检测主库是否真的挂了（不是网络抖动）                          │
│  2. 选择最新的备库作为新主库                                      │
│  3. 将新主库提升为可写                                            │
│  4. 将其他备库重新指向新主库                                      │
│  5. 更新 Service/Endpoint 指向新主库                              │
│  6. 通知应用层连接信息变更                                       │
│                                                                  │
│  这些步骤全部编码到 Operator 的 Reconcile 循环中                  │
└─────────────────────────────────────────────────────────────────┘

问题3: 声明式 API 降低使用门槛
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  用户只需要说"我要什么"，不需要说"怎么做"                         │
│                                                                  │
│  apiVersion: postgresql.k8s.enterprisedb.io/v1                  │
│  kind: Cluster                                                   │
│  spec:                                                           │
│    instances: 3                                                  │
│    postgresqlVersion: "16"                                       │
│    storage:                                                       │
│      size: 100Gi                                                 │
│    highAvailability:                                             │
│      enabled: true                                               │
│    backup:                                                        │
│      enabled: true                                               │
│      schedule: "0 2 * * *"                                      │
│                                                                  │
│  用户不需要知道：                                                  │
│  - 如何配置 Patroni                                              │
│  - 如何设置流复制                                                │
│  - 如何配置 PgBouncer                                           │
│  - 如何做 PITR 备份                                              │
└─────────────────────────────────────────────────────────────────┘

问题4: 一致性保证
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Level Triggered vs Edge Triggered                               │
│                                                                  │
│  Edge Triggered（边缘触发）= 事件驱动                             │
│  - "Pod创建了" → 执行一次                                        │
│  - 问题：如果执行失败怎么办？漏掉了怎么办？                       │
│                                                                  │
│  Level Triggered（电平触发）= 状态驱动                            │
│  - "当前状态 ≠ 期望状态" → 执行修正                              │
│  - 无论中间发生了什么，最终都会达到一致                           │
│  - 这是 Kubernetes 控制器的核心设计哲学                           │
│                                                                  │
│  Operator 遵循同样的哲学                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Operator 工作原理深度剖析

### 2.1 Reconcile 循环详解

```
┌─────────────────────────────────────────────────────────────────┐
│  一次完整的 Reconcile 循环（以 PostgreSQL 为例）                  │
└─────────────────────────────────────────────────────────────────┘

用户创建 CR:
  apiVersion: pg.example.com/v1
  kind: PostgresCluster
  name: my-postgres
  spec:
    instances: 3

                    ┌──────────────────────────────┐
                    │     Reconcile 开始            │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Step 1: 获取 CR 对象         │
                    │  读取 my-postgres 的 Spec      │
                    │  desiredInstances = 3         │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Step 2: 获取实际状态          │
                    │  列出所有标签为                │
                    │  cluster=my-postgres 的 Pod   │
                    │  actualPods = [pg-0]         │
                    │  （只有1个Pod在运行）          │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Step 3: 比较 Diff            │
                    │  desired(3) != actual(1)      │
                    │  缺少: pg-1, pg-2            │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Step 4: 执行操作              │
                    │  创建 pg-1 的 StatefulSet Pod │
                    │  创建 pg-2 的 StatefulSet Pod │
                    │  初始化从库（basebackup）     │
                    │  配置流复制                     │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Step 5: 更新 Status          │
                    │  status.instances = 3        │
                    │  status.readyReplicas = 3    │
                    │  status.phase = Running      │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Reconcile 结束               │
                    │  (等待下一次触发)             │
                    └──────────────────────────────┘

重要特性：
- 幂等性：多次执行结果相同
- 收敛性：最终会达到期望状态
- 异步性：不阻塞，每次 reconcile 独立
```

### 2.2 Informer 和 Watcher 机制

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator 如何感知变化？—— Informer 架构                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      Operator 进程内部                             │
│                                                                  │
│  Kubernetes API Server                                           │
│        │                                                         │
│        │  Watch (长连接/HTTP Streaming)                          │
│        │  GET /apis/pg.example.com/v1/postgresclusters?watch=1  │
│        ▼                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌───────────────────┐    │
│  │  Reflector  │───▶│  DeltaFIFO  │───▶│    Processor      │    │
│  │             │    │             │    │                   │    │
│  │ 接收事件:    │    │ 事件队列:    │    │ 弹出事件           │    │
│  │ - Added     │    │ {Add, obj}  │    │ 分发给回调函数     │    │
│  │ - Modified  │    │ {Modified,o}│    │                   │    │
│  │ - Deleted   │    │ {Deleted,o} │    │ OnAdd()           │    │
│  │             │    │             │    │ OnUpdate()        │    │
│  │ 全量List +   │    │ 先进先出    │    │ OnDelete()        │    │
│  │ 增量Watch    │    │             │    │                   │    │
│  └─────────────┘    └─────────────┘    └─────────┬─────────┘    │
│                                               │                 │
│                                    ┌──────────▼─────────┐      │
│                                    │    WorkQueue        │      │
│                                    │                    │      │
│                                    │ 限速队列            │      │
│                                    │ 去重合并            │      │
│                                    │ 延迟重试            │      │
│                                    └──────────┬─────────┘      │
│                                               │                 │
│                                    ┌──────────▼─────────┐      │
│                                    │  Reconciler Loop    │      │
│                                    │                    │      │
│                                    │ for item := range q │      │
│                                    │   reconcile(item)   │      │
│                                    └────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘

为什么用 WorkQueue 而不直接回调？

场景：10秒内对同一个CR修改了100次
  直接回调 → 触发100次Reconcile → 浪费
  WorkQueue → 合并为1次 → 高效

WorkQueue 特性：
  - Rate Limiting: 限速，避免雪崩
  - Deduplication: 去重，相同key只保留最新
  - Delaying: 延迟重试，指数退避
```

### 2.3 OwnerReference 与垃圾回收

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator 创建的资源如何跟随CR一起清理？                          │
└─────────────────────────────────────────────────────────────────┘

OwnerReference 机制:

PostgresCluster (CR)
  ├── OwnerReference: (无，这是根对象)
  │
  ├── StatefulSet (由Operator创建)
  │   └── ownerReferences:
  │       - apiVersion: pg.example.com/v1
  │         kind: PostgresCluster
  │         name: my-postgres
  │         uid: xxx-xxx-xxx
  │         controller: true
  │         blockOwnerDeletion: true
  │
  ├── Service (由Operator创建)
  │   └── ownerReferences: [同上]
  │
  ├── ConfigMap (由Operator创建)
  │   └── ownerReferences: [同上]
  │
  └── Secret (由Operator创建)
      └── ownerReferences: [同上]

当用户删除 PostgresCluster 时:
  1. K8s 发现它有子资源设置了 ownerReference
  2. 如果 blockOwnerDeletion=true，先删除子资源
  3. 子资源级联删除（StatefulSet → Pod → PVC...）
  4. 最后删除 PostgresCluster 本身

这就是垃圾回收（Garbage Collection）
```

### 2.4 最终一致性模型

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator 的最终一致性 —— 不追求强一致，但保证最终收敛             │
└─────────────────────────────────────────────────────────────────┘

时间线：

T0: 用户创建 CR (instances: 3)
    ↓ Reconcile #1
T1: 创建了 StatefulSet (但Pod还没起来)
    ↓ (Reconcile结束，等待下次触发)

T2: Pod Ready 事件触发
    ↓ Reconcile #2
T3: 检测到3个Pod都Ready，更新Status
    ↓ (Reconcile结束)

T4: 用户修改 CR (instances: 5)
    ↓ Reconcile #3
T5: 更新StatefulSet replicas=5
    ↓ (Reconcile结束)

T6: 新Pod Ready事件触发
    ↓ Reconcile #4
T7: 确认5个实例都就绪
    ↓ ...

关键点：
- 每次Reconcile只做"合理的一步"
- 不追求一次完成所有事
- 通过多次循环逐步收敛
- 即使中途出错，下次循环会自动修复

这就像恒温器：
  设定温度25°C → 当前20°C → 开启加热
  当前22°C → 继续加热
  当前24°C → 继续加热
  当前25°C → 停止加热
  当前24.5°C → 再次加热
  ... 永远在调节，永远趋向目标
```

---

## 3. PostgreSQL Operator 完整实战

### 3.1 项目规划

```
┌─────────────────────────────────────────────────────────────────┐
│  我们要构建什么？                                                 │
└─────────────────────────────────────────────────────────────────┘

PostgresCluster CRD 功能清单：

┌─────────────────────────────────────────────────────────────────┐
│  核心功能                                                        │
├─────────────────────────────────────────────────────────────────┤
│  ✅ 创建 PostgreSQL 单实例集群                                   │
│  ✅ 创建 PostgreSQL 高可用集群（Primary + Replica）               │
│  ✅ 自动故障检测与主从切换（Failover）                            │
│  ✅ 水平扩缩容                                                   │
│  ✅ 滚动升级                                                     │
│  ✅ 持久化存储管理                                               │
│  ✅ 连接池（PgBouncer集成）                                      │
│  ✅ 备份与恢复                                                   │
│  ✅ 监控指标导出                                                 │
└─────────────────────────────────────────────────────────────────┘

技术选型：
  - 语言: Go 1.21+
  - 框架: Kubebuilder (基于 controller-runtime)
  - API版本: v1 (稳定版)
  - 数据库编排: Patroni（成熟的高可用方案）
```

### 3.2 项目初始化

```bash
# 安装 kubebuilder
curl -L https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH) | tar xz -
sudo mv kubebuilder /usr/local/bin/

# 安装 kustomize
go install sigs.k8s.io/kustomize/kustomize/v5@latest

# 创建项目
kubebuilder init --domain pg.example.com --repo github.com/example/postgresql-operator --license apache2

cd postgresql-operator

# 创建 API（CRD + Controller）
kubebuilder create api \
  --group postgresql \
  --version v1 \
  --kind PostgresCluster \
  --resource=true \
  --controller=true

# 项目结构
postgresql-operator/
├── api/
│   └── v1/
│       ├── postgresscluster_types.go    # CRD 类型定义
│       ├── postgresscluster_webhook.go  # 校验 Webhook
│       └── zz_generated.deepcopy.go     # 深拷贝生成
├── controllers/
│   └── postgresscluster_controller.go   # Reconcile 逻辑
├── main.go                              # 入口
├── Makefile                             # 构建/部署工具
└── config/
    ├── crd/bases/                       # CRD YAML
    ├── rbac/                            # RBAC 权限
    ├── manager/                         # 部署配置
    └── samples/                         # 示例 CR
```

### 3.3 定义 CRD 类型

```go
// api/v1/postgresscluster_types.go

package v1

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PostgresClusterSpec 定义 PostgresCluster 的期望状态
type PostgresClusterSpec struct {
	// 实例数量
	Instances int32 `json:"instances"`

	// PostgreSQL 版本
	PostgreSQLVersion string `json:"postgresqlVersion"`

	// 存储配置
	Storage StorageSpec `json:"storage"`

	// 资源请求和限制
	Resources corev1.ResourceRequirements `json:"resources,omitempty"`

	// 高可用配置
	HighAvailability HighAvailabilitySpec `json:"highAvailability,omitempty"`

	// 备份配置
	Backup BackupSpec `json:"backup,omitempty"`

	// 连接池配置
	ConnectionPool *ConnectionPoolSpec `json:"connectionPool,omitempty"`

	// PostgreSQL 参数
	Parameters map[string]string `json:"parameters,omitempty"`
}

type StorageSpec struct {
	Size           string `json:"size"`
	StorageClass   string `json:"storageClass,omitempty"`
}

type HighAvailabilitySpec struct {
	Enabled bool `json:"enabled"`
	// 故障检测超时（秒）
	FailoverTimeout int32 `json:"failoverTimeout,omitempty"`
}

type BackupSpec struct {
	Enabled  bool   `json:"enabled"`
	Schedule string `json:"schedule,omitempty"`
	Retention int32 `json:"retention,omitempty"`
	// 目标存储位置
	Destination string `json:"destination,omitempty"`
}

type ConnectionPoolSpec struct {
	Enabled     bool                   `json:"enabled"`
	MinConnections int32               `json:"minConnections,omitempty"`
	MaxClientConn int32                `json:"maxClientConn,omitempty"`
	Mode        string                 `json:"mode,omitempty"` // transaction, session, statement
	Resources   corev1.ResourceRequirements `json:"resources,omitempty"`
}

// PostgresClusterStatus 定义 PostgresCluster 的实际状态
type PostgresClusterStatus struct {
	// 集群阶段: Pending | Creating | Running | Updating | FailingOver | Error
	Phase string `json:"phase"`

	// 就绪实例数
	ReadyReplicas int32 `json:"readyReplicas"`

	// 当前主库名称
	CurrentPrimary string `json:"currentPrimary"`

	// 所有实例列表
	Instances []InstanceStatus `json:"instances,omitempty"`

	// Conditions 用于描述状态转换
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

type InstanceStatus struct {
	Name     string `json:"name"`
	Role     string `json:"role"` // primary | replica
	Ready    bool   `json:"ready"`
	PodName  string `json:"podName"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:shortName=pg
// +kubebuilder:printcolumn:name="Instances",type="integer",JSONPath=".spec.instances",description="Number of instances"
// +kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase",description="Cluster phase"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"

type PostgresCluster struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PostgresClusterSpec   `json:"spec,omitempty"`
	Status PostgresClusterStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

type PostgresClusterList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PostgresCluster `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PostgresCluster{}, &PostgresClusterList{})
}
```

### 3.4 实现 Controller（核心 Reconcile 逻辑）

```go
// controllers/postgresscluster_controller.go

package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	logf "sigs.k8s.io/controller-runtime/pkg/log"

	pgv1 "github.com/example/postgresql-operator/api/v1"
)

const (
	finalizerName = "postgrescluster.pg.example.com/finalizer"
	requeueAfter  = 30 * time.Second
)

var log = logf.Log.WithName("postgresscluster-controller")

// PostgresClusterReconciler reconciles a PostgresCluster object
type PostgresClusterReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// Reconcile 是控制循环的核心
func (r *PostgresClusterReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.WithValues("postgresscluster", req.NamespacedName)

	var cluster pgv1.PostgresCluster
	if err := r.Get(ctx, req.NamespacedName, &cluster); err != nil {
		if errors.IsNotFound(err) {
			return ctrl.Result{}, nil
		}
		return ctrl.Result{}, err
	}

	// ======== 步骤1: 处理删除 ========
	if !cluster.ObjectMeta.DeletionTimestamp.IsZero() {
		return r.handleDeletion(ctx, logger, &cluster)
	}

	// ======== 步骤2: 添加 Finalizer ========
	if !controllerutil.ContainsFinalizer(&cluster, finalizerName) {
		controllerutil.AddFinalizer(&cluster, finalizerName)
		if err := r.Update(ctx, &cluster); err != nil {
			return ctrl.Result{}, err
		}
		return ctrl.Result{Requeue: true}, nil
	}

	// ======== 步骤3: 协调 StatefulSet ========
	sts, err := r.reconcileStatefulSet(ctx, logger, &cluster)
	if err != nil {
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	// ======== 步骤4: 协调 Service ========
	if err := r.reconcileService(ctx, logger, &cluster); err != nil {
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	// ======== 步骤5: 协调 ConfigMap（PostgreSQL配置） ========
	if err := r.reconcileConfigMap(ctx, logger, &cluster); err != nil {
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	// ======== 步骤6: 协调 Secret（密码等） ========
	if err := r.reconcileSecret(ctx, logger, &cluster); err != nil {
		return r.updateErrorStatus(ctx, logger, &cluster, err)
	}

	// ======== 步骤7: 协调 PgBouncer（如果启用） ========
	if cluster.Spec.ConnectionPool != nil && cluster.Spec.ConnectionPool.Enabled {
		if err := r.reconcilePgBouncer(ctx, logger, &cluster); err != nil {
			return r.updateErrorStatus(ctx, logger, &cluster, err)
		}
	}

	// ======== 步骤8: 更新 Status ========
	if err := r.updateStatus(ctx, logger, &cluster, sts); err != nil {
		return ctrl.Result{}, err
	}

	return ctrl.Result{RequeueAfter: requeueAfter}, nil
}

// reconcileStatefulSet 创建/更新 StatefulSet
func (r *PostgresClusterReconciler) reconcileStatefulSet(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) (*appsv1.StatefulSet, error) {

	sts := &appsv1.StatefulSet{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      cluster.Name,
		Namespace: cluster.Namespace,
	}, sts)

	if errors.IsNotFound(err) {
		logger.Info("Creating new StatefulSet")
		sts = r.makeStatefulSet(cluster)
		if err := r.Create(ctx, sts); err != nil {
			return nil, fmt.Errorf("failed to create StatefulSet: %w", err)
		}
		return sts, nil
	} else if err != nil {
		return nil, err
	}

	desiredSts := r.makeStatefulSet(cluster)
	sts.Spec.Replicas = desiredSts.Spec.Replicas
	sts.Spec.Template.Spec.Containers[0].Image =
		fmt.Sprintf("postgres:%s", cluster.Spec.PostgreSQLVersion)

	if err := r.Update(ctx, sts); err != nil {
		return nil, fmt.Errorf("failed to update StatefulSet: %w", err)
	}

	return sts, nil
}

// makeStatefulSet 构建 StatefulSet 对象
func (r *PostgresClusterReconciler) makeStatefulSet(cluster *pgv1.PostgresCluster) *appsv1.StatefulSet {
	replicas := cluster.Spec.Instances
	labels := map[string]string{
		"app":       "postgresql",
		"cluster":   cluster.Name,
		"managed-by": "postgres-operator",
	}

	sts := &appsv1.StatefulSet{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cluster.Name,
			Namespace: cluster.Namespace,
			Labels:    labels,
		},
		Spec: appsv1.StatefulSetSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			ServiceName: cluster.Name + "-headless",
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
					Annotations: map[string]string{
						"io.prometheus.io/scrape": "true",
						"io.prometheus.io/port":   "9187",
					},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  "postgres",
							Image: fmt.Sprintf("postgres:%s", cluster.Spec.PostgreSQLVersion),
							Env: []corev1.EnvVar{
								{Name: "PGDATA", Value: "/var/lib/postgresql/data/pgdata"},
								{Name: "POD_NAME", ValueFrom: &corev1.EnvVarSource{
									FieldRef: &corev1.ObjectFieldSelector{FieldPath: "metadata.name"},
								}},
								{Name: "CLUSTER_NAME", Value: cluster.Name},
							},
							Ports: []corev1.ContainerPort{
								{ContainerPort: 5432, Name: "postgresql"},
								{ContainerPort: 8008, Name: "patroni"},
							},
							VolumeMounts: []corev1.VolumeMount{
								{Name: "data", MountPath: "/var/lib/postgresql/data"},
								{Name: "config", MountPath: "/etc/postgresql/conf.d"},
							},
							LivenessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									TCPSocket: &corev1.TCPSocketAction{Port: intstr.FromInt(5432)},
								},
								InitialDelaySeconds: 30,
								PeriodSeconds:       10,
							},
							ReadinessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									Exec: &corev1.ExecAction{
										Command: []string{"pg_isready", "-U", "postgres", "-h", "localhost"},
									},
								},
								InitialDelaySeconds: 5,
								PeriodSeconds:      5,
							},
							Resources: cluster.Spec.Resources,
						},
					},
					Volumes: []corev1.Volume{
						{Name: "config", VolumeSource: corev1.VolumeSource{
							ConfigMap: &corev1.ConfigMapVolumeSource{
								LocalObjectReference: corev1.LocalObjectReference{Name: cluster.Name + "-config"},
							},
						}},
					},
				},
			},
			VolumeClaimTemplates: []corev1.PersistentVolumeClaim{
				{
					ObjectMeta: metav1.ObjectMeta{Name: "data"},
					Spec: corev1.PersistentVolumeClaimSpec{
						AccessModes: []corev1.PersistentVolumeAccessMode{corev1.ReadWriteOnce},
						Resources: corev1.VolumeResourceRequirements{
							Requests: corev1.ResourceList{
								corev1.ResourceStorage: resource.MustParse(cluster.Spec.Storage.Size),
							},
						},
						StorageClassName: func() *string {
							s := cluster.Spec.Storage.StorageClass
							if s == "" {
								return nil
							}
							return &s
						}(),
					},
				},
			},
		},
	}

	if err := controllerutil.SetControllerReference(cluster, sts, r.Scheme); err != nil {
		panic(err)
	}
	return sts
}

// reconcileService 创建读写分离的Service
func (r *PostgresClusterReconciler) reconcileService(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {

	services := []struct {
		name   string
		selector map[string]string
		port    int32
	}{
		{
			name: cluster.Name,
			selector: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
				"role":    "primary",
			},
			port: 5432,
		},
		{
			name: cluster.Name + "-headless",
			selector: map[string]string{
				"app":     "postgresql",
				"cluster": cluster.Name,
			},
			port: 5432,
		},
	}

	for _, svcDef := range services {
		svc := &corev1.Service{}
		err := r.Get(ctx, types.NamespacedName{
			Name: svcDef.name, Namespace: cluster.Namespace,
		}, svc)

		newSvc := &corev1.Service{
			ObjectMeta: metav1.ObjectMeta{
				Name:      svcDef.name,
				Namespace: cluster.Namespace,
				Labels: map[string]string{
					"app": "postgresql", "cluster": cluster.Name,
				},
			},
			Spec: corev1.ServiceSpec{
				Selector: svcDef.selector,
				Ports: []corev1.ServicePort{
					{Port: svcDef.port, TargetPort: intstr.FromInt(int(svcDef.port))},
				},
				ClusterIP: func() corev1.ServiceIPType {
					if svcDef.name == cluster.Name+"-headless" {
						return corev1.ServiceIPNone
					}
					return ""
				}(),
			},
		}

		if errors.IsNotFound(err) {
			controllerutil.SetControllerReference(cluster, newSvc, r.Scheme)
			if err := r.Create(ctx, newSvc); err != nil {
				return fmt.Errorf("failed to create service %s: %w", svcDef.name, err)
			}
		} else if err == nil {
			newSvc.ResourceVersion = svc.ResourceVersion
			if err := r.Update(ctx, newSvc); err != nil {
				return fmt.Errorf("failed to update service %s: %w", svcDef.name, err)
			}
		} else {
			return err
		}
	}
	return nil
}

// reconcileConfigMap 创建 PostgreSQL 配置文件
func (r *PostgresClusterReconciler) reconcileConfigMap(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {
	cm := &corev1.ConfigMap{}
	err := r.Get(ctx, types.NamespacedName{
		Name: cluster.Name + "-config", Namespace: cluster.Namespace,
	}, cm)

	defaultParams := map[string]string{
		"max_connections":     "100",
		"shared_buffers":      "256MB",
		"effective_cache_size": "1GB",
		"maintenance_work_mem": "64MB",
		"wal_compression":     "on",
		"wal_level":           "replica",
		"max_wal_senders":     "10",
		"hot_standby":         "on",
	}

	for k, v := range cluster.Spec.Parameters {
		defaultParams[k] = v
	}

	configContent := ""
	for k, v := range defaultParams {
		configContent += fmt.Sprintf("%s = '%s'\n", k, v)
	}

	newCM := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cluster.Name + "-config",
			Namespace: cluster.Namespace,
		},
		Data: map[string]string{
			"postgresql.conf": configContent,
		},
	}

	if errors.IsNotFound(err) {
		controllerutil.SetControllerReference(cluster, newCM, r.Scheme)
		return r.Create(ctx, newCM)
	} else if err == nil {
		newCM.ResourceVersion = cm.ResourceVersion
		return r.Update(ctx, newCM)
	}
	return err
}

// reconcileSecret 创建数据库密码
func (r *PostgresClusterReconciler) reconcileSecret(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) error {
	secret := &corev1.Secret{}
	err := r.Get(ctx, types.NamespacedName{
		Name: cluster.Name + "-secret", Namespace: cluster.Namespace,
	}, secret)

	newSecret := &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{
			Name:      cluster.Name + "-secret",
			Namespace: cluster.Namespace,
		},
		StringData: map[string]string{
			"POSTGRES_PASSWORD": generatePassword(),
			"PATRONI_REPLICATION_PASSWORD": generatePassword(),
			"PATRONI_SUPERUSER_PASSWORD":  generatePassword(),
		},
		Type: corev1.SecretTypeOpaque,
	}

	if errors.IsNotFound(err) {
		controllerutil.SetControllerReference(cluster, newSecret, r.Scheme)
		return r.Create(ctx, newSecret)
	}
	return nil
}

// updateStatus 更新 CR 状态
func (r *PostgresClusterReconciler) updateStatus(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
	sts *appsv1.StatefulSet,
) error {
	podList := &corev1.PodList{}
	r.List(ctx, podList, client.InNamespace(cluster.Namespace),
		client.MatchingLabels{"cluster": cluster.Name})

	readyCount := int32(0)
	var instances []pgv1.InstanceStatus
	for _, pod := range podList.Items {
		isReady := false
		for _, cond := range pod.Status.Conditions {
			if cond.Type == corev1.PodReady && cond.Status == corev1.ConditionTrue {
				isReady = true
				break
			}
		}
		if isReady {
			readyCount++
		}
		instances = append(instances, pgv1.InstanceStatus{
			Name:    pod.Name,
			Role:    getPodRole(pod),
			Ready:   isReady,
			PodName: pod.Name,
		})
	}

	currentPrimary := findPrimary(podList.Items)

	oldStatus := cluster.Status
	cluster.Status.Phase = determinePhase(sts, readyCount, cluster.Spec.Instances)
	cluster.Status.ReadyReplicas = readyCount
	cluster.Status.CurrentPrimary = currentPrimary
	cluster.Status.Instances = instances

	setCondition(&cluster.Status, "Ready", readyCount >= 1, "")

	if oldStatus.Phase != cluster.Status.Phase ||
		oldStatus.ReadyReplicas != cluster.Status.ReadyReplicas ||
		oldStatus.CurrentPrimary != cluster.Status.CurrentPrimary {
		return r.Status().Update(ctx, cluster)
	}
	return nil
}

// handleDeletion 处理删除前的清理工作
func (r *PostgresClusterReconciler) handleDeletion(
	ctx context.Context,
	logger logr.Logger,
	cluster *pgv1.PostgresCluster,
) (ctrl.Result, error) {

	logger.Info("Performing pre-delete cleanup")

	if controllerutil.ContainsFinalizer(cluster, finalizerName) {
		if cluster.Spec.Backup.Enabled {
			if err := r.performFinalBackup(ctx, logger, cluster); err != nil {
				logger.Error(err, "Final backup failed, retrying")
				return ctrl.Result{RequeueAfter: time.Minute}, err
			}
		}

		controllerutil.RemoveFinalizer(cluster, finalizerName)
		if err := r.Update(ctx, cluster); err != nil {
			return ctrl.Result{}, err
		}
	}
	return ctrl.Result{}, nil
}

// SetupWithManager 注册 Controller 到 Manager
func (r *PostgresClusterReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&pgv1.PostgresCluster{}).
		Owns(&appsv1.StatefulSet{}).
		Owns(&corev1.Service{}).
		Owns(&corev1.ConfigMap{}).
		Owns(&corev1.Secret{}).
		Complete(r)
}
```

### 3.5 入口函数

```go
package main

import (
	"os"
	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"

	pgv1 "github.com/example/postgresql-operator/api/v1"
	"github.com/example/postgresql-operator/controllers"
)

var scheme = runtime.NewScheme()

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
	utilruntime.Must(pgv1.AddToScheme(scheme))
}

func main() {
	ctrl.SetLogger(zap.New(zap.UseDevMode(true)))

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 scheme,
		MetricsBindAddress:     ":8080",
		HealthProbeBindAddress":8081",
		LeaderElection:         true,
		LeaderElectionID:       "a8e9c074.pg.example.com",
	})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}

	if err = (&controllers.PostgresClusterReconciler{
		Client: mgr.GetClient(),
		Scheme: mgr.GetScheme(),
	}).SetupWithManager(mgr); err != nil {
		setupLog.Error(err, "unable to create controller")
		os.Exit(1)
	}

	if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
		setupLog.Error(err, "unable to set up health check")
		os.Exit(1)
	}

	if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
		setupLog.Error(err, "unable to set up ready check")
		os.Exit(1)
	}

	setupLog.Info("starting manager")
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		setupLog.Error(err, "problem running manager")
		os.Exit(1)
	}
}
```

### 3.6 构建和部署

```bash
# 本地构建 Docker 镜像
make docker-build IMG=registry.example.com/postgresql-operator:v0.1.0

# 推送到镜像仓库
make docker-push IMG=registry.example.com/postgresql-operator:v0.1.0

# 部署到集群
make deploy IMG=registry.example.com/postgresql-operator:v0.1.0

# 或者手动部署
kubectl apply -f config/crd/bases/
kubectl apply -f config/rbac/
kubectl apply -f config/manager/
```

---

## 4. 使用 PostgreSQL Operator

### 4.1 创建单实例集群

```yaml
apiVersion: postgresql.v1
kind: PostgresCluster
metadata:
  name: my-postgres
  namespace: production
spec:
  instances: 1
  postgresqlVersion: "16"
  storage:
    size: 50Gi
    storageClass: standard-rwo
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  parameters:
    max_connections: "200"
    shared_buffers: "512MB"
    effective_cache_size: "2GiB"
```

```bash
kubectl apply -f single-instance.yaml

# 查看 CR
kubectl get pg my-postgres -n production
# NAME          INSTANCES   PHASE      AGE
# my-postgres   1           Running    2m

# 查看详情
kubectl describe pg my-postgres -n production

# 查看创建的资源
kubectl get all -l cluster=my-postgres -n production
```

### 4.2 创建高可用集群

```yaml
apiVersion: postgresql.v1
kind: PostgresCluster
metadata:
  name: prod-postgres-ha
  namespace: production
spec:
  instances: 3
  postgresqlVersion: "16"
  storage:
    size: 100Gi
    storageClass: premium-rwo
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "4"
      memory: "8Gi"
  highAvailability:
    enabled: true
    failoverTimeout: 60
  backup:
    enabled: true
    schedule: "0 2 * * *"
    retention: 14
    destination: "gs://my-bucket/backups/prod-postgres"
  connectionPool:
    enabled: true
    minConnections: 10
    maxClientConn: 200
    mode: "transaction"
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
  parameters:
    max_connections: "300"
    shared_buffers: "1GB"
    effective_cache_size: "4GB"
    wal_level: "replica"
    max_wal_senders: "15"
    synchronous_commit: "on"
```

### 4.3 扩缩容

```bash
# 从3实例扩容到5实例
kubectl patch pg prod-postgres-ha -n production --type merge -p '{"spec":{"instances":5}}'

# 缩容到2实例
kubectl patch pg prod-postgres-ha -n production --type merge -p '{"spec":{"instances":2}}'
```

### 4.4 升级 PostgreSQL 版本

```bash
# 滚动升级到 PostgreSQL 17
kubectl patch pg prod-postgres-ha -n production --type merge -p '{"spec":{"postgresqlVersion":"17"}}'

# 观察滚动升级过程
kubectl rollout status statefulset/prod-postgres-ha -n production
```

### 4.5 查看集群状态

```bash
# 查看集群概览
kubectl get pg -A -o wide

# 查看详细状态
kubectl get pg prod-postgres-ha -n production -o yaml | grep -A30 status:

# 输出示例:
# status:
#   phase: Running
#   readyReplicas: 3
#   currentPrimary: prod-postgres-ha-2
#   instances:
#   - name: prod-postgres-ha-0
#     role: replica
#     ready: true
#     podName: prod-postgres-ha-0
#   - name: prod-postgres-ha-1
#     role: replica
#     ready: true
#     podName: prod-postgres-ha-1
#   - name: prod-postgres-ha-2
#     role: primary
#     ready: true
#     podName: prod-postgres-ha-2
```

---

## 5. Operator 设计模式总结

### 5.1 核心设计原则

```
┌─────────────────────────────────────────────────────────────────┐
│  编写好 Operator 的黄金法则                                       │
└─────────────────────────────────────────────────────────────────┘

1. Reconcile 必须是幂等的
   ┌───────────────────────────────────────────────────────────┐
   │ 同一个CR调用100次Reconcile，结果和调用1次一样               │
   │ 不要假设之前的状态，每次都从零开始思考                       │
   └───────────────────────────────────────────────────────────┘

2. Reconcile 必须是收敛的
   ┌───────────────────────────────────────────────────────────┐
   │ 经过有限次Reconcile后，系统必须达到稳定状态                │
   │ 如果一直不收敛，说明有bug                                  │
   └───────────────────────────────────────────────────────────┘

3. 错误不要 panic，返回 error 并 requeue
   ┌───────────────────────────────────────────────────────────┐
   │ 外部依赖可能暂时不可用（API超时、DNS解析失败等）            │
   │ 返回error让框架稍后重试，不要直接crash                     │
   └───────────────────────────────────────────────────────────┘

4. 只关心自己的资源
   ┌───────────────────────────────────────────────────────────┐
   │ 用 Owns() 声明自己创建的资源                               │
   │ 用 For() 声明自己监听的资源                                │
   │ 不要越权管理不属于你的资源                                  │
   └───────────────────────────────────────────────────────────┘

5. Status 反映真实状态
   ┌───────────────────────────────────────────────────────────┐
   │ Status是给用户看的，必须反映集群的真实情况                  │
   │ 不要乐观地更新Status，要基于实际观察到的状态                │
   └───────────────────────────────────────────────────────────┘
```

### 5.2 常见模式对照表

| 场景 | 模式 | 说明 |
|------|------|------|
| 创建资源 | Get-or-Create | 先Get，NotFound则Create |
| 更新资源 | Mutate-and-Update | 读出现有对象，修改字段，再Update |
| 删除前清理 | Finalizer | 删除时执行清理逻辑 |
| 资源关联 | OwnerReference | 设置owner实现级联删除 |
| 状态同步 | Subresource Update | 使用Status()接口更新 |
| 事件去重 | WorkQueue | 合并同一对象的多次变更 |
| 领外依赖 | External Reconciler | 管理非K8s资源 |
| 配置校验 | ValidatingWebhook | 创建前校验CR合法性 |
| 默认值 | DefaultingWebhook | 创建时填充默认值 |
| 多版本 | Conversion Webhook | CRD版本间转换 |

### 5.3 成熟 Operator 参考

| Operator | 管理 | GitHub Stars | 特点 |
|----------|------|-------------|------|
| CloudNativePG | PostgreSQL | ~3k | CNCF沙箱项目，功能完整 |
| Zalando Postgres Operator | PostgreSQL | ~4k | 生产验证，Patroni集成 |
| Percona PG Operator | PostgreSQL | ~1k | 商业支持，企业级 |
| Redis Operator | Redis | ~2k | Sentinel/Cluster模式 |
| RabbitMQ Cluster Operator | RabbitMQ | ~1.5k | Erlang原生集成 |
| Strimzi Kafka Operator | Kafka | ~4k | CNCF项目，最成熟的之一 |
| Prometheus Operator | Monitoring | ~5k | 事实标准 |
| Cert-manager | Certificate | ~11k | 最流行的Operator之一 |
