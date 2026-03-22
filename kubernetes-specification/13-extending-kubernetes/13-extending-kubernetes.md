# Kubernetes定制与扩展

## 本章导学

**学完本章后，你将能够：**

- 从**扩展机制**理解Kubernetes的架构设计哲学
- 从**API层**理解Kubernetes如何支持自定义资源
- 从**调度层**理解Kubernetes调度器的扩展方式
- 从**网络层**理解CNI接口和自定义网络方案
- 掌握Kubernetes集群定制和扩展的最佳实践

**学习方法：**

```
架构设计 → API扩展 → 调度扩展 → 网络扩展 → 存储扩展 → 实战定制
```

---

# Kubernetes扩展架构

## 1.1 Kubernetes扩展点概述

### 1.1.1 Kubernetes扩展架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes扩展架构全景                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         用户层                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  kubectl / Dashboard / SDK                                  │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         API层                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  CustomResourceDefinition (CRD)                            │ │
│  │  API Server Aggregation Layer                               │ │
│  │  Admission Webhooks                                         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      核心Kubernetes                               │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐       │
│  │ Controller│ │ Scheduler │ │  Kubelet  │ │  Kube-    │       │
│  │ Manager   │ │           │ │           │ │  Proxy    │       │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│     网络层     │   │     存储层     │   │     计算层     │
│   ┌─────────┐ │   │   ┌─────────┐ │   │   ┌─────────┐ │
│   │   CNI   │ │   │   │   CSI   │ │   │   │   CCM    │ │
│   └─────────┘ │   │   └─────────┘ │   │   └─────────┘ │
│   ┌─────────┐ │   │   ┌─────────┐ │   │   ┌─────────┐ │
│   │  CNM    │ │   │   │  Flex   │ │   │   │ Device  │ │
│   └─────────┘ │   │   └─────────┘ │   │   └─────────┘ │
└───────────────┘   └───────────────┘   └───────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes核心扩展点                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  1. API扩展层                                                    │
│     ├── CRD (Custom Resource Definition)                       │
│     ├── API Server Aggregation                                 │
│     └── Admission Webhooks                                     │
│                                                                  │
│  2. 调度扩展层                                                   │
│     ├── Scheduler Framework                                    │
│     ├── Predicates/Priorities                                 │
│     └── Volume Scheduling                                      │
│                                                                  │
│  3. 网络扩展层                                                   │
│     ├── CNI (Container Network Interface)                      │
│     ├── CNI Plugins                                            │
│     └── Network Policy                                         │
│                                                                  │
│  4. 存储扩展层                                                   │
│     ├── CSI (Container Storage Interface)                     │
│     ├── FlexVolume                                              │
│     └── Volume Plugins                                         │
│                                                                  │
│  5. 计算扩展层                                                   │
│     ├── CCM (Cloud Controller Manager)                        │
│     ├── Device Plugins                                          │
│     └── Runtime Service                                         │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1.2 扩展机制设计哲学

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes扩展设计原则                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  1. 声明式API优先                                                │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  用户声明期望状态                                          │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │ apiVersion: apps/v1                                 │ │   │
│  │  │ kind: Deployment                                    │ │   │
│  │  │ spec:                                               │ │   │
│  │  │   replicas: 3                                       │ │   │
│  │  │   selector: ...                                     │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  │                          │                                │   │
│  │                          ▼                                │   │
│  │              Kubernetes协调达到期望状态                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  2. 核心稳定，边缘扩展                                           │
│                                                                  │
│  核心API稳定 → 扩展点灵活                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │    核心API（Pod/Service/Deployment） → 稳定             │   │
│  │           │                                              │   │
│  │           ▼                                              │   │
│  │    扩展API（CRD/Aggregated API） → 灵活                 │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  3. 接口抽象                                                     │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                          │   │
│  │    ┌────────────────────────────────────────────────┐  │   │
│  │    │              CNI Interface                      │  │   │
│  │    │  func AddNetwork(net *NetworkConfig) error    │  │   │
│  │    │  func DelNetwork(net *NetworkConfig) error    │  │   │
│  │    └────────────────────────────────────────────────┘  │   │
│  │                          │                               │   │
│  │         ┌────────────────┼────────────────┐            │   │
│  │         ▼                ▼                ▼            │   │
│  │    ┌─────────┐      ┌─────────┐      ┌─────────┐    │   │
│  │    │ Calico  │      │ Flannel │      │  Cilium │    │   │
│  │    └─────────┘      └─────────┘      └─────────┘    │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.2 API层扩展

### 1.2.1 API Server Aggregation

```
┌─────────────────────────────────────────────────────────────────┐
│                    API Server Aggregation架构                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        kube-apiserver                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    API Server核心                          │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  /api/v1/* (核心资源)                               │  │  │
│  │  │  /apis/apps/v1/* (扩展资源)                         │  │  │
│  │  │  /apis/networking.k8s.io/v1/*                      │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                            │                               │  │
│  │                            ▼                               │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │         Aggregation Layer                           │  │  │
│  │  │  - 代理请求到扩展API Server                         │  │  │
│  │  │  - 认证/授权检查                                    │  │  │
│  │  │  - 请求转发                                          │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      kube-apiserver                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  Extended API Server                       │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  /apis/mycompany.com/v1/*                          │  │  │
│  │  │  - 自定义资源处理                                    │  │  │
│  │  │  - CRD处理                                          │  │  │
│  │  │  - 业务逻辑                                          │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    API Aggregation请求流程                        │
└─────────────────────────────────────────────────────────────────┘

Client                    kube-apiserver                  Extension API Server
  │                            │                                  │
  │  1. POST /apis/myco.com/v1/myresources                       │
  │ ───────────────────────────>│                                  │
  │                            │  2. 认证/授权检查                  │
  │                            │                                  │
  │                            │  3. 代理请求                      │
  │                            │ ────────────────────────────────>│
  │                            │                                  │
  │                            │  4. 业务处理                      │
  │                            │                                  │
  │                            │  5. 返回响应                      │
  │                            │ <───────────────────────────────│
  │  6. 201 Created            │                                  │
  │ <──────────────────────────│                                  │
```

### 1.2.2 APIService配置

```yaml
# apiservice.yaml - 配置扩展API Server

apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1.mycompany.example.com
spec:
  # 扩展API的service地址
  service:
    name: my-extension-api
    namespace: extension-system
    port: 443

  # API版本
  version: v1

  # 分组
  group: mycompany.example.com

  # 版本
  versionPriority: 100

  # 签名证书
  caBundle: <base64-encoded-ca>

  # 是否可用
  availablePriorities:
    - system-master

  # 签名算法
  insecureSkipTLSVerify: false
```

### 1.2.3 CRD vs Aggregated API

```
┌─────────────────────────────────────────────────────────────────┐
│                    CRD vs Aggregated API对比                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  CRD (Custom Resource Definition)                               │
├─────────────────────────────────────────────────────────────────┤
│  优点：                                                          │
│  ├── 无需编写API Server                                        │
│  ├── 声明式YAML即可创建资源                                     │
│  ├── Kubernetes原生体验                                         │
│  └── kubectl直接支持                                            │
│                                                                  │
│  缺点：                                                          │
│  ├── 功能有限（仅CRUD操作）                                     │
│  ├── 无自定义业务逻辑                                           │
│  └── 无法处理复杂验证                                           │
│                                                                  │
│  适用场景：                                                      │
│  ├── 简单的配置资源                                             │
│  ├── 声明式管理外部系统配置                                     │
│  └── 快速原型开发                                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Aggregated API                                                 │
├─────────────────────────────────────────────────────────────────┤
│  优点：                                                          │
│  ├── 完全自定义API行为                                          │
│  ├── 支持复杂业务逻辑                                           │
│  ├── 可自定义认证/授权                                          │
│  └── 可实现自定义子资源                                        │
│                                                                  │
│ 缺点：                                                           │
│  ├── 需要编写API Server                                         │
│  ├── 更高的开发复杂度                                           │
│  └── 需要维护额外组件                                           │
│                                                                  │
│  适用场景：                                                      │
│  ├── 需要复杂验证逻辑                                           │
│  ├── 需要与外部系统集成                                         │
│  ├── 需要实时处理大量数据                                       │
│  └── 需要高性能API                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1.3 调度器扩展

### 1.3.1 Scheduler Framework架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Scheduler Framework                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Scheduler调度流程                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. 队列阶段 (Queueing)                                          │
│     ┌─────────────────────────────────────────────────────┐      │
│     │  Pod被插入调度队列                                   │      │
│     │  - Priority Queue                                   │      │
│     │  - FIFO Queue                                       │      │
│     └─────────────────────────────────────────────────────┘      │
│                              │                                   │
│                              ▼                                   │
│  2. 过滤阶段 (Filtering)                                         │
│     ┌─────────────────────────────────────────────────────┐      │
│     │  过滤不满足条件的节点                               │      │
│     │  - PodFitsResources                                │      │
│     │  - PodFitsHostPorts                                │      │
│     │  - HostName                                        │      │
│     │  - VolumeZone                                      │      │
│     └─────────────────────────────────────────────────────┘      │
│                              │                                   │
│                              ▼                                   │
│  3. 评分阶段 (Scoring)                                           │
│     ┌─────────────────────────────────────────────────────┐      │
│     │  对通过的节点进行评分                               │      │
│     │  - LeastAllocated                                  │      │
│     │  - BalancedAllocation                             │      │
│     │  - ImageLocality                                  │      │
│     └─────────────────────────────────────────────────────┘      │
│                              │                                   │
│                              ▼                                   │
│  4. 绑定阶段 (Binding)                                           │
│     ┌─────────────────────────────────────────────────────┐      │
│     │  将Pod绑定到选中的节点                              │      │
│     │  - 创建Binding对象                                  │      │
│     │  - 更新Pod.spec.nodeName                           │      │
│     └─────────────────────────────────────────────────────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Scheduler Framework扩展点                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  type Plugin interface {                                        │
│      Name() string                                               │
│  }                                                              │
│                                                                  │
│  // Queue Sort Plugin - 决定Pod出队顺序                          │
│  type QueueSortPlugin interface {                                │
│      Plugin                                                      │
│      Less(pod1, pod2 *v1.Pod) bool                             │
│  }                                                              │
│                                                                  │
│  // Pre-filter Plugin - 预处理                                 │
│  type PreFilterPlugin interface {                               │
│      Plugin                                                      │
│      PreFilter(ctx context.Context, state *CycleState, p *v1.Pod) *Status │
│  }                                                              │
│                                                                  │
│  // Filter Plugin - 过滤节点                                    │
│  type FilterPlugin interface {                                   │
│      Plugin                                                      │
│      Filter(ctx context.Context, state *CycleState, p *v1.Pod, node *NodeInfo) *Status │
│  }                                                              │
│                                                                  │
│  // Post-filter Plugin - 过滤后处理                            │
│  type PostFilterPlugin interface {                               │
│      Plugin                                                      │
│      PostFilter(ctx context.Context, state *CycleState, p *v1.Pod, nodes []*NodeInfo, filteredNodeStatusMap NodeToStatusMap) (*PostFilterResult, *Status) │
│  }                                                              │
│                                                                  │
│  // Score Plugin - 评分                                        │
│  type ScorePlugin interface {                                    │
│      Plugin                                                      │
│      Score(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) (int64, *Status) │
│      ScoreExtensions() ScoreExtensions                           │
│  }                                                              │
│                                                                  │
│  // Reserve Plugin - 预留资源                                   │
│  type ReservePlugin interface {                                   │
│      Plugin                                                      │
│      Reserve(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) *Status │
│      Unreserve(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) │
│  }                                                              │
│                                                                  │
│  // Permit Plugin - 许可阶段                                    │
│  type PermitPlugin interface {                                   │
│      Plugin                                                      │
│      Permit(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) (*PermitResult, *Status) │
│  }                                                              │
│                                                                  │
│  // Pre-bind Plugin - 绑定前处理                               │
│  type PreBindPlugin interface {                                 │
│      Plugin                                                      │
│      PreBind(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) *Status │
│  }                                                              │
│                                                                  │
│  // Bind Plugin - 绑定                                         │
│  type BindPlugin interface {                                     │
│      Plugin                                                      │
│      Bind(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) *Status │
│  }                                                              │
│                                                                  │
│  // Post-bind Plugin - 绑定后处理                              │
│  type PostBindPlugin interface {                                 │
│      Plugin                                                      │
│      PostBind(ctx context.Context, state *CycleState, p *v1.Pod, nodeName string) │
│  }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3.2 自定义调度器实现

```go
// custom_scheduler.go - 自定义调度器插件

package scheduler

import (
    "context"
    "fmt"

    v1 "k8s.io/api/core/v1"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/klog/v2"
   framework "k8s.io/kubernetes/pkg/scheduler/framework"
)

type CustomSchedulerPlugin struct {
    runtime.Scheme
}

var _ framework.FilterPlugin = &CustomSchedulerPlugin{}
var _ framework.ScorePlugin = &CustomSchedulerPlugin{}

func (s *CustomSchedulerPlugin) Name() string {
    return "custom-scheduler"
}

// Filter - 过滤不满足条件的节点
func (s *CustomSchedulerPlugin) Filter(ctx context.Context, state *framework.CycleState, pod *v1.Pod, nodeInfo *framework.NodeInfo) *framework.Status {
    // 获取节点标签
    node := nodeInfo.Node()
    if node == nil {
        return framework.NewStatus(framework.Error, "node is nil")
    }

    // 检查节点是否有特定的GPU标签
    if pod.Spec.NodeSelector["gpu-required"] == "true" {
        if _, ok := node.Labels["gpu-type"]; !ok {
            klog.V(4).Infof("Node %s does not have GPU", node.Name)
            return framework.NewStatus(framework.Unschedulable, "node does not have GPU")
        }
    }

    // 检查节点是否在维护模式
    if node.Labels["maintenance-mode"] == "true" {
        return framework.NewStatus(framework.Unschedulable, "node is in maintenance mode")
    }

    return framework.NewStatus(framework.Success, "")
}

// Score - 评分节点
func (s *CustomSchedulerPlugin) Score(ctx context.Context, state *framework.CycleState, pod *v1.Pod, nodeName string) (int64, *framework.Status) {
    // 获取节点
    node, err := s.GetNode(ctx, nodeName)
    if err != nil {
        return 0, framework.NewStatus(framework.Error, err.Error())
    }

    // 基于资源使用率评分
    cpuPercent := float64(node.Status.Allocatable.Cpu().Value()) / float64(node.Status.Capacity.Cpu().Value())
    memPercent := float64(node.Status.Allocatable.Memory().Value()) / float64(node.Status.Capacity.Memory().Value())

    // 资源使用率越低，分数越高
    score := int64((1 - (cpuPercent + memPercent) / 2) * 100)

    return score, framework.NewStatus(framework.Success, "")
}

// ScoreExtensions - 返回评分扩展
func (s *CustomSchedulerPlugin) ScoreExtensions() framework.ScoreExtensions {
    return nil
}

func NewCustomSchedulerPlugin(_ runtime.Object, _ framework.Handle) (framework.Plugin, error) {
    return &CustomSchedulerPlugin{}, nil
}
```

### 1.3.3 调度器配置

```yaml
# scheduler-config.yaml - 调度器配置

apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: /etc/kubernetes/scheduler.conf

profiles:
  - schedulerName: default-scheduler
    plugins:
      multiPoint:
        enabled:
          - name: PrioritySort
          - name: NodeAffinity
          - name: TaintToleration
          - name: NodeResourcesFit
          - name: VolumeBinding
          - name: VolumeFiltering
        disabled:
          - name: "*"

      queueSort:
        enabled:
          - name: PrioritySort

      filter:
        enabled:
          - name: NodeUnschedulable
          - name: NodeResourcesFit
          - name: VolumeBinding
          - name: VolumeZoneFiltering
          - name: CustomSchedulerPlugin  # 自定义过滤插件

      scoring:
        enabled:
          - name: NodeResourcesFit
            weight: 1
          - name: BalancedAllocation
            weight: 1
          - name: CustomSchedulerPlugin  # 自定义评分插件
            weight: 2

    pluginConfig:
      - name: CustomSchedulerPlugin
        args:
          gpuLabel: gpu-type
          maintenanceLabel: maintenance-mode
```

---

## 1.4 网络扩展

### 1.4.1 CNI架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    CNI (Container Network Interface) 架构           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Kubelet网络管理流程                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Kubelet                                                       │
│    │                                                           │
│    │  1. 创建Pause容器（CNI Sandbox）                          │
│    │ ────────────────────────────────────────────────────────>│
│    │                                                           │
│    │  2. 调用CNI插件                                           │
│    │  ┌─────────────────────────────────────────────────────┐  │
│    │  │  CNI_ADD / CNI_DEL / CNI_CHECK                     │  │
│    │  └─────────────────────────────────────────────────────┘  │
│    │                          │                                │
│    │                          ▼                                │
│    │  ┌─────────────────────────────────────────────────────┐  │
│    │  │              CNI Plugin                             │  │
│    │  │  - flannel                                         │  │
│    │  │  - calico                                          │  │
│    │  │  - cilium                                          │  │
│    │  │  - weave                                           │  │
│    │  └─────────────────────────────────────────────────────┘  │
│    │                          │                                │
│    │                          ▼                                │
│    │  ┌─────────────────────────────────────────────────────┐  │
│    │  │            容器网络命名空间                          │  │
│    │  │  - 创建veth pair                                   │  │
│    │  │  - 分配IP地址                                      │  │
│    │  │  - 设置网络策略                                     │  │
│    │  └─────────────────────────────────────────────────────┘  │
│    │                                                           │
│    │  3. 配置网络                                             │
│    │ <───────────────────────────────────────────────────────│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CNI插件类型                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  1. Main插件 - 负责创建网络接口                                  │
│     ├── bridge - 网桥模式                                       │
│     ├── ipvlan - IPvLAN模式                                    │
│     ├── loopback - 回环设备                                     │
│     ├── macvlan - MACVLAN模式                                 │
│     ├── ptp - 点对点模式                                        │
│     └── vlan - VLAN模式                                         │
│                                                                  │
│  2. IPAM插件 - 负责IP地址分配                                   │
│     ├── host-local - 本地IPAM                                   │
│     ├── dhcp - DHCP分配                                        │
│     └── static - 静态IP                                         │
│                                                                  │
│  3. Meta插件 - 组合其他插件                                     │
│     ├── flannel - 组合bridge和host-local                      │
│     ├── calico - 集成BGP网络                                   │
│     └── cilium - eBPF驱动的网络                                │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4.2 CNI插件实现

```bash
#!/bin/bash
# my-cni-plugin.sh - 简单CNI插件实现

CNI_VERSION="0.4.0"
CNI_CONTAINERID=""
CNI_NETNS="/var/run/netns"
CNI_IFNAME="eth0"
CNI_PATH="/opt/cni/bin"

# CNI_ADD - 添加网络
cni_add() {
    CONTAINER_ID=$1
    NETNS=$2
    IFNAME=$3
    IP=$4
    GATEWAY=$5

    # 创建veth pair
    HOST_VETH="veth_${CONTAINER_ID:0:8}"
    ip link add $IFNAME type veth peer name $HOST_VETH

    # 将一端放到容器网络命名空间
    ip link set $IFNAME netns $NETNS

    # 在容器内配置
    ip netns exec $NETNS ip link set $IFNAME up
    ip netns exec $NETNS ip addr add $IP dev $IFNAME
    ip netns exec $NETNS ip route add default via $GATEWAY

    # 在主机端配置
    ip link set $HOST_VETH up

    echo "{
        \"cniVersion\": \"$CNI_VERSION\",
        \"interfaces\": [{
            \"name\": \"$IFNAME\",
            \"mac\": \"$(ip netns exec $NETNS cat /sys/class/net/$IFNAME/address)\"
        }],
        \"dns\": {
            \"nameservers\": [\"8.8.8.8\"]
        }
    }"
}

# CNI_DEL - 删除网络
cni_del() {
    CONTAINER_ID=$1
    NETNS=$2
    IFNAME=$3

    HOST_VETH="veth_${CONTAINER_ID:0:8}"

    ip link del $HOST_VETH 2>/dev/null || true
    ip netns exec $NETNS ip link del $IFNAME 2>/dev/null || true
}

# CNI_CHECK - 检查网络
cni_check() {
    CONTAINER_ID=$1
    NETNS=$2
    IFNAME=$3

    # 检查接口是否存在
    ip netns exec $NETNS ip link show $IFNAME >/dev/null 2>&1
    return $?
}

# 主入口
case $CNI_COMMAND in
    ADD)
        cni_add $CNI_CONTAINERID $CNI_NETNS $CNI_IFNAME $CNI_IP $CNI_GATEWAY
        ;;
    DEL)
        cni_del $CNI_CONTAINERID $CNI_NETNS $CNI_IFNAME
        ;;
    CHECK)
        cni_check $CNI_CONTAINERID $CNI_NETNS $CNI_IFNAME
        ;;
    VERSION)
        echo '{"cniVersion":"0.4.0"}'
        ;;
esac
```

### 1.4.3 CNI配置

```json
{
  "cniVersion": "0.4.0",
  "name": "my-cni-network",
  "type": "my-cni-plugin",
  "capabilities": {
    "portMappings": true,
    "dns": true,
    "network监察": true
  },
  "ipam": {
    "type": "host-local",
    "subnet": "10.244.0.0/16",
    "gateway": "10.244.0.1",
    "routes": [
      {
        "dst": "0.0.0.0/0",
        "gateway": "10.244.0.1"
      }
    ],
    "dataDir": "/var/lib/cni/networks"
  },
  "dns": {
    "nameservers": ["8.8.8.8", "8.8.4.4"],
    "domain": "cluster.local",
    "search": ["default.svc.cluster.local", "svc.cluster.local"]
  },
  "logLevel": "debug",
  "logFile": "/var/log/cni.log"
}
```

---

## 1.5 存储扩展

### 1.5.1 CSI架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    CSI (Container Storage Interface) 架构             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CSI组件架构                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│                    Kubernetes CSI系统                            │
│                                                                  │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐    │
│  │  CO (Container  │    │  CSI RPC    │      │  CSP (Container │  │
│  │   Orchestrator)│    │  Protocol   │      │   Storage    │   │
│  │               │    │             │      │   Provider)  │   │
│  │  - Kubelet    │    │  - Identity │      │              │    │
│  │  - External   │◄──►│  - Controller│◄───►│  - Driver    │    │
│  │    Provisioner│    │  - Node     │      │  - Plugin   │    │
│  └─────────────┘      └─────────────┘      └─────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CSI RPC接口                                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  // Identity Service - 插件身份                                 │
│  interface IdentityService {                                    │
│      GetPluginInfo() -> (info, error)                          │
│      GetPluginCapabilities() -> (caps, error)                  │
│      Probe() -> (ready, error)                                  │
│  }                                                              │
│                                                                  │
│  // Controller Service - 控制器服务                            │
│  interface ControllerService {                                  │
│      CreateVolume() -> (volume, error)                         │
│      DeleteVolume() -> (error)                                  │
│      ControllerPublishVolume() -> (publish, error)            │
│      ControllerUnpublishVolume() -> (error)                    │
│      CreateSnapshot() -> (snapshot, error)                     │
│      DeleteSnapshot() -> (error)                                │
│      ListVolumes() -> (volumes, error)                         │
│  }                                                              │
│                                                                  │
│  // Node Service - 节点服务                                     │
│  interface NodeService {                                        │
│      NodeStageVolume() -> (error)                               │
│      NodeUnstageVolume() -> (error)                            │
│      NodePublishVolume() -> (error)                             │
│      NodeUnpublishVolume() -> (error)                          │
│      NodeGetVolumeStats() -> (error)                            │
│      NodeExpandVolume() -> (error)                              │
│  }                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Volume生命周期                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. CreateVolume                                               │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  StorageClass ──> CSI Driver ──> 实际存储卷        │     │
│     │                                                     │     │
│     │  kubectl apply -f pvc.yaml                         │     │
│     └─────────────────────────────────────────────────────┘     │
│                              │                                   │
│                              ▼                                   │
│  2. ControllerPublish                                        │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  将卷Attach到节点                                    │     │
│     │                                                     │     │
│     │  - 初始化存储连接                                   │     │
│     │  - 记录Attach信息                                   │     │
│     └─────────────────────────────────────────────────────┘     │
│                              │                                   │
│                              ▼                                   │
│  3. NodeStage                                                │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  在节点上准备卷                                      │     │
│     │                                                     │     │
│     │  - 格式化                                           │     │
│     │  - 挂载到globalmount                                │     │
│     └─────────────────────────────────────────────────────┘     │
│                              │                                   │
│                              ▼                                   │
│  4. NodePublish                                              │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  将卷Mount到容器                                    │     │
│     │                                                     │     │
│     │  - Bind Mount到容器路径                            │     │
│     └─────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.5.2 CSI插件实现

```go
// csi-controller.go - CSI控制器服务实现

package csi

import (
    "context"
    "fmt"

    "github.com/container-storage-interface/spec/lib/go/csi"
    "google.golang.org/grpc"
)

type ControllerServer struct {
   driver *Driver
}

func (cs *ControllerServer) CreateVolume(ctx context.Context, req *csi.CreateVolumeRequest) (*csi.CreateVolumeResponse, error) {
    // 验证请求
    if err := validateCreateVolumeRequest(req); err != nil {
        return nil, err
    }

    // 获取参数
    name := req.Name
    capacity := req.CapacityRange.RequiredBytes

    // 创建卷
    volume, err := cs.driver.CreateVolume(ctx, name, capacity)
    if err != nil {
        return nil, err
    }

    return &csi.CreateVolumeResponse{
        Volume: &csi.Volume{
            Id:            volume.ID,
            CapacityBytes: capacity,
            VolumeContext: req.Parameters,
        },
    }, nil
}

func (cs *ControllerServer) DeleteVolume(ctx context.Context, req *csi.DeleteVolumeRequest) (*csi.DeleteVolumeResponse, error) {
    volumeID := req.VolumeId

    if err := cs.driver.DeleteVolume(ctx, volumeID); err != nil {
        return nil, err
    }

    return &csi.DeleteVolumeResponse{}, nil
}

func (cs *ControllerServer) ControllerPublishVolume(ctx context.Context, req *csi.ControllerPublishVolumeRequest) (*csi.ControllerPublishVolumeResponse, error) {
    volumeID := req.VolumeId
    nodeID := req.NodeId
    volumeCapability := req.VolumeCapability

    // 检查访问模式
    if volumeCapability.GetAccessMode().Mode != csi.VolumeCapability_AccessMode_SINGLE_NODE_WRITER {
        return nil, fmt.Errorf("access mode not supported")
    }

    // Attach卷到节点
    devicePath, err := cs.driver.AttachVolume(ctx, volumeID, nodeID)
    if err != nil {
        return nil, err
    }

    return &csi.ControllerPublishVolumeResponse{
        PublishContext: map[string]string{
            "devicePath": devicePath,
        },
    }, nil
}

func (cs *ControllerServer) ControllerUnpublishVolume(ctx context.Context, req *csi.ControllerUnpublishVolumeRequest) (*csi.ControllerUnpublishVolumeResponse, error) {
    volumeID := req.VolumeId
    nodeID := req.NodeId

    if err := cs.driver.DetachVolume(ctx, volumeID, nodeID); err != nil {
        return nil, err
    }

    return &csi.ControllerUnpublishVolumeResponse{}, nil
}

// NodeServer实现
type NodeServer struct {
    driver *Driver
}

func (ns *NodeServer) NodeStageVolume(ctx context.Context, req *csi.NodeStageVolumeRequest) (*csi.NodeStageVolumeResponse, error) {
    volumeID := req.VolumeId
    stagingTarget := req.StagingTargetPath
    volumeCapability := req.VolumeCapability

    // 格式化并挂载卷
    if err := ns.driver.MountVolume(ctx, volumeID, stagingTarget, volumeCapability); err != nil {
        return nil, err
    }

    return &csi.NodeStageVolumeResponse{}, nil
}

func (ns *NodeServer) NodeUnstageVolume(ctx context.Context, req *csi.NodeUnstageVolumeRequest) (*csi.NodeUnstageVolumeResponse, error) {
    volumeID := req.VolumeId
    stagingTarget := req.StagingTargetPath

    if err := ns.driver.UnmountVolume(ctx, volumeID, stagingTarget); err != nil {
        return nil, err
    }

    return &csi.NodeUnstageVolumeResponse{}, nil
}

func (ns *NodeServer) NodePublishVolume(ctx context.Context, req *csi.NodePublishVolumeRequest) (*csi.NodePublishVolumeResponse, error) {
    volumeID := req.VolumeId
    targetPath := req.TargetPath
    stagingTarget := req.StagingTargetPath

    // Bind mount到容器路径
    if err := ns.driver.BindMount(ctx, stagingTarget, targetPath); err != nil {
        return nil, err
    }

    return &csi.NodePublishVolumeResponse{}, nil
}
```

---

## 1.6 Kubelet扩展

### 1.6.1 Device Plugin架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Device Plugin架构                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Device Plugin工作流程                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Kubelet                               Device Plugin             │
│    │                                     │                       │
│    │  1. 注册设备插件                     │                       │
│    │ ───────────────────────────────────>│                       │
│    │                                     │                       │
│    │  2. 启动 gRPC服务                    │                       │
│    │ <───────────────────────────────────│                       │
│    │                                     │                       │
│    │  3. ListAndWatch - 定期上报设备     │                       │
│    │ <───────────────────────────────────│                       │
│    │                                     │                       │
│    │  4. Allocate - 分配设备给容器       │                       │
│    │ ───────────────────────────────────>│                       │
│    │                                     │                       │
│    │  5. 设备信息                        │                       │
│    │ <───────────────────────────────────│                       │
│    │                                     │                       │
│    │  6. 配置容器使用设备                 │                       │
│    │                                     │                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Device Plugin接口                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  // DevicePlugin接口                                            │
│  interface DevicePlugin {                                       │
│      // Start - 启动插件                                         │
│      Start() error                                              │
│                                                                  │
│      // Stop - 停止插件                                          │
│      Stop() error                                                │
│                                                                  │
│      // GetDevicePluginOptions - 获取选项                        │
│      GetDevicePluginOptions() *DevicePluginOptions              │
│  }                                                              │
│                                                                  │
│  // DeploymentService接口                                        │
│  interface DeploymentService {                                  │
│      // ListAndWatch - 定期上报设备列表                          │
│      ListAndWatch() error                                        │
│                                                                  │
│      // Allocate - 为容器分配设备                                │
│      Allocate(ctx context.Context, reqs []*AllocateRequest)      │
│                   (*[]AllocateResponse, error)                  │
│  }                                                              │
│                                                                  │
│  // 健康检查接口                                                 │
│  // 通过gRPC健康检查实现                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.6.2 Device Plugin实现

```go
// gpu-plugin.go - GPU Device Plugin实现

package plugin

import (
    "context"
    "fmt"
    "net"
    "path"
    "time"

    "google.golang.org/grpc"
    "k8s.io/klog/v2"
    "k8s.io/kubernetes/pkg/kubelet/apis/deviceplugin/v1beta1"
)

type GPUDevicePlugin struct {
    resourceName string
    socketPath   string
    server       *grpc.Server
    devices      []*v1beta1.Device
}

func NewGPUDevicePlugin() *GPUDevicePlugin {
    return &GPUDevicePlugin{
        resourceName: "nvidia.com/gpu",
        socketPath:   "/var/lib/kubelet/device-plugins/nvidia.sock",
        devices:      []*v1beta1.Device{},
    }
}

func (d *GPUDevicePlugin) Start() error {
    // 发现GPU设备
    if err := d.discoverGPUs(); err != nil {
        return err
    }

    // 创建gRPC服务器
    d.server = grpc.NewServer()

    // 注册服务
    v1beta1.RegisterDevicePluginServer(d.server, d)

    // 监听socket
    listener, err := net.Listen("unix", d.socketPath)
    if err != nil {
        return err
    }

    // 启动服务
    go d.server.Serve(listener)

    // 健康检查
    go d.healthCheck()

    klog.Info("GPU device plugin started")
    return nil
}

func (d *GPUDevicePlugin) ListAndWatch(e v1beta1.DevicePlugin_ListAndWatchServer) error {
    // 定期发送设备列表
    for {
        select {
        case <-e.Context().Done():
            return nil
        default:
            // 发送设备列表
            if err := e.Send(&v1beta1.ListAndWatchResponse{Devices: d.devices}); err != nil {
                return err
            }
            time.Sleep(10 * time.Second)
        }
    }
}

func (d *GPUDevicePlugin) Allocate(ctx context.Context, req *v1beta1.AllocateRequest) (*v1beta1.AllocateResponse, error) {
    responses := []*v1beta1.AllocateResponse{}

    for _, req := range req.ContainerRequests {
        // 选择一个GPU设备
        deviceID := d.allocateGPU()

        // 配置容器环境变量和挂载
        response := &v1beta1.AllocateResponse{
            ContainerResponses: []*v1beta1.ContainerAllocateResponse{
                {
                    Envs: map[string]string{
                        "NVIDIA_VISIBLE_DEVICES": deviceID,
                        "NVIDIA_DRIVER_CAPABILITIES": "all",
                    },
                    Mounts: []*v1beta1.Mount{
                        {
                            ContainerPath: "/usr/local/nvidia",
                            HostPath:      "/usr/local/nvidia",
                        },
                    },
                    Devices: []*v1beta1.DeviceSpec{
                        {
                            HostPath:      "/dev/nvidia0",
                            ContainerPath: "/dev/nvidia0",
                            Permissions:   "rwm",
                        },
                    },
                },
            },
        }
        responses = append(responses, response)
    }

    return &v1beta1.AllocateResponse{
        ContainerResponses: responses[0].ContainerResponses,
    }, nil
}

func (d *GPUDevicePlugin) discoverGPUs() error {
    // 扫描GPU设备
    // 实际实现中需要调用nvidia-smi或其他GPU工具
    d.devices = []*v1beta1.Device{
        {
            ID:     "GPU-0",
            Health: v1beta1.Healthy,
        },
        {
            ID:     "GPU-1",
            Health: v1beta1.Healthy,
        },
    }
    return nil
}

func (d *GPUDevicePlugin) allocateGPU() string {
    // 简单轮询分配
    if len(d.devices) > 0 {
        return d.devices[0].ID
    }
    return ""
}

func (d *GPUDevicePlugin) healthCheck() {
    ticker := time.NewTicker(30 * time.Second)
    defer ticker.Stop()

    for range ticker.C {
        d.checkDeviceHealth()
    }
}
```

---

## 1.7 实战：定制Kubernetes集群

### 1.7.1 自定义API资源

```yaml
# custom-resource.yaml - 定义自定义资源

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: metrics.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
  scope: Namespaced
  names:
    plural: metrics
    singular: metric
    kind: Metric
    shortNames:
      - met
  validation:
    openAPIV3Schema:
      type: object
      properties:
        spec:
          type: object
          properties:
            prometheus:
              type: string
            interval:
              type: string
            retention:
              type: string
        status:
          type: object
          properties:
            lastScrape:
              type: string
            condition:
              type: string
---
apiVersion: example.com/v1
kind: Metric
metadata:
  name: cluster-metrics
spec:
  prometheus: prometheus-operated
  interval: 30s
  retention: 15d
```

### 1.7.2 自定义调度器配置

```yaml
# custom-scheduler.yaml - 部署自定义调度器

apiVersion: v1
kind: ConfigMap
metadata:
  name: scheduler-config
  namespace: kube-system
data:
  scheduler-config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1
    kind: KubeSchedulerConfiguration
    profiles:
      - schedulerName: custom-scheduler
        plugins:
          filter:
            enabled:
              - name: CustomFilterPlugin
          scoring:
            enabled:
              - name: CustomScorePlugin
                weight: 2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-scheduler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      component: scheduler
      custom: "true"
  template:
    metadata:
      labels:
        component: scheduler
        custom: "true"
    spec:
      containers:
        - name: scheduler
          image: my-custom-scheduler:v1.0
          args:
            - --config=/etc/kubernetes/scheduler-config.yaml
          volumeMounts:
            - name: config
              mountPath: /etc/kubernetes/
      volumes:
        - name: config
          configMap:
            name: scheduler-config
```

### 1.7.3 自定义网络策略

```yaml
# network-policy.yaml - 应用网络策略

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend
        - namespaceSelector:
            matchLabels:
              name: production
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              role: database
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 53
        - protocol: UDP
          port: 53
```

---

## 1.8 本章小结

- Kubernetes采用声明式API和控制器模式，支持灵活扩展
- API层扩展包括CRD和Aggregated API两种方式
- 调度器扩展通过Scheduler Framework实现自定义调度策略
- 网络扩展通过CNI接口实现自定义网络方案
- 存储扩展通过CSI接口实现自定义存储方案
- Kubelet扩展包括Device Plugin等机制
- 生产环境定制需要考虑稳定性、安全性和可维护性

---

**附录：Kubernetes扩展资源**

- [Kubernetes API文档](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/)
- [Scheduler Framework文档](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)
- [CNI规范](https://github.com/containernetworking/cni)
- [CSI规范](https://github.com/container-storage-interface/spec)
