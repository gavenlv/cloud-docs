# Kubernetes Operator开发

## 本章导学

**学完本章后，你将能够：**

- 从**设计模式**理解Operator的核心原理——控制器模式
- 从**CRD机制**理解Kubernetes扩展API的方式
- 从**协调循环**理解Operator如何保持期望状态与实际状态一致
- 掌握Operator开发框架（kubebuilder、controller-runtime）
- 学会构建生产级别的Operator

**学习方法：**

```
原理 → CRD设计 → 控制器实现 → Operator Framework → 实战开发
```

---

# Operator核心原理

## 1.1 Operator是什么？

### 1.1.1 Operator的设计理念

```
┌─────────────────────────────────────────────────────────────────┐
│                    Operator设计理念                                   │
└─────────────────────────────────────────────────────────────────┘

Operator是Kubernetes的扩展机制，它让你能够：
1. 定义新的资源类型（CRD）
2. 自动化管理有状态应用的整个生命周期
3. 将运维知识编码到软件中

┌─────────────────────────────────────────────────────────────────┐
│  传统应用管理 vs Operator管理                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  传统应用管理：                                                 │
│                                                                  │
│  管理员                          Kubernetes                      │
│    │                                │                             │
│    │  1. 手动部署                  │                             │
│    │ ─────────────────────────────>│                             │
│    │                                │                             │
│    │  2. 手动监控                  │                             │
│    │ ─────────────────────────────>│                             │
│    │                                │                             │
│    │  3. 手动扩缩容               │                             │
│    │ ─────────────────────────────>│                             │
│    │                                │                             │
│    │  4. 手动故障恢复             │                             │
│    │ ─────────────────────────────>│                             │
│                                                                  │
│  问题：需要人工介入，无法自动化                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Operator管理：                                                 │
│                                                                  │
│  应用声明                          Operator                       │
│  │                                │                              │
│  │  1. 声明期望状态              │                              │
│  │ ─────────────────────────────>│                              │
│  │                                │  2. 读取期望状态             │
│  │                                │ ─────────────────────────────>│
│  │                                │                              │
│  │                                │  3. 查看实际状态             │
│  │                                │ <─────────────────────────────│
│  │                                │                              │
│  │                                │  4. 执行操作达到期望         │
│  │                                │ ─────────────────────────────>│
│  │                                │                              │
│  │  5. 查看实际状态              │                              │
│  │ <─────────────────────────────│                              │
│                                                                  │
│  优势：自动化、声明式、智能化                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1.2 Operator与控制器的类比

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes内置控制器 vs Operator                     │
└─────────────────────────────────────────────────────────────────┘

Kubernetes内置控制器：
┌─────────────────────────────────────────────────────────────────┐
│  Deployment Controller：                                         │
│  ├── 监控：Deployment对象                                       │
│  ├── 期望：指定的replica数量                                   │
│  ├── 实际：运行的Pod数量                                       │
│  ├── 协调：创建/删除Pod达到期望                                │
│  └── 机制：Control Loop（控制循环）                            │
│                                                                  │
│  Reconciliation Loop（协调循环）：                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │    ┌─────────────┐                                      │    │
│  │    │  Get State  │                                      │    │
│  │    └──────┬──────┘                                      │    │
│  │           │                                              │    │
│  │           ▼                                              │    │
│  │    ┌─────────────┐                                      │    │
│  │    │ Compare     │                                      │    │
│  │    │ Desired vs  │                                      │    │
│  │    │ Actual      │                                      │    │
│  │    └──────┬──────┘                                      │    │
│  │           │                                              │    │
│  │           ▼                                              │    │
│  │    ┌─────────────┐                                      │    │
│  │    │   Act       │                                      │    │
│  │    │   (Reconcile)│                                      │    │
│  │    └──────┬──────┘                                      │    │
│  │           │                                              │    │
│  │           └──────────────────┐                          │    │
│  │                              │                          │    │
│  │                              │ 循环                     │    │
│  └──────────────────────────────┴──────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Operator = 自定义控制器 + 领域知识

┌─────────────────────────────────────────────────────────────────┐
│  Prometheus Operator：                                           │
│  ├── 监控：Prometheus CRD                                      │
│  ├── 期望：AlertManager配置、ServiceMonitor                    │
│  ├── 实际：运行的Prometheus Pod                                │
│  ├── 协调：创建/配置/更新Prometheus                            │
│  └── 领域知识：如何配置Prometheus参数                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.2 CRD机制原理

### 1.2.1 CRD架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    CRD在Kubernetes API中的位置                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes API层级结构                            │
└─────────────────────────────────────────────────────────────────┘

/apis/batch/v1/namespaces/{ns}/jobs
         │
         │ 核心组（core group）
         ▼
/api/v1/namespaces/{ns}/pods
/api/v1/namespaces/{ns}/services
...

         │ 命名组（named group）
         ▼
/apis/apps/v1/namespaces/{ns}/deployments
/apis/networking.k8s.io/v1/namespaces/{ns}/ingresses
...

         │ 自定义资源（CRD）
         ▼
/apis/example.com/v1/namespaces/{ns}/myapps
/apis.operators.coreos.com/v1alpha1/namespaces/{ns}/subscriptions
...

┌─────────────────────────────────────────────────────────────────┐
│  CRD结构：                                                       │
│                                                                  │
│  apiVersion: example.com/v1                                     │
│  kind: MyApp                                                    │
│  metadata:                                                      │
│    name: my-app                                                 │
│    namespace: default                                           │
│  spec:           # 用户定义的期望状态                           │
│    replicas: 3                                                 │
│    image: nginx:1.21                                           │
│  status:         # Operator更新的实际状态                        │
│    availableReplicas: 3                                        │
│    conditions:                                                  │
│    - type: Ready                                               │
│      status: "True"                                            │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2.2 CRD定义

```yaml
# crd.yaml - MyApp资源的CRD定义

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myapps.example.com
  annotations:
    # 控制CRD版本
    controller-gen.kubebuilder.io/version: v0.9.0
spec:
  # API组
  group: example.com
  # 版本列表
  versions:
    - name: v1
      served: true          # 是否提供此版本
      storage: true         # 是否是存储版本（只能有一个）
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 10
                image:
                  type: string
            status:
              type: object
              properties:
                availableReplicas:
                  type: integer
  # 作用域：Namespaced或Cluster
  scope: Namespaced
  names:
    kind: MyApp           # CRD_kind
    listKind: MyAppList   # 列表类型
    plural: myapps         # REST API路径
    singular: myapp        # 单数形式
    shortNames:
      - ma               # 缩写
  preserveUnknownFields: false
```

```bash
# 应用CRD
kubectl apply -f crd.yaml

# 查看CRD
kubectl get crd
# 输出：
# NAME                          CREATED AT
# myapps.example.com            2024-01-01T00:00:00Z

# 查看CRD详情
kubectl describe crd myapps.example.com
```

### 1.2.3 CRD版本管理

```
┌─────────────────────────────────────────────────────────────────┐
│                    CRD版本管理策略                                   │
└─────────────────────────────────────────────────────────────────┘

版本类型：
┌─────────────────────────────────────────────────────────────────┐
│  1. 单版本：                                                    │
│     versions:                                                    │
│     - name: v1                                                  │
│       served: true                                              │
│       storage: true                                             │
│                                                                  │
│  2. 多版本共存：                                                │
│     versions:                                                    │
│     - name: v1                                                  │
│       served: true                                               │
│       storage: true                                             │
│     - name: v1beta1                                             │
│       served: true                                              │
│       storage: false                                            │
│                                                                  │
│  3. 版本转换（Webhook）：                                        │
│     versions:                                                    │
│     - name: v1                                                  │
│       served: true                                              │
│       storage: true                                             │
│     - name: v2                                                  │
│       served: true                                              │
│       storage: true                   ← 多个存储版本需要转换Webhook│
│     conversion:                                                  │
│       strategy: Webhook                                        │
│       webhook:                                                  │
│         conversionReviewVersions:                               │
│         - v1                                                    │
│         - v2                                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.3 控制器模式原理

### 1.3.1 控制器架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    控制器架构                                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Operator进程                              │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Informer组件                            │ │
│  │  ┌─────────────┐      ┌─────────────┐                     │ │
│  │  │  Reflector  │ ───> │  DeltaFIFO  │                     │ │
│  │  │            │      │             │                     │ │
│  │  └──────┬──────┘      └──────┬──────┘                     │ │
│  │         │                    │                            │ │
│  │         │             ┌──────┴──────┐                     │ │
│  │         │             │             │                     │ │
│  │         ▼             ▼             ▼                     │ │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐              │ │
│  │  │  Store    │ │ Indexer   │ │  WorkQueue│              │ │
│  │  └───────────┘ └───────────┘ └───────────┘              │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Controller组件                           │ │
│  │                                                            │ │
│  │  ┌─────────────┐      ┌─────────────┐                    │ │
│  │  │ Reconcile  │ ───> │   Client    │                    │ │
│  │  │   Loop     │      │             │                    │ │
│  │  └─────────────┘      └─────────────┘                    │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    组件职责                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Reflector：                                                     │
│  ├── 从API Server监听资源变化                                   │
│  ├── 使用List-Watch机制                                         │
│  └── 异常处理和重试                                             │
│                                                                  │
│  DeltaFIFO：                                                    │
│  ├── 存储资源的变化（Delta）                                   │
│  ├── 队列操作：Add/Update/Delete                              │
│  └── 确保资源顺序                                               │
│                                                                  │
│  Indexer：                                                      │
│  ├── 提供资源索引                                               │
│  ├── 支持按namespace、labels查询                               │
│  └── Thread-safe                                                │
│                                                                  │
│  WorkQueue：                                                    │
│  ├── 延迟队列（带重试）                                        │
│  ├── 限速队列（Rate Limiting）                                 │
│  └── 队列去重                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3.2 协调循环

```
┌─────────────────────────────────────────────────────────────────┐
│                    Reconcile循环详解                               │
└─────────────────────────────────────────────────────────────────┘

Reconcile函数签名：
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  func (r *MyAppReconciler) Reconcile(ctx context.Context,       │
│                                        req ctrl.Request)         │
│                                        (ctrl.Result, error)     │
│                                                                  │
│  参数：                                                          │
│  ├── ctx: Context，用于取消和超时                               │
│  └── req: Request，包含Name和Namespace用于定位资源             │
│                                                                  │
│  返回值：                                                        │
│  ├── Result: 下次调度的时刻                                     │
│  └── error: 错误信息                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

Reconcile流程：
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. Fetch Resource                                              │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  r.Get(ctx, req.NamespacedName, &myapp)            │    │
│     │                                                     │    │
│     │  错误处理：                                          │    │
│     │  ├── NotFound → 返回，不重试                        │    │
│     │  └── 其他错误 → 返回，重试                          │    │
│     └─────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  2. Load MyApp Spec                                            │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  replicas := myapp.Spec.Replicas                   │    │
│     │  image := myapp.Spec.Image                         │    │
│     └─────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  3. Create/Update Deployment                                   │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  // 期望状态                                        │    │
│     │  desired := r.desiredDeployment(myapp)             │    │
│     │                                                     │    │
│     │  // 实际状态                                        │    │
│     │  actual, err := r.getActualDeployment(myapp)       │    │
│     │                                                     │    │
│     │  // 协调                                             │    │
│     │  if !exists {                                      │    │
│     │      return r.createDeployment(desired)             │    │
│     │  }                                                 │    │
│     │  if needsUpdate(actual, desired) {                  │    │
│     │      return r.updateDeployment(actual, desired)     │    │
│     │  }                                                 │    │
│     └─────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  4. Update MyApp Status                                        │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  // 获取实际Deployment状态                          │    │
│     │  status := getDeploymentStatus(actual)             │    │
│     │                                                     │    │
│     │  // 更新MyApp Status                                │    │
│     │  return r.updateStatus(&myapp, status)            │    │
│     └─────────────────────────────────────────────────────┘    │
│                              │                                  │
│                              ▼                                  │
│  5. Return Result                                               │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  return ctrl.Result{RequeueAfter: 30*time.Second}, nil│    │
│     │                                                     │    │
│     │  // 不需要重试                                      │    │
│     │  return ctrl.Result{}, nil                          │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.4 kubebuilder框架

### 1.4.1 kubebuilder项目结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubebuilder项目结构                               │
└─────────────────────────────────────────────────────────────────┘

my-operator/
├── main.go                          # 程序入口
├── go.mod                           # Go模块
├── go.sum                           # 依赖锁定
├── Makefile                         # 构建脚本
├── config/
│   ├── default/                     # 默认配置
│   │   └── manager_config.yaml
│   ├── rbac/                        # RBAC配置
│   │   ├── role.yaml
│   │   └── role_binding.yaml
│   ├── prometheus/                  # 监控配置
│   │   └── monitor.yaml
│   └── crd/
│       └── kustomization.yaml
├── api/
│   └── v1/
│       ├── groupversion_info.go    # 版本信息
│       ├── myapp_types.go         # CRD类型定义
│       └── zz_generated.deepcopy.go # 自动生成的代码
├── controllers/
│   ├── myapp_controller.go        # 控制器逻辑
│   └── suite_test.go               # 控制器测试
└── test/
    └── e2e_test.go                  # E2E测试

┌─────────────────────────────────────────────────────────────────┐
│                    各文件职责                                       │
└─────────────────────────────────────────────────────────────────┘

main.go：
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  func main() {                                                  │
│      // 1. 初始化flag                                          │
│      // 2. 初始化Manager                                        │
│      // 3. 注册Controller                                       │
│      // 4. 启动Manager                                          │
│  }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

myapp_types.go（定义CRD）：
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  type MyAppSpec struct {                                        │
│      Replicas *int32 `json:"replicas,omitempty"`                │
│      Image    string `json:"image"`                             │
│  }                                                              │
│                                                                  │
│  type MyAppStatus struct {                                       │
│      AvailableReplicas int32 `json:"availableReplicas"`         │
│  }                                                              │
│                                                                  │
│  type MyApp struct {                                             │
│      metav1.TypeMeta   `json:",inline"`                         │
│      metav1.ObjectMeta `json:"metadata"`                        │
│      Spec   MyAppSpec   `json:"spec"`                          │
│      Status MyAppStatus `json:"status"`                        │
│  }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4.2 Controller实现

```go
// controllers/myapp_controller.go

package controllers

import (
    "context"
    "fmt"

    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    "sigs.k8s.io/controller-runtime/pkg/log"

    example.comv1 "my-operator/api/v1"
)

// MyAppReconciler reconciles a MyApp object
type MyAppReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=example.com,resources=myapps,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=example.com,resources=myapps/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete

func (r *MyAppReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := log.FromContext(ctx)

    // 1. 获取MyApp资源
    myapp := &examplecomv1.MyApp{}
    if err := r.Get(ctx, req.NamespacedName, myapp); err != nil {
        logger.Error(err, "无法获取MyApp资源")
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 2. 定义期望的Deployment
    desired := r.desiredDeployment(myapp)

    // 3. 获取实际的Deployment
    actual := &appsv1.Deployment{}
    err := r.Get(ctx, req.NamespacedName, actual)

    if err != nil && client.IgnoreNotFound(err) != nil {
        return ctrl.Result{}, err
    }

    if client.IgnoreNotFound(err) == nil {
        // Deployment已存在，检查是否需要更新
        if needsUpdate(actual, desired) {
            if err := r.Update(ctx, desired); err != nil {
                return ctrl.Result{}, err
            }
        }
    } else {
        // 创建新的Deployment
        if err := r.Create(ctx, desired); err != nil {
            return ctrl.Result{}, err
        }
    }

    // 4. 更新Status
    if err := r.updateStatus(ctx, myapp, actual); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
}

func (r *MyAppReconciler) desiredDeployment(myapp *examplecomv1.MyApp) *appsv1.Deployment {
    replicas := int32(1)
    if myapp.Spec.Replicas != nil {
        replicas = *myapp.Spec.Replicas
    }

    return &appsv1.Deployment{
        ObjectMeta: metav1.ObjectMeta{
            Name:      myapp.Name,
            Namespace: myapp.Namespace,
        },
        Spec: appsv1.DeploymentSpec{
            Replicas: &replicas,
            Selector: &metav1.LabelSelector{
                MatchLabels: map[string]string{
                    "app": myapp.Name,
                },
            },
            Template: corev1.PodTemplateSpec{
                ObjectMeta: metav1.ObjectMeta{
                    Labels: map[string]string{
                        "app": myapp.Name,
                    },
                },
                Spec: corev1.PodSpec{
                    Containers: []corev1.Container{
                        {
                            Name:  "myapp",
                            Image: myapp.Spec.Image,
                        },
                    },
                },
            },
        },
    }
}

func (r *MyAppReconciler) updateStatus(ctx context.Context, myapp *examplecomv1.MyApp, deploy *appsv1.Deployment) error {
    myapp.Status.AvailableReplicas = deploy.Status.AvailableReplicas
    return r.Status().Update(ctx, myapp)
}

func needsUpdate(actual, desired *appsv1.Deployment) bool {
    // 检查是否需要更新
    return *actual.Spec.Replicas != *desired.Spec.Replicas ||
           actual.Spec.Template.Spec.Containers[0].Image != desired.Spec.Template.Spec.Containers[0].Image
}
```

---

## 1.5 Webhook机制

### 1.5.1 Webhook类型

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Webhook类型                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  1. Mutation Webhook（变更Webhook）                             │
│                                                                  │
│  用途：在对象创建/更新前修改对象                                 │
│  时机：PATCH请求之前                                            │
│  应用：设置默认值、注入 sidecar、修改配置                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Client          API Server         MutatingWebhook    │    │
│  │    │                  │                   │            │    │
│  │    │  POST /api/v1/.. │                   │            │    │
│  │    │ ────────────────> │                   │            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 1. 创建对象      │            │    │
│  │    │                   │ ─────────────────>│            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 2. 返回修改后的对象│            │    │
│  │    │                   │ <─────────────────│            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 3. 继续创建流程   │            │    │
│  │    │                   │                   │            │    │
│  │    │  201 Created      │                   │            │    │
│  │    │ <──────────────── │                   │            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  2. Validation Webhook（验证Webhook）                           │
│                                                                  │
│  用途：在对象创建/更新前验证对象                                │
│  时机：PUT/PATCH请求之前                                        │
│  应用：检查配置是否合法、约束条件验证                           │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Client          API Server         ValidatingWebhook   │    │
│  │    │                  │                   │            │    │
│  │    │  POST /api/v1/.. │                   │            │    │
│  │    │ ────────────────> │                   │            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 1. 验证对象      │            │    │
│  │    │                   │ ─────────────────>│            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 2. 返回验证结果  │            │    │
│  │    │                   │ <─────────────────│            │    │
│  │    │                   │                   │            │    │
│  │    │                   │ 3. 决定是否创建  │            │    │
│  │    │                   │                   │            │    │
│  │    │  201 Created      │                   │            │    │
│  │    │ <──────────────── │                   │            │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.5.2 Webhook配置

```yaml
# webhook.yaml

apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: myapp-mutating-webhook
webhooks:
  - name: myapp.example.com
    clientConfig:
      service:
        name: myapp-operator
        namespace: operators
        path: /mutate-myapp
      caBundle: <base64-encoded-ca>
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["example.com"]
        apiVersions: ["v1"]
        resources: ["myapps"]
    sideEffects: None
    timeoutSeconds: 10
    admissionReviewVersions: ["v1", "v1beta1"]
    failurePolicy: Fail

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: myapp-validating-webhook
webhooks:
  - name: myapp.example.com
    clientConfig:
      service:
        name: myapp-operator
        namespace: operators
        path: /validate-myapp
      caBundle: <base64-encoded-ca>
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["example.com"]
        apiVersions: ["v1"]
        resources: ["myapps"]
    sideEffects: None
    timeoutSeconds: 10
    admissionReviewVersions: ["v1", "v1beta1"]
    failurePolicy: Fail
```

---

## 1.6 实战：开发一个MySQL Operator

### 1.6.1 项目初始化

```bash
# 1. 安装kubebuilder
os=$(go env GOOS)
arch=$(go env GOARCH)
curl -L https://go.kubebuilder.io/dl/3.9.0/$os/$arch | tar -xz -C /tmp/
sudo mv /tmp/kubebuilder /usr/local/bin/
rm -rf /tmp/kubebuilder

# 2. 初始化项目
mkdir mysql-operator
cd mysql-operator
kubebuilder init --domain example.com --repo example.com/mysql-operator

# 3. 创建API
kubebuilder create api --group database --version v1 --kind MySQL

# 4. 定义MySQL类型
cat > api/v1/mysql_types.go << 'EOF'
package v1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type MySQLSpec struct {
    // Replicas MySQL实例数量
    Replicas int32 `json:"replicas,omitempty"`

    // Version MySQL版本
    Version string `json:"version"`

    // StorageSize 数据存储大小
    StorageSize string `json:"storageSize,omitempty"`

    // RootPassword Secret名称
    RootPassword string `json:"rootPassword,omitempty"`
}

type MySQLStatus struct {
    // ReadyReplicas 就绪实例数
    ReadyReplicas int32 `json:"readyReplicas,omitempty"`

    // Phase 当前状态
    Phase string `json:"phase,omitempty"`
}

type MySQL struct {
    metav1.TypeMeta   `json:",inline"`
    metav1.ObjectMeta `json:"metadata,omitempty"`

    Spec   MySQLSpec   `json:"spec,omitempty"`
    Status MySQLStatus `json:"status,omitempty"`
}

type MySQLList struct {
    metav1.TypeMeta `json:",inline"`
    metav1.ListMeta `json:"metadata,omitempty"`
    Items           []MySQL `json:"items"`
}
EOF

# 5. 生成代码
make generate
make manifests
```

### 1.6.2 Controller实现

```go
// controllers/mysql_controller.go

package controllers

import (
   "context"
    "fmt"

    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/util/intstr"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"

    databasev1 "example.com/mysql-operator/api/v1"
)

func (r *MySQLReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    logger := r.Log.WithValues("mysql", req.NamespacedName)

    // 获取MySQL资源
    mysql := &databasev1.MySQL{}
    if err := r.Get(ctx, req.NamespacedName, mysql); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 创建Service
    if err := r.reconcileService(ctx, mysql); err != nil {
        return ctrl.Result{}, err
    }

    // 创建StatefulSet
    if err := r.reconcileStatefulSet(ctx, mysql); err != nil {
        return ctrl.Result{}, err
    }

    // 更新状态
    if err := r.updateStatus(ctx, mysql); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
}

func (r *MySQLReconciler) reconcileService(ctx context.Context, mysql *databasev1.MySQL) error {
    svc := &corev1.Service{
        ObjectMeta: metav1.ObjectMeta{
            Name:      mysql.Name,
            Namespace: mysql.Namespace,
        },
    }

    // 创建Headless Service
    _, err := ctrl.CreateOrUpdate(ctx, r.Client, svc, func() error {
        svc.Spec.ClusterIP = corev1.ClusterIPNone
        svc.Spec.Ports = []corev1.ServicePort{
            {
                Name:     "mysql",
                Port:     3306,
                TargetPort: intstr.FromInt(3306),
            },
        }
        svc.Spec.Selector = map[string]string{
            "app": "mysql",
            "mysql": mysql.Name,
        }
        return ctrl.SetControllerReference(mysql, svc, r.Scheme)
    })

    return err
}

func (r *MySQLReconciler) reconcileStatefulSet(ctx context.Context, mysql *databasev1.MySQL) error {
    replicas := mysql.Spec.Replicas
    if replicas == 0 {
        replicas = 1
    }

    storageSize := mysql.Spec.StorageSize
    if storageSize == "" {
        storageSize = "10Gi"
    }

    version := mysql.Spec.Version
    if version == "" {
        version = "8.0"
    }

    ss := &appsv1.StatefulSet{
        ObjectMeta: metav1.ObjectMeta{
            Name:      mysql.Name,
            Namespace: mysql.Namespace,
        },
    }

    _, err := ctrl.CreateOrUpdate(ctx, r.Client, ss, func() error {
        ss.Spec.Replicas = &replicas
        ss.Spec.ServiceName = mysql.Name
        ss.Spec.Selector = &metav1.LabelSelector{
            MatchLabels: map[string]string{
                "app": "mysql",
                "mysql": mysql.Name,
            },
        }

        ss.Spec.Template.Labels = map[string]string{
            "app": "mysql",
            "mysql": mysql.Name,
        }

        ss.Spec.Template.Spec.Containers[0] = corev1.Container{
            Name:  "mysql",
            Image: fmt.Sprintf("mysql:%s", version),
            Ports: []corev1.ContainerPort{
                {Name: "mysql", ContainerPort: 3306},
            },
            Env: []corev1.EnvVar{
                {
                    Name: "MYSQL_ROOT_PASSWORD",
                    ValueFrom: &corev1.EnvVarSource{
                        SecretKeyRef: &corev1.SecretKeySelector{
                            LocalObjectReference: corev1.LocalObjectReference{
                                Name: mysql.Spec.RootPassword,
                            },
                            Key: "password",
                        },
                    },
                },
            },
        }

        ss.Spec.VolumeClaimTemplates = []corev1.PersistentVolumeClaim{
            {
                ObjectMeta: metav1.ObjectMeta{
                    Name: "data",
                },
                Spec: corev1.PersistentVolumeClaimSpec{
                    AccessModes: []corev1.PersistentVolumeAccessMode{
                        corev1.ReadWriteOnce,
                    },
                    Resources: corev1.ResourceRequirements{
                        Requests: corev1.ResourceList{
                            corev1.ResourceStorage: resource.MustParse(storageSize),
                        },
                    },
                },
            },
        }

        return ctrl.SetControllerReference(mysql, ss, r.Scheme)
    })

    return err
}
```

### 1.6.3 部署和验证

```bash
# 1. 构建镜像
make docker-build IMG=example.com/mysql-operator:v1.0.0

# 2. 推送镜像
make docker-push IMG=example.com/mysql-operator:v1.0.0

# 3. 部署Operator
make deploy IMG=example.com/mysql-operator:v1.0.0

# 4. 部署CRD
kubectl apply -f config/crd/bases/database.example.com_mysqls.yaml

# 5. 创建MySQL实例
cat > config/samples/database_v1_mysql.yaml << 'EOF'
apiVersion: database.example.com/v1
kind: MySQL
metadata:
  name: mysql-sample
spec:
  replicas: 3
  version: "8.0"
  storageSize: 20Gi
  rootPassword: mysql-secret
EOF

kubectl apply -f config/samples/database_v1_mysql.yaml

# 6. 验证部署
kubectl get MySQL
kubectl get StatefulSet
kubectl get Pod
kubectl get Service

# 7. 查看日志
kubectl logs -l app=mysql,mysql=mysql-sample

# 8. 扩容
kubectl scale MySQL mysql-sample --replicas=5

# 9. 查看状态
kubectl describe MySQL mysql-sample
```

---

## 1.7 最佳实践

### 1.7.1 Operator开发最佳实践

```
┌─────────────────────────────────────────────────────────────────┐
│                    Operator开发最佳实践                               │
└─────────────────────────────────────────────────────────────────┘

1. 错误处理
   ├── 使用client.IgnoreNotFound()处理NotFound错误
   ├── 使用requeueAfter进行延迟重试
   ├── 避免快速重试导致资源抖动
   └── 记录详细日志便于排查

2. 状态管理
   ├── Status只由Controller更新
   ├── 使用Conditions表示复杂状态
   ├── 避免在Status中存储敏感信息
   └── 使用Subresource更新Status

3. 资源管理
   ├── 使用Controller Reference设置拥有关系
   ├── 清理不再需要的子资源
   ├── 避免资源泄漏
   └── 使用Finalizer处理清理逻辑

4. 性能优化
   ├── 使用Informer减少API Server负载
   ├── 使用Indexer缓存常用资源
   ├── 批量处理减少API调用
   └── 使用Field Selector过滤

5. 安全性
   ├── 使用RBAC控制权限
   ├── 最小权限原则
   ├── 验证所有输入
   └── 使用Webhook进行验证
```

### 1.7.2 生产环境注意事项

```
┌─────────────────────────────────────────────────────────────────┐
│                    生产环境注意事项                                   │
└─────────────────────────────────────────────────────────────────┘

1. 高可用
   ├── Leader Election确保只有一个实例处理
   ├── 优雅关闭处理进行中的请求
   └── 健康检查确保存活

2. 监控
   ├── 暴露Prometheus指标
   ├── 记录关键事件到Events
   └── 使用Operator Lifecycle Manager

3. 升级
   ├── 支持CRD版本升级
   ├── 保持向后兼容
   ├── 使用Upgrade Strategy
   └── 灰度发布

4. 测试
   ├── 单元测试覆盖核心逻辑
   ├── 集成测试验证Controller
   ├── E2E测试验证完整流程
   └── 使用envtest进行测试

5. 文档
   ├── CRD文档说明
   ├── API说明
   ├── 示例和教程
   └── 迁移指南
```

---

## 1.8 本章小结

- Operator是Kubernetes的扩展机制，通过控制器模式自动化管理有状态应用
- CRD定义了新的资源类型，扩展Kubernetes API
- 控制器通过Reconcile循环保持期望状态与实际状态一致
- kubebuilder提供了Operator开发的完整框架
- Webhook用于验证和修改资源对象
- 生产环境Operator需要考虑高可用、监控、测试等

---

**下一章：深入ServiceMesh**
