# Kubernetes专题

## 概述

本专题提供从基础到专家级的Kubernetes教程，涵盖Kubernetes的核心概念、底层原理、实战案例和最佳实践。每个章节都包含详细的代码示例、原理解释和验证步骤，帮助读者深入理解Kubernetes的工作原理。

## 目录结构

```
kubernetes-specification/
├── README.md                           # 本文件
├── 01-fundamentals.md                  # Kubernetes基础和核心原理
├── 02-pod-management.md                # Pod管理
├── 03-deployment-replicaset.md         # Deployment和ReplicaSet
├── 04-service-ingress.md               # Service和Ingress
├── 05-configmap-secret.md              # ConfigMap和Secret
├── 06-persistent-volume.md             # PersistentVolume和PersistentVolumeClaim
├── 07-statefulset-daemonset.md        # StatefulSet和DaemonSet
├── 08-helm-package-manager.md          # Helm包管理
├── 09-best-practices.md                # Kubernetes最佳实践
├── 10-troubleshooting.md              # Kubernetes常见错误处理
├── VERIFICATION.md                     # 代码验证说明
├── verify-code.ps1                     # Windows验证脚本
└── verify-code.sh                      # Linux/macOS验证脚本
```

## 章节内容

### 01. Kubernetes基础和核心原理

**内容概览：**
- Kubernetes架构和核心组件
- 控制平面和数据平面
- API Server原理
- etcd存储原理
- Scheduler调度原理
- Controller Manager原理
- Kubelet原理
- Kube-proxy原理
- 实战：搭建Kubernetes集群

**学习目标：**
- 理解Kubernetes的核心概念
- 掌握Kubernetes架构
- 了解控制平面组件
- 了解数据平面组件
- 学会搭建Kubernetes集群

**代码示例：**
- 使用Minikube搭建集群
- 使用kubeadm搭建集群
- 集群验证
- 节点管理

### 02. Pod管理

**内容概览：**
- Pod原理和生命周期
- Pod配置和调度
- Pod资源限制
- Pod健康检查
- Pod网络和存储
- 实战：部署Pod

**学习目标：**
- 理解Pod的核心概念
- 掌握Pod生命周期
- 学会Pod配置
- 了解Pod调度
- 掌握Pod资源管理

**代码示例：**
- 创建Pod
- Pod资源限制
- Pod健康检查
- Pod网络配置
- Pod存储配置

### 03. Deployment和ReplicaSet

**内容概览：**
- Deployment原理
- ReplicaSet原理
- 滚动更新
- 回滚策略
- 扩缩容
- 实战：部署应用

**学习目标：**
- 理解Deployment核心概念
- 掌握ReplicaSet原理
- 学会滚动更新
- 了解回滚策略
- 掌握扩缩容

**代码示例：**
- 创建Deployment
- 滚动更新
- 回滚Deployment
- 扩缩容
- 金丝雀发布

### 04. Service和Ingress

**内容概览：**
- Service原理
- Service类型
- Ingress原理
- Ingress Controller
- 负载均衡
- 实战：配置服务发现

**学习目标：**
- 理解Service核心概念
- 掌握Service类型
- 学会Ingress配置
- 了解负载均衡
- 掌握服务发现

**代码示例：**
- 创建Service
- 配置Ingress
- 负载均衡
- 服务发现
- 网络策略

### 05. ConfigMap和Secret

**内容概览：**
- ConfigMap原理
- Secret原理
- 配置管理
- 敏感数据管理
- 配置注入
- 实战：配置管理

**学习目标：**
- 理解ConfigMap核心概念
- 掌握Secret原理
- 学会配置管理
- 了解敏感数据管理
- 掌握配置注入

**代码示例：**
- 创建ConfigMap
- 创建Secret
- 配置注入
- 环境变量配置
- 配置文件挂载

### 06. PersistentVolume和PersistentVolumeClaim

**内容概览：**
- PersistentVolume原理
- PersistentVolumeClaim原理
- 存储类
- 动态供应
- 存储回收策略
- 实战：数据持久化

**学习目标：**
- 理解PersistentVolume核心概念
- 掌握PersistentVolumeClaim原理
- 学会存储类配置
- 了解动态供应
- 掌握存储管理

**代码示例：**
- 创建PersistentVolume
- 创建PersistentVolumeClaim
- 配置存储类
- 动态供应
- 数据持久化

### 07. StatefulSet和DaemonSet

**内容概览：**
- StatefulSet原理
- DaemonSet原理
- 有状态应用部署
- 守护进程部署
- 网络标识
- 实战：部署有状态应用

**学习目标：**
- 理解StatefulSet核心概念
- 掌握DaemonSet原理
- 学会有状态应用部署
- 了解守护进程部署
- 掌握网络标识

**代码示例：**
- 创建StatefulSet
- 创建DaemonSet
- 有状态应用部署
- 守护进程部署
- 网络标识配置

### 08. Helm包管理

**内容概览：**
- Helm原理
- Chart结构
- 模板引擎
- Values文件
- 依赖管理
- 实战：使用Helm部署应用

**学习目标：**
- 理解Helm核心概念
- 掌握Chart结构
- 学会模板引擎
- 了解Values文件
- 掌握依赖管理

**代码示例：**
- 创建Chart
- 编写模板
- 配置Values
- 安装Chart
- 升级和回滚

### 09. Kubernetes最佳实践

**内容概览：**
- 资源管理最佳实践
- 安全最佳实践
- 网络最佳实践
- 存储最佳实践
- 监控和日志
- CI/CD集成

**学习目标：**
- 掌握资源管理技巧
- 了解安全最佳实践
- 学会网络优化
- 掌握存储优化
- 了解监控和日志
- 学会CI/CD集成

**代码示例：**
- 资源配额
- 网络策略
- 存储策略
- 监控配置
- CI/CD流程

### 10. Kubernetes常见错误处理

**内容概览：**
- Pod启动失败
- 调度失败
- 网络连接问题
- 存储访问问题
- 集群问题
- 调试技巧

**学习目标：**
- 掌握常见错误处理方法
- 学会Pod启动失败排查
- 了解调度失败诊断
- 掌握网络问题解决
- 学会存储问题处理

**代码示例：**
- Pod启动失败处理
- 调度失败排查
- 网络问题诊断
- 存储问题解决
- 集群问题排查

## 学习路径

### 初级路径

1. 阅读 [01-fundamentals.md](./01-fundamentals.md)
2. 完成基础实战练习
3. 阅读 [02-pod-management.md](./02-pod-management.md)
4. 完成Pod管理练习

### 中级路径

1. 完成 [03-deployment-replicaset.md](./03-deployment-replicaset.md)
2. 掌握Deployment管理
3. 完成 [04-service-ingress.md](./04-service-ingress.md)
4. 实现服务发现

### 高级路径

1. 学习 [05-configmap-secret.md](./05-configmap-secret.md)
2. 掌握配置管理
3. 学习 [06-persistent-volume.md](./06-persistent-volume.md)
4. 实现数据持久化

### 专家路径

1. 深入学习 [07-statefulset-daemonset.md](./07-statefulset-daemonset.md)
2. 掌握有状态应用部署
3. 学习 [08-helm-package-manager.md](./08-helm-package-manager.md)
4. 掌握Helm包管理
5. 学习 [09-best-practices.md](./09-best-practices.md)
6. 实施最佳实践
7. 学习 [10-troubleshooting.md](./10-troubleshooting.md)
8. 掌握常见错误处理
9. 构建生产级Kubernetes应用
10. 集成CI/CD流程

## 前置要求

### 必备知识

- 基本的Linux命令行操作
- 基本的Docker知识
- 基本的容器化概念
- 基本的云计算概念

### 必备工具

- kubectl >= 1.24
- Docker >= 20.10
- Minikube 或 Kind（本地开发）
- Git
- 文本编辑器（VS Code推荐）

### 可选工具

- Helm >= 3.0
- k9s（集群管理）
- Lens（集群可视化）
- GitHub/GitLab账户（用于CI/CD）

## 快速开始

### 安装kubectl

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
# 从 https://kubernetes.io/docs/tasks/tools/ 下载安装程序
```

### 安装Minikube

```bash
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Windows
# 从 https://minikube.sigs.k8s.io/docs/start/ 下载安装程序
```

### 启动集群

```bash
# 启动Minikube集群
minikube start

# 验证集群状态
kubectl cluster-info

# 查看节点
kubectl get nodes

# 查看Pod
kubectl get pods --all-namespaces
```

### 部署第一个应用

```bash
# 创建Deployment
kubectl create deployment hello-world --image=nginx:latest

# 暴露服务
kubectl expose deployment hello-world --port=80 --type=NodePort

# 查看服务
kubectl get services

# 访问应用
minikube service hello-world

# 删除资源
kubectl delete deployment hello-world
kubectl delete service hello-world
```

## 代码验证

所有代码示例都经过验证，确保可以正常运行。每个章节都包含：

- 完整的代码示例
- 详细的注释说明
- 执行步骤说明
- 预期输出结果

### 验证步骤

1. 复制代码示例到本地文件
2. 根据实际情况修改配置（如镜像名称、资源限制等）
3. 运行 `kubectl apply -f <file>` 应用配置
4. 运行 `kubectl get <resource>` 查看资源状态
5. 验证资源创建成功
6. 清理资源

## 常见问题

### Q: 如何获取Kubernetes版本？

A: 运行 `kubectl version --short` 查看Kubernetes版本。

### Q: 如何查看集群状态？

A: 运行 `kubectl cluster-info` 查看集群信息，运行 `kubectl get nodes` 查看节点状态。

### Q: 如何查看Pod日志？

A: 运行 `kubectl logs <pod-name>` 查看Pod日志。

### Q: 如何进入Pod？

A: 运行 `kubectl exec -it <pod-name> -- /bin/bash` 进入Pod。

### Q: 如何处理Pod启动失败？

A: 首先查看Pod状态 `kubectl describe pod <pod-name>`，然后查看Pod日志 `kubectl logs <pod-name>`。详细信息请参考第10章。

### Q: 如何扩缩容Deployment？

A: 运行 `kubectl scale deployment <deployment-name> --replicas=<number>` 扩缩容Deployment。

## 贡献指南

欢迎贡献代码、提出建议或报告问题。请遵循以下步骤：

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

本专题采用MIT许可证。详情请参阅LICENSE文件。

## 联系方式

如有问题或建议，请通过以下方式联系：

- 提交Issue
- 发送邮件至：your.email@example.com

## 参考资料

- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [kubectl命令参考](https://kubernetes.io/docs/reference/generated/kubectl/)
- [Helm官方文档](https://helm.sh/docs/)
- [Kubernetes最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)

## 更新日志

### v1.0.0 (2024-01-15)

- 初始版本发布
- 包含10个完整章节
- 所有代码示例经过验证
- 提供详细的实战案例

---

**祝学习愉快！**
