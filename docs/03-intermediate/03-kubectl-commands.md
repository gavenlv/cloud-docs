# Kubernetes常用命令参考速查表

## 本速查表说明

本速查表整理了Kubernetes最常用的命令，按功能分类，方便快速查阅。所有命令都适配了Windows PowerShell环境。每个命令都包含详细参数说明，解释参数含义和为什么需要它。

---

## 目录

1. [kubectl配置](#1-kubectl配置)
2. [Pod命令](#2-pod命令)
3. [Deployment命令](#3-deployment命令)
4. [Service命令](#4-service命令)
5. [Ingress命令](#5-ingress命令)
6. [ConfigMap和Secret命令](#6-configmap和secret命令)
7. [持久化存储命令](#7-持久化存储命令)
8. [Namespace命令](#8-namespace命令)
9. [节点和集群命令](#9-节点和集群命令)
10. [Controller命令](#10-controller命令)
11. [调试和排错命令](#11-调试和排错命令)
12. [速查索引](#12-速查索引)

---

## 1. kubectl配置

### 1.1 集群连接配置

```powershell
# ============================================================
# 查看当前配置
# ============================================================
kubectl config view

# 参数说明:
# ├── --minify: 只显示当前上下文
# ├── --raw: 显示原始配置（含token）
# └── 显示所有上下文、当前上下文、集群信息


# ============================================================
# 列出所有上下文
# ============================================================
kubectl config get-contexts

# 参数说明:
# ├── -o name: 只显示上下文名称
# └── 显示：上下文名、集群、命名空间、认证信息


# ============================================================
# 切换上下文
# ============================================================
kubectl config use-context context-name

# 示例
kubectl config use-context production
kubectl config use-context minikube


# ============================================================
# 设置默认命名空间
# ============================================================
kubectl config set-context --current --namespace=namespace-name

# 示例
kubectl config set-context --current --namespace=default


# ============================================================
# 添加集群
# ============================================================
kubectl config set-cluster cluster-name `
    --server=https://kubernetes.io:6443 `
    --certificate-authority=/path/to/ca.crt

# 参数说明:
# ├── --server: API Server地址
# ├── --certificate-authority: CA证书路径
# ├── --embed-certs: 嵌入证书到配置
# └── --insecure-skip-tls-verify: 跳过TLS验证（不推荐）


# ============================================================
# 添加用户认证
# ============================================================
# 方式1: 客户端证书
kubectl config set-credentials user-name `
    --client-certificate=/path/to/cert.crt `
    --client-key=/path/to/key.key

# 方式2: Token
kubectl config set-credentials user-name --token=BearerToken

# 方式3: 用户名密码
kubectl config set-credentials user-name `
    --username=admin `
    --password=password


# ============================================================
# 创建上下文
# ============================================================
kubectl config set-context context-name `
    --cluster=cluster-name `
    --user=user-name `
    --namespace=namespace-name


# ============================================================
# 删除上下文/集群/用户
# ============================================================
kubectl config delete-context context-name
kubectl config delete-cluster cluster-name
kubectl config delete-credentials user-name
```

### 1.2 kubectl常用参数

```powershell
# ============================================================
# 常用全局参数
# ============================================================

# --namespace, -n: 指定命名空间
kubectl get pods -n kube-system

# --all-namespaces, -A: 查看所有命名空间
kubectl get pods -A

# --output, -o: 输出格式
kubectl get pods -o wide          # 宽格式
kubectl get pods -o yaml           # YAML格式
kubectl get pods -o json           # JSON格式
kubectl get pods -o name           # 只显示资源名
kubectl get pods -o jsonpath='{.items[*].metadata.name}'  # 自定义输出

# --label-selector, -l: 标签筛选
kubectl get pods -l app=web
kubectl get pods -l 'app in (web,api)'

# --field-selector: 字段筛选
kubectl get pods --field-selector status.phase=Running

# --watch, -w: 实时监控
kubectl get pods -w

# --sort-by: 排序
kubectl get pods --sort-by='.metadata.name'
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'

# --dry-run: 试运行
kubectl get pods --dry-run=client
kubectl get pods --dry-run=server

# --explain: 查看资源定义
kubectl explain pod
kubectl explain pod.spec.containers
```

---

## 2. Pod命令

### 2.1 创建Pod

```powershell
# ============================================================
# 从YAML创建Pod
# ============================================================
kubectl apply -f pod.yaml

# 参数说明:
# ├── -f, --filename: 文件路径（支持URL）
# ├── -k, --kustomize: kustomization目录
# ├── --dry-run: 试运行
# ├── --validate: 验证资源（默认true）
# └── --edit: 创建前编辑

# 示例
kubectl apply -f ./pod.yaml                  # 从文件
kubectl apply -f https://example.com/pod.yaml  # 从URL
kubectl apply -f ./dir/                        # 目录
kubectl apply -f pod.yaml --dry-run=client     # 试运行


# ============================================================
# 快速创建Pod（临时测试）
# ============================================================
kubectl run nginx --image=nginx

# 参数说明:
# ├── --image: 镜像名称
# ├── --restart: 重启策略（Always、OnFailure、Never）
# ├── --dry-run: 试运行
# ├── -o: 输出格式
# ├── --env: 环境变量
# ├── --port: 端口
# ├── --serviceaccount: 服务账号
# └── --command: 覆盖默认命令

# 示例
kubectl run nginx --image=nginx:latest                    # 基本
kubectl run nginx --image=nginx --port=80                # 指定端口
kubectl run nginx --image=nginx --env="ENV=prod"         # 环境变量
kubectl run nginx --image=nginx --command -- sh -c "..." # 自定义命令
kubectl run nginx --image=nginx --dry-run=client -o yaml # 生成YAML
```

### 2.2 查看Pod

```powershell
# ============================================================
# 查看Pod列表
# ============================================================
kubectl get pods

# 参数说明:
# ├── -o, --output: 输出格式（wide/yaml/json/name）
# ├── -w, --watch: 实时监控
# ├── -l, --selector: 标签选择
# ├── --field-selector: 字段选择
# ├── --no-headers: 不显示表头
# └── -A, --all-namespaces: 所有命名空间

# 示例
kubectl get pods                           # 当前命名空间
kubectl get pods -A                        # 所有命名空间
kubectl get pods -n kube-system           # 指定命名空间
kubectl get pods -o wide                  # 详细信息
kubectl get pods -o yaml                  # YAML输出
kubectl get pods -l app=web               # 标签筛选
kubectl get pods --field-selector=status.phase=Running  # 状态筛选


# ============================================================
# 查看Pod详情
# ============================================================
kubectl describe pod pod-name

# 参数说明:
# └── 显示：基本信息、事件、容器状态、资源限制等

# 示例
kubectl describe pod my-pod -n my-namespace


# ============================================================
# 查看Pod YAML
# ============================================================
kubectl get pod pod-name -o yaml

# 示例
kubectl get pod my-pod -o yaml --export


# ============================================================
# 查看Pod日志
# ============================================================
kubectl logs pod-name

# 参数说明:
# ├── -f, --follow: 实时跟踪日志
# ├── --previous: 查看上一个容器的日志
# ├── --since: 只显示指定时间后的日志
# ├── --tail: 显示最后N行
# ├── -c, --container: 指定容器（多容器时）
# ├── --timestamps: 显示时间戳
# └── --prefix: 每行添加前缀（容器名）

# 示例
kubectl logs my-pod                           # 基本日志
kubectl logs -f my-pod                        # 实时跟踪
kubectl logs --tail=100 my-pod               # 最后100行
kubectl logs --since=1h my-pod                # 最近1小时
kubectl logs -c sidecar my-pod               # 指定容器
kubectl logs --previous my-pod               # 上一个容器
kubectl logs -f my-pod -c main --prefix      # 带容器前缀


# ============================================================
# 查看所有容器的日志
# ============================================================
kubectl logs pod-name --all-containers=true

# 实时跟踪所有容器
kubectl logs pod-name -f --all-containers=true
```

### 2.3 管理Pod

```powershell
# ============================================================
# 删除Pod
# ============================================================
kubectl delete pod pod-name

# 参数说明:
# ├── -f, --filename: 文件路径
# ├── --force: 强制删除（立即删除）
# ├── --grace-period: 优雅终止期限（秒）
# ├── --now: 立即删除
# └── --cascade: 级联删除（默认true）

# 示例
kubectl delete pod my-pod                     # 正常删除
kubectl delete pod my-pod --grace-period=0   # 强制删除
kubectl delete pod my-pod --force            # 强制删除（立即）
kubectl delete -f ./pods.yaml                # 从文件删除
kubectl delete pods --all                    # 删除所有Pod


# ============================================================
# 编辑Pod
# ============================================================
kubectl edit pod pod-name

# 示例
kubectl edit pod my-pod


# ============================================================
# 替换Pod
# ============================================================
kubectl replace -f pod.yaml

# 强制替换（先删除再创建）
kubectl replace --force -f pod.yaml


# ============================================================
# 查看Pod正在执行的命令
# ============================================================
kubectl exec pod-name -- ps aux

# 示例
kubectl exec my-pod -- ls /app                    # 列出文件
kubectl exec -it my-pod -- /bin/sh               # 交互式Shell
kubectl exec -it my-pod -c sidecar -- /bin/sh    # 指定容器
kubectl exec my-pod -- cat /etc/config.conf      # 读取文件
```

### 2.4 Pod调试

```powershell
# ============================================================
# 端口转发
# ============================================================
kubectl port-forward pod-name local-port:pod-port

# 参数说明:
# ├── --address: 绑定地址（默认127.0.0.1）
# └── 格式: 本地端口:Pod端口

# 示例
kubectl port-forward pod-name 8080:80                    # 转发到本地8080
kubectl port-forward pod-name 8080:80 --address 0.0.0.0  # 允许外部访问
kubectl port-forward -n namespace pod-name 8080:80      # 指定命名空间


# ============================================================
# 复制文件
# ============================================================
kubectl cp pod-name:/path/in/pod /local/path

# 参数说明:
# ├── -c, --container: 指定容器
# └── 格式: pod:/path 或 pod:/path: -c container

# 示例
kubectl cp my-pod:/app/config.yaml ./config.yaml      # Pod到本地
kubectl cp ./local-file.txt my-pod:/app/file.txt     # 本地到Pod


# ============================================================
# 资源占用查看
# ============================================================
kubectl top pod

# 参数说明:
# ├── --containers: 显示容器资源
# ├── --no-headers: 不显示表头
# └── -l: 标签选择

# 示例
kubectl top pod                               # 查看资源
kubectl top pod my-pod                       # 查看指定Pod
kubectl top pod --containers                 # 显示容器


# ============================================================
# 等待Pod状态
# ============================================================
kubectl wait --for=jsonpath='{.status.phase}'=Running pod/my-pod

# 参数说明:
# ├── --for: 等待条件
# ├── --timeout: 超时时间
# ├── --recursive: 包含依赖资源
# └── 支持：jsonpath、delete、condition

# 示例
kubectl wait --for=condition=ready pod/my-pod --timeout=300s
kubectl wait --for=delete pod/my-pod --timeout=60s
```

---

## 3. Deployment命令

### 3.1 创建Deployment

```powershell
# ============================================================
# 快速创建Deployment
# ============================================================
kubectl create deployment my-app --image=nginx

# 参数说明:
# ├── --image: 容器镜像
# ├── --replicas: 副本数
# ├── --port: 容器端口
# ├── --env: 环境变量
# ├── --dry-run: 试运行
# ├── -o: 输出格式
# ├── --schedule: CronJob使用
# └── --/COMMAND: 自定义命令

# 示例
kubectl create deployment my-app --image=nginx               # 基本
kubectl create deployment my-app --image=nginx --replicas=3  # 3个副本
kubectl create deployment my-app --image=nginx --dry-run=client -o yaml  # 生成YAML


# ============================================================
# 从YAML创建Deployment
# ============================================================
kubectl apply -f deployment.yaml

# 示例
kubectl apply -f ./deployment.yaml
kubectl apply -f https://example.com/deploy.yaml


# ============================================================
# 扩缩容
# ============================================================
kubectl scale deployment my-app --replicas=5

# 参数说明:
# ├── --replicas: 目标副本数
# ├── --current-replicas: 当前副本数（条件触发）
# └── --timeout: 超时时间

# 示例
kubectl scale deployment my-app --replicas=3        # 缩放到3个
kubectl scale deployment my-app --replicas=0       # 缩放到0（暂停）
kubectl scale deployment my-app --current-replicas=3 --replicas=5  # 条件触发


# ============================================================
# 滚动更新
# ============================================================
kubectl set image deployment/my-app app=nginx:1.25

# 参数说明:
# ├── --image: 更新镜像
# ├── --record: 记录到注解（用于回滚）
# ├── --dry-run: 试运行
# └── 格式: deployment/名称 容器名=新镜像

# 示例
kubectl set image deployment/web nginx=nginx:1.25              # 更新镜像
kubectl set image deployment/web nginx=nginx:1.25 --record    # 记录变更
kubectl set image deployment/web nginx=nginx:1.25 -n namespace # 指定命名空间


# ============================================================
# 查看滚动更新状态
# ============================================================
kubectl rollout status deployment/my-app

# 参数说明:
# └── 等待滚动更新完成

# 示例
kubectl rollout status deployment/my-app -n namespace


# ============================================================
# 回滚
# ============================================================
kubectl rollout undo deployment/my-app

# 参数说明:
# ├── --to-revision: 回滚到指定版本
# └── --dry-run: 试运行

# 示例
kubectl rollout undo deployment/my-app                  # 回滚到上一版本
kubectl rollout undo deployment/my-app --to-revision=3  # 回滚到指定版本
kubectl rollout undo deployment/my-app -n namespace


# ============================================================
# 暂停/恢复 rollout
# ============================================================
kubectl rollout pause deployment/my-app
kubectl rollout resume deployment/my-app

# 暂停后可以批量修改，然后一起生效
kubectl rollout pause deployment/my-app
kubectl set image deployment/my-app nginx=nginx:1.26
kubectl set image deployment/my-app app=app:v2
kubectl rollout resume deployment/my-app
```

### 3.2 查看Deployment

```powershell
# ============================================================
# 查看Deployment列表
# ============================================================
kubectl get deployment

# 示例
kubectl get deployment                    # 当前命名空间
kubectl get deployment -A                 # 所有命名空间
kubectl get deployment -n namespace       # 指定命名空间
kubectl get deployment -o wide            # 详细信息


# ============================================================
# 查看Deployment详情
# ============================================================
kubectl describe deployment my-app

# 显示：
# - 基本信息
# - 标签选择器
# - 副本数（期望/当前/就绪）
# - 策略
# - 历史版本
# - 事件


# ============================================================
# 查看Deployment历史
# ============================================================
kubectl rollout history deployment/my-app

# 参数说明:
# ├── --revision: 查看指定版本详情
# └── 显示版本号、变更原因、时间

# 示例
kubectl rollout history deployment/my-app
kubectl rollout history deployment/my-app --revision=3
```

### 3.3 管理Deployment

```powershell
# ============================================================
# 删除Deployment
# ============================================================
kubectl delete deployment my-app

# 删除Deployment及所有Pod
kubectl delete deployment my-app --cascade=true


# ============================================================
# 编辑Deployment
# ============================================================
kubectl edit deployment my-app


# ============================================================
# 查看副本集
# ============================================================
kubectl get replicaset

# 示例
kubectl get rs                              # 列表
kubectl get replicaset -l app=web           # 标签筛选
kubectl describe replicaset my-app-xxxx    # 详情
```

---

## 4. Service命令

### 4.1 创建Service

```powershell
# ============================================================
# 快速创建Service
# ============================================================
kubectl expose deployment my-app --port=80 --target-port=8080

# 参数说明:
# ├── --port: Service端口
# ├── --target-port: 容器端口（默认同port）
# ├── --type: Service类型（ClusterIP/NodePort/LoadBalancer/ExternalName）
# ├── --protocol: 协议（TCP/UDP/SCTP）
# ├── --name: Service名称
# ├── --selector: 标签选择器
# ├── --cluster-ip: 指定ClusterIP
# ├── --external-ip: 外部IP
# ├── --load-balancer-ip: 负载均衡IP
# ├── --node-port: 节点端口
# └── --dry-run: 试运行

# 示例
kubectl expose deployment my-app --port=80 --target-port=8080                    # ClusterIP
kubectl expose deployment my-app --port=80 --type=NodePort                     # NodePort
kubectl expose deployment my-app --port=80 --type=LoadBalancer                 # LoadBalancer
kubectl expose deployment my-app --port=80 --type=ExternalName --external-name=my-db.example.com  # ExternalName


# ============================================================
# 从YAML创建Service
# ============================================================
kubectl apply -f service.yaml


# ============================================================
# 创建Service（详细配置）
# ============================================================
kubectl create service clusterip my-service `
    --tcp=8080:8080 `
    --tcp=9090:9090

# 参数说明:
# ├── clusterip: 类型
# ├── my-service: 名称
# └── --tcp=外部端口:内部端口


# ============================================================
# 创建NodePort Service
# ============================================================
kubectl create service nodeport my-service `
    --tcp=8080:8080 `
    --node-port=30080


# ============================================================
# 创建LoadBalancer Service
# ============================================================
kubectl create service loadbalancer my-service `
    --tcp=8080:8080
```

### 4.2 查看和管理Service

```powershell
# ============================================================
# 查看Service列表
# ============================================================
kubectl get service

# 示例
kubectl get svc                         # 简称
kubectl get service -A                 # 所有命名空间
kubectl get service -o wide            # 详细信息
kubectl get service -o yaml             # YAML输出


# ============================================================
# 查看Service详情
# ============================================================
kubectl describe service my-service

# 显示：
# - 端点（Pod IP）
# - 标签选择器
# - 端口映射
# - 类型
# - 集群IP


# ============================================================
# 查看端点
# ============================================================
kubectl get endpoints my-service

# 显示Service对应的所有Pod IP和端口


# ============================================================
# 删除Service
# ============================================================
kubectl delete service my-service
kubectl delete service -f service.yaml
```

---

## 5. Ingress命令

### 5.1 创建Ingress

```powershell
# ============================================================
# 创建Ingress
# ============================================================
kubectl create ingress my-ingress `
    --rule="example.com/*=my-service:80"

# 参数说明:
# ├── --rule: 路由规则（主机/路径=服务:端口）
# ├── --class: IngressClass名称
# ├── --annotation: 注解
# ├── --dry-run: 试运行
# └── -o: 输出格式

# 示例
kubectl create ingress my-ingress --rule="example.com/*=my-service:80"              # 基本
kubectl create ingress my-ingress --rule="example.com/api*=api-service:80"          # 带路径
kubectl create ingress my-ingress --rule="api.example.com/*=api-service:80"         # 带主机
kubectl create ingress my-ingress --class=nginx --rule="example.com/*=svc:80"       # 指定class
kubectl create ingress my-ingress --dry-run=client -o yaml                         # 生成YAML


# ============================================================
# 创建TLS Ingress
# ============================================================
kubectl create ingress my-ingress `
    --rule="example.com/*=my-service:80" `
    --tls="example.com=secret-name"


# ============================================================
# 从YAML创建Ingress
# ============================================================
kubectl apply -f ingress.yaml
```

### 5.2 管理Ingress

```powershell
# ============================================================
# 查看Ingress
# ============================================================
kubectl get ingress

# 示例
kubectl get ingress                       # 列表
kubectl get ingress -A                    # 所有命名空间
kubectl get ingress -o yaml              # YAML输出
kubectl describe ingress my-ingress      # 详情


# ============================================================
# 查看IngressClass
# ============================================================
kubectl get ingressclass

# 示例
kubectl get ingressclass
kubectl describe ingressclass nginx


# ============================================================
# 删除Ingress
# ============================================================
kubectl delete ingress my-ingress
```

---

## 6. ConfigMap和Secret命令

### 6.1 ConfigMap

```powershell
# ============================================================
# 创建ConfigMap
# ============================================================

# 方式1: 从文件
kubectl create configmap my-config --from-file=app.config

# 方式2: 从目录
kubectl create configmap my-config --from-file=./config/

# 方式3: 从环境变量文件
kubectl create configmap my-config --from-env-file=env.txt

# 方式4: 从字面值
kubectl create configmap my-config `
    --from-literal=key1=value1 `
    --from-literal=key2=value2

# 方式5: 从YAML
kubectl apply -f configmap.yaml

# 参数说明:
# ├── --from-file: 文件（key=文件名，value=文件内容）
# ├── --from-file: 目录（目录下所有文件）
# ├── --from-env-file: 环境变量文件
# ├── --from-literal: 键值对
# ├── --dry-run: 试运行
# └── -o: 输出格式

# 示例
kubectl create configmap app-config --from-literal=DB_HOST=mysql --from-literal=DB_PORT=3306
kubectl create configmap app-config --from-file=config.yaml
kubectl create configmap app-config --from-file=app.properties --from-literal=ENV=prod


# ============================================================
# 查看ConfigMap
# ============================================================
kubectl get configmap

# 示例
kubectl get configmap my-config                    # 获取
kubectl get configmap my-config -o yaml           # YAML格式
kubectl describe configmap my-config               # 详情


# ============================================================
# 删除ConfigMap
# ============================================================
kubectl delete configmap my-config
kubectl delete configmap my-config -n namespace
```

### 6.2 Secret

```powershell
# ============================================================
# 创建Secret
# ============================================================

# 方式1: 通用Secret（Opaque）
kubectl create secret generic my-secret `
    --from-literal=username=admin `
    --from-literal=password=secret123

# 方式2: TLS Secret
kubectl create secret tls my-tls-secret `
    --cert=path/to/cert.crt `
    --key=path/to/key.key

# 方式3: Docker Registry Secret
kubectl create secret docker-registry my-registry-secret `
    --docker-server=https://index.docker.io/v1/ `
    --docker-username=myuser `
    --docker-password=mypass `
    --docker-email=my@email.com

# 方式4: 从YAML
kubectl apply -f secret.yaml

# 参数说明:
# ├── generic: 通用Secret
# ├── tls: TLS证书Secret
# ├── docker-registry: Docker仓库Secret
# ├── --from-literal: 字面值
# ├── --from-file: 文件
# └── --from-cert-file/--from-key-file: 证书/密钥文件

# 示例
kubectl create secret generic db-credentials `
    --from-literal=username=admin `
    --from-literal=password=secret

kubectl create secret tls my-tls `
    --cert=tls.crt `
    --key=tls.key

kubectl create secret docker-registry my-registry `
    --docker-server=gcr.io `
    --docker-username=_json_key `
    --docker-password="$(cat key.json)"


# ============================================================
# 查看Secret
# ============================================================
kubectl get secret

# 示例
kubectl get secret my-secret                    # 获取
kubectl get secret my-secret -o yaml            # YAML（值是base64编码）
kubectl describe secret my-secret              # 详情（不显示值）


# ============================================================
# 解码Secret值
# ============================================================
kubectl get secret my-secret -o jsonpath='{.data.password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }


# ============================================================
# 删除Secret
# ============================================================
kubectl delete secret my-secret
```

---

## 7. 持久化存储命令

### 7.1 PV和PVC

```powershell
# ============================================================
# 创建PV
# ============================================================
kubectl apply -f pv.yaml

# YAML示例：
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: my-pv
# spec:
#   capacity:
#     storage: 10Gi
#   accessModes:
#     - ReadWriteOnce
#   storageClassName: standard
#   hostPath:
#     path: /mnt/data


# ============================================================
# 创建PVC
# ============================================================
kubectl apply -f pvc.yaml

# YAML示例：
# apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   name: my-pvc
# spec:
#   accessModes:
#     - ReadWriteOnce
#   resources:
#     requests:
#       storage: 5Gi
#   storageClassName: standard


# ============================================================
# 快速创建PVC
# ============================================================
kubectl create pvc my-pvc `
    --storage=5Gi `
    --class=standard `
    --access-modes=ReadWriteOnce


# ============================================================
# 查看PV和PVC
# ============================================================
kubectl get pv                    # 查看PV
kubectl get pvc                  # 查看PVC

# 示例
kubectl get pv my-pv              # 查看指定PV
kubectl get pvc my-pvc            # 查看指定PVC
kubectl get pvc -A                # 所有命名空间
kubectl describe pvc my-pvc       # PVC详情


# ============================================================
# 删除PV/PVC
# ============================================================
kubectl delete pv my-pv
kubectl delete pvc my-pvc
```

### 7.2 StorageClass

```powershell
# ============================================================
# 查看StorageClass
# ============================================================
kubectl get storageclass

# 示例
kubectl get storageclass
kubectl describe storageclass standard


# ============================================================
# 设置默认StorageClass
# ============================================================
kubectl patch storageclass standard -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## 8. Namespace命令

```powershell
# ============================================================
# 创建Namespace
# ============================================================
kubectl create namespace my-namespace

# 示例
kubectl create namespace production
kubectl create namespace my-app --dry-run=client -o yaml  # 生成YAML


# ============================================================
# 查看Namespace
# ============================================================
kubectl get namespace
kubectl get ns  # 简称

# 示例
kubectl get namespace
kubectl get ns -o wide
kubectl describe namespace kube-system


# ============================================================
# 设置默认Namespace
# ============================================================
kubectl config set-context --current --namespace=my-namespace


# ============================================================
# 删除Namespace
# ============================================================
kubectl delete namespace my-namespace

# 注意：删除命名空间会删除其下所有资源
```

---

## 9. 节点和集群命令

### 9.1 节点管理

```powershell
# ============================================================
# 查看节点
# ============================================================
kubectl get nodes

# 示例
kubectl get nodes                         # 列表
kubectl get nodes -o wide                # 详细信息
kubectl get nodes -o yaml                 # YAML输出
kubectl describe node node-name           # 节点详情


# ============================================================
# 查看节点资源
# ============================================================
kubectl top node

# 示例
kubectl top node                          # 所有节点
kubectl top node node-name                # 指定节点


# ============================================================
# 节点 cordon/uncordon（调度控制）
# ============================================================
kubectl cordon node-name                  # 禁止调度
kubectl uncordon node-name                # 允许调度

# 示例
kubectl cordon worker-1                  # 维护前标记
kubectl uncordon worker-1                 # 维护后恢复


# ============================================================
# 节点 drain（排空）
# ============================================================
kubectl drain node-name

# 参数说明:
# ├── --ignore-daemonsets: 忽略DaemonSet
# ├── --force: 强制删除非托管Pod
# ├── --delete-emptydir-data: 删除emptyDir数据
# ├── --timeout: 超时时间
# └── --skip-waiting-for-persistent-volumes: 跳过等待PV

# 示例
kubectl drain worker-1 --ignore-daemonsets --force
```

### 9.2 集群信息

```powershell
# ============================================================
# 集群信息
# ============================================================
kubectl cluster-info

# 显示API Server和Kubernetes Dashboard地址


# ============================================================
# 集群版本
# ============================================================
kubectl version

# 显示客户端和服务端版本


# ============================================================
# API资源
# ============================================================
kubectl api-resources

# 参数说明:
# ├── --namespaced: 是否命名空间级别
# ├── -o: 输出格式
# └── --verbs: 筛选动词

# 示例
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources -o wide


# ============================================================
# API详细
# ============================================================
kubectl api-versions
```

---

## 10. Controller命令

### 10.1 StatefulSet

```powershell
# ============================================================
# 创建StatefulSet
# ============================================================
kubectl apply -f statefulset.yaml

# 示例
kubectl create statefulset my-statefulset --image=nginx --dry-run=client -o yaml


# ============================================================
# 管理StatefulSet
# ============================================================
kubectl get statefulset
kubectl describe statefulset my-statefulset
kubectl delete statefulset my-statefulset

# 扩缩容
kubectl scale statefulset my-statefulset --replicas=3

# 删除Pod（会按顺序重建）
kubectl delete pod my-statefulset-0


# 查看PVC
kubectl get pvc -l app=my-statefulset
```

### 10.2 DaemonSet

```powershell
# ============================================================
# 创建DaemonSet
# ============================================================
kubectl apply -f daemonset.yaml

# 示例
kubectl create daemonset my-daemonset --image=fluentd --dry-run=client -o yaml


# ============================================================
# 管理DaemonSet
# ============================================================
kubectl get daemonset
kubectl describe daemonset my-daemonset
kubectl delete daemonset my-daemonset
kubectl rollout status daemonset my-daemonset
```

### 10.3 Job和CronJob

```powershell
# ============================================================
# 创建Job
# ============================================================
kubectl create job my-job --image=busybox -- /bin/sh -c "echo hello"

# 参数说明:
# ├── --image: 镜像
# ├── --from: 从CronJob创建
# ├── --dry-run: 试运行
# └── --schedule: CronJob使用

# 示例
kubectl create job my-job --image=my-app -- sh -c "./run.sh"
kubectl create job my-job --image=my-app --from=cronjob/my-cronjob


# ============================================================
# 创建CronJob
# ============================================================
kubectl create cronjob my-cronjob `
    --image=busybox `
    --schedule="*/5 * * * *" `
    -- /bin/sh -c "echo hello"

# 参数说明:
# ├── --schedule: Cron表达式
# ├── --image: 镜像
# ├── --restart: 重启策略
# └── --dry-run: 试运行

# 示例
kubectl create cronjob backup-job --image=my-backup --schedule="0 2 * * *" -- sh -c "./backup.sh"


# ============================================================
# 管理Job/CronJob
# ============================================================
kubectl get job
kubectl get cronjob
kubectl describe job my-job
kubectl describe cronjob my-cronjob
kubectl delete job my-job
kubectl delete cronjob my-cronjob

# 手动运行Job
kubectl create job my-job --from=cronjob/my-cronjob
```

---

## 11. 调试和排错命令

### 11.1 事件查看

```powershell
# ============================================================
# 查看事件
# ============================================================
kubectl get events

# 参数说明:
# ├── --field-selector: 字段选择
# ├── --sort-by: 排序
# ├── --watch: 实时监控
# └── -o: 输出格式

# 示例
kubectl get events                              # 所有事件
kubectl get events --sort-by='.lastTimestamp'   # 按时间排序
kubectl get events --field-selector involvedObject.name=my-pod  # 特定资源
kubectl get events -w                          # 实时监控
kubectl get events -n kube-system              # 系统组件
kubectl describe pod my-pod  # 查看Pod相关事件
```

### 11.2 资源占用

```powershell
# ============================================================
# 资源占用
# ============================================================
kubectl top nodes                              # 节点
kubectl top pods                               # Pods

# 示例
kubectl top pods -n namespace
kubectl top pods --containers
```

### 11.3 资源清理

```powershell
# ============================================================
# 清理资源
# ============================================================

# 删除所有Pod（保留Deployment）
kubectl delete pod --all -n namespace

# 删除所有资源
kubectl delete all --all -n namespace

# 删除已终止的Pod
kubectl get pods --field-selector=status.phase=Succeeded -o name | ForEach-Object { kubectl delete $_ }

# 删除Evicted的Pod
kubectl get pods --field-selector=status.phase==Evicted -o name | ForEach-Object { kubectl delete $_ }
```

### 11.4 Pod调试

```powershell
# ============================================================
# 调试Pod
# ============================================================

# 查看Pod详细信息
kubectl get pod my-pod -o yaml

# 查看资源定义
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers

# 验证YAML
kubectl apply -f pod.yaml --dry-run=client
kubectl apply -f pod.yaml --dry-run=server
```

---

## 12. 速查索引

### 快速查找

| 操作 | 命令 |
|------|------|
| 查看Pod | `kubectl get pods` |
| 查看详情 | `kubectl describe pod my-pod` |
| 查看日志 | `kubectl logs -f my-pod` |
| 进入Pod | `kubectl exec -it my-pod -- /bin/sh` |
| 端口转发 | `kubectl port-forward my-pod 8080:80` |
| 创建Deployment | `kubectl create deployment my-app --image=nginx` |
| 扩缩容 | `kubectl scale deployment my-app --replicas=5` |
| 更新镜像 | `kubectl set image deployment/my-app app=nginx:1.25` |
| 回滚 | `kubectl rollout undo deployment/my-app` |
| 创建Service | `kubectl expose deployment my-app --port=80` |
| 创建ConfigMap | `kubectl create configmap my-config --from-literal=key=value` |
| 创建Secret | `kubectl create secret generic my-secret --from-literal=key=value` |
| 创建Ingress | `kubectl create ingress my-ingress --rule="example.com/*=svc:80"` |
| 查看Service | `kubectl get svc` |
| 查看Node | `kubectl get nodes` |
| 切换Namespace | `kubectl config set-context --current --namespace=my-ns` |

### 常用参数速查

| 参数 | 含义 | 示例 |
|------|------|------|
| `-n`, `--namespace` | 指定命名空间 | `kubectl get pods -n kube-system` |
| `-A`, `--all-namespaces` | 所有命名空间 | `kubectl get pods -A` |
| `-o`, `--output` | 输出格式 | `kubectl get pods -o yaml` |
| `-l`, `--selector` | 标签选择 | `kubectl get pods -l app=web` |
| `-f`, `--filename` | 文件路径 | `kubectl apply -f pod.yaml` |
| `--dry-run` | 试运行 | `kubectl run nginx --dry-run=client -o yaml` |
| `-w`, `--watch` | 实时监控 | `kubectl get pods -w` |
| `--edit` | 编辑资源 | `kubectl edit deployment my-app` |
| `--force` | 强制删除 | `kubectl delete pod my-pod --force` |
| `--all` | 所有资源 | `kubectl delete pods --all` |

### YAML快速生成

```
# Deployment
kubectl create deployment my-app --image=nginx --dry-run=client -o yaml > deployment.yaml

# Service
kubectl expose deployment my-app --port=80 --target-port=8080 --dry-run=client -o yaml > service.yaml

# ConfigMap
kubectl create configmap my-config --from-literal=key=value --dry-run=client -o yaml > configmap.yaml

# Secret
kubectl create secret generic my-secret --from-literal=key=value --dry-run=client -o yaml > secret.yaml

# Pod
kubectl run my-pod --image=nginx --dry-run=client -o yaml > pod.yaml
```

---

*最后更新：2024*
