# kubectl命令详解

## 本章导学

**学完本章后，你将能够：**

- 从**命令分类**掌握kubectl所有常用命令
- 从**资源管理**熟练操作Kubernetes各种资源
- 从**调试技巧**快速定位和解决问题
- 从**输出格式化**获取所需的详细信息
- 从**实战场景**应对日常工作需求

**学习方法：**

```
基础命令 → 资源操作 → 调试排错 → 高效技巧 → 实战场景
```

---

# kubectl基础命令

## 1.1 kubectl概述

### 1.1.1 kubectl命令结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubectl命令结构                                    │
└─────────────────────────────────────────────────────────────────┘

kubectl [command] [TYPE] [NAME] [flags]

┌─────────────────────────────────────────────────────────────────┐
│  command: 操作命令                                               │
├─────────────────────────────────────────────────────────────────┤
│  get      - 查看资源列表                                          │
│  describe - 查看资源详细信息                                     │
│  create   - 创建资源                                             │
│  apply    - 应用配置文件                                         │
│  delete   - 删除资源                                             │
│  edit     - 编辑资源                                             │
│  exec     - 在容器中执行命令                                     │
│  logs     - 查看容器日志                                         │
│  port-forward - 端口转发                                        │
│  cp       - 文件拷贝                                              │
│  rollout  - 滚动更新管理                                         │
│  scale    - 扩缩容                                               │
│  top      - 资源使用情况                                          │
│  api-resources - 查看API资源                                     │
│  api-versions - 查看API版本                                      │
│  explain  - 查看资源定义                                         │
│  diff     - 查看配置差异                                         │
│  label    - 管理标签                                             │
│  annotate - 管理注解                                             │
│  completion - shell补全                                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TYPE: 资源类型                                                  │
├─────────────────────────────────────────────────────────────────┤
│  pods/pod/p          - Pod资源                                   │
│  deployments/deploy  - Deployment资源                           │
│  services/svc        - Service资源                              │
│  replicasets/rs      - ReplicaSet资源                           │
│  statefulsets/sts    - StatefulSet资源                          │
│  daemonsets/ds      - DaemonSet资源                            │
│  jobs                - Job资源                                   │
│  cronjobs/cj        - CronJob资源                               │
│  configmaps/cm       - ConfigMap资源                            │
│  secrets             - Secret资源                               │
│  persistentvolumes/pv - PV资源                                  │
│  persistentvolumeclaims/pvc - PVC资源                           │
│  namespaces/ns       - Namespace资源                            │
│  nodes/no            - Node资源                                  │
│  events/ev           - Event资源                                │
│  ingresses/ing      - Ingress资源                               │
│  networkpolicies/netpol - 网络策略                              │
│  serviceaccounts/sa - ServiceAccount资源                        │
│  clusterrolebindings - ClusterRoleBinding资源                   │
│  rolebindings        - RoleBinding资源                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  flags: 常用选项                                                 │
├─────────────────────────────────────────────────────────────────┤
│  -n, --namespace    - 指定命名空间                               │
│  -A, --all-namespaces - 所有命名空间                             │
│  -o, --output       - 输出格式                                   │
│  -l, --label        - 标签选择器                                 │
│  -f, --filename     - 配置文件                                   │
│  -k, --kustomize    - Kustomize目录                            │
│  --dry-run          - 试运行模式                                 │
│  -v, --v            - 日志级别                                   │
│  --help             - 帮助信息                                   │
│  --server           - API Server地址                           │
│  --kubeconfig       - kubeconfig路径                            │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1.2 输出格式

```
┌─────────────────────────────────────────────────────────────────┐
│                    kubectl输出格式详解                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  -o wide - 增加显示列                                            │
└─────────────────────────────────────────────────────────────────┘

# 基本输出
kubectl get pods
# NAME        READY   STATUS    RESTARTS   AGE
# myapp-pod   1/1     Running   0          10d

# 宽表输出（增加IP、节点等信息）
kubectl get pods -o wide
# NAME        READY   STATUS    RESTARTS   AGE   IP           NODE
# myapp-pod   1/1     Running   0          10d   10.244.1.5   node1

┌─────────────────────────────────────────────────────────────────┐
│  -o yaml - YAML格式输出                                          │
└─────────────────────────────────────────────────────────────────┘

kubectl get pod myapp-pod -o yaml
# apiVersion: v1
# kind: Pod
# metadata:
#   name: myapp-pod
#   namespace: default
# spec:
#   containers:
#   - name: myapp
#     image: nginx:latest
# status:
#   phase: Running

┌─────────────────────────────────────────────────────────────────┐
│  -o json - JSON格式输出                                          │
└─────────────────────────────────────────────────────────────────┘

kubectl get pod myapp-pod -o json | jq '.spec.containers[0].image'

┌─────────────────────────────────────────────────────────────────┐
│  -o custom-columns - 自定义列                                    │
└─────────────────────────────────────────────────────────────────┘

kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

┌─────────────────────────────────────────────────────────────────┐
│  -o jsonpath - JSONPath查询                                      │
└─────────────────────────────────────────────────────────────────┘

# 获取所有Pod的IP地址
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# 获取节点名称和容量
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\n"}{end}'
```

---

## 1.2 基础操作命令

### 1.2.1 集群信息

```bash
# 查看集群信息
kubectl cluster-info
# Kubernetes control plane is running at https://192.168.1.100:6443
# CoreDNS is running at https://192.168.1.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# 查看集群详细配置
kubectl cluster-info dump

# 查看API资源
kubectl api-resources
# NAME         SHORTNAMES   APIVERSION           NAMESPACED   KIND
# pods         p            v1                   true         Pod
# services     svc          v1                   true         Service
# deployments  deploy       apps/v1              true         Deployment
# ...

# 查看API版本
kubectl api-versions

# 查看可用的API组
kubectl api-groups
```

### 1.2.2 上下文和配置

```bash
# 查看所有上下文
kubectl config get-contexts
# CURRENT   NAME                    CLUSTER         AUTHINFO        NAMESPACE
# *         kubernetes-admin@k8s   k8s             kubernetes-admin default

# 切换上下文
kubectl config use-context context-name

# 查看当前上下文
kubectl config current-context

# 设置默认命名空间
kubectl config set-context --current --namespace=my-namespace

# 查看配置
kubectl config view

# 添加集群
kubectl config set-cluster cluster-name \
  --server=https://192.168.1.100:6443 \
  --certificate-authority=/path/to/ca.crt

# 添加用户
kubectl config set-credentials user-name \
  --client-certificate=/path/to/cert.crt \
  --client-key=/path/to/key.key

# 添加上下文
kubectl config set-context context-name \
  --cluster=cluster-name \
  --user=user-name \
  --namespace=default
```

### 1.2.3 帮助命令

```bash
# 查看命令帮助
kubectl --help

# 查看具体命令帮助
kubectl get --help
kubectl apply --help

# 查看资源定义
kubectl explain pods
kubectl explain deployment.spec

# 查看资源定义详情（递归）
kubectl explain pods --recursive
```

---

# Pod管理命令

## 2.1 Pod查看命令

### 2.1.1 获取Pod

```bash
# 获取所有Pod
kubectl get pods
kubectl get pods -A

# 获取指定命名空间的Pod
kubectl get pods -n namespace-name

# 获取Pod并显示详细信息
kubectl get pods -o wide

# 获取Pod的标签
kubectl get pods --show-labels
# NAME        READY   STATUS    AGE   LABELS
# myapp-pod   1/1     Running   10d   app=myapp,env=prod

# 按标签筛选Pod
kubectl get pods -l app=myapp
kubectl get pods -l 'app in (myapp, frontend)'
kubectl get pods -l app!=myapp

# 获取特定状态的Pod
kubectl get pods --field-selector status.phase=Running
kubectl get pods --field-selector status.phase!=Running

# 获取Pod的特定字段
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# 实时监控Pod状态
kubectl get pods -w
kubectl get pods --watch

# 按创建时间排序
kubectl get pods --sort-by=.metadata.creationTimestamp

# 显示Pod数量统计
kubectl get pods -A --no-headers | wc -l
```

### 2.1.2 Pod详情

```bash
# 查看Pod详细信息
kubectl describe pod myapp-pod

# 查看Pod的YAML配置
kubectl get pod myapp-pod -o yaml

# 查看Pod的JSON格式
kubectl get pod myapp-pod -o json

# 查看Pod的日志
kubectl logs myapp-pod
kubectl logs myapp-pod -f                    # 实时跟踪
kubectl logs myapp-pod --previous            # 上一个容器的日志
kubectl logs myapp-pod -c container-name     # 指定容器

# 查看Pod中容器的详情
kubectl get pod myapp-pod -o jsonpath='{.spec.containers[*].name}'

# 查看Pod的事件
kubectl get events --field-selector involvedObject.name=myapp-pod

# 查看Pod的资源使用情况
kubectl top pod myapp-pod
kubectl top pod --containers
```

### 2.2 Pod操作命令

### 2.2.1 创建Pod

```bash
# 从YAML创建
kubectl apply -f pod.yaml
kubectl create -f pod.yaml

# 试运行（不实际创建）
kubectl apply -f pod.yaml --dry-run=client
kubectl apply -f pod.yaml --dry-run=server

# 从镜像直接创建（测试用）
kubectl run myapp-pod --image=nginx --dry-run=client -o yaml > pod.yaml

# 在指定命名空间创建
kubectl apply -f pod.yaml -n namespace-name

# 从stdin创建
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: nginx:latest
EOF
```

### 2.2.2 编辑Pod

```bash
# 编辑Pod配置
kubectl edit pod myapp-pod

# 修改Pod镜像
kubectl set image pod/myapp-pod myapp=nginx:1.21

# 修改Pod的标签
kubectl label pod myapp-pod env=prod

# 添加标签
kubectl label pod myapp-pod tier=frontend

# 删除标签
kubectl label pod myapp-pod env-

# 添加注解
kubectl annotate pod myapp-pod description="My app pod"

# 查看注解
kubectl annotate pod myapp-pod --list
```

### 2.2.3 删除Pod

```bash
# 删除Pod
kubectl delete pod myapp-pod

# 从YAML删除
kubectl delete -f pod.yaml

# 删除所有Pod
kubectl delete pods --all

# 按标签删除
kubectl delete pods -l app=myapp

# 强制删除（不等待）
kubectl delete pod myapp-pod --force --grace-period=0

# 删除已终止的Pod
kubectl delete pods --field-selector=status.phase=Failed
```

### 2.2.4 Pod调试

```bash
# 在Pod中执行命令
kubectl exec myapp-pod -- ls /app
kubectl exec myapp-pod -- cat /app/config.json

# 进入交互式终端
kubectl exec -it myapp-pod -- /bin/sh
kubectl exec -it myapp-pod -- /bin/bash
kubectl exec -it myapp-pod -c container-name -- /bin/bash

# 端口转发
kubectl port-forward myapp-pod 8080:80
kubectl port-forward myapp-pod 8080:80 -n namespace-name

# 复制文件
kubectl cp myapp-pod:/app/config.yaml ./config.yaml
kubectl cp ./config.yaml myapp-pod:/app/config.yaml

# 复制整个目录
kubectl cp myapp-pod:/app -c container-name ./app

# 复制时排除文件
kubectl cp myapp-pod:/app/./config.yaml ./config.yaml --exclude=.git
```

---

# Deployment管理命令

## 3.1 Deployment查看命令

### 3.1.1 获取Deployment

```bash
# 获取所有Deployment
kubectl get deployments
kubectl get deploy

# 获取指定命名空间的Deployment
kubectl get deployments -n namespace-name

# 获取Deployment并显示详细信息
kubectl get deployments -o wide

# 获取Deployment的标签
kubectl get deployments --show-labels

# 按命名空间筛选
kubectl get deployments -n namespace -l app=myapp

# 查看Deployment状态
kubectl get deployment myapp-deploy -o yaml
```

### 3.1.2 Deployment详情

```bash
# 查看Deployment详细信息
kubectl describe deployment myapp-deploy

# 查看Deployment的ReplicaSet
kubectl get rs -l app=myapp

# 查看Deployment的Events
kubectl get events --field-selector involvedObject.name=myapp-deploy

# 查看历史版本
kubectl rollout history deployment myapp-deploy

# 查看特定版本详情
kubectl rollout history deployment myapp-deploy --revision=2

# 查看Deployment状态
kubectl rollout status deployment myapp-deploy

# 查看每个Pod的镜像版本
kubectl get pods -l app=myapp -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

### 3.2 Deployment操作命令

### 3.2.1 创建Deployment

```bash
# 从YAML创建
kubectl apply -f deployment.yaml
kubectl create deployment myapp-deploy --image=nginx --replicas=3

# 从镜像创建（基础方式）
kubectl create deployment myapp-deploy \
  --image=nginx:latest \
  --replicas=3 \
  --port=80

# 使用特定配置创建
kubectl create deployment myapp-deploy \
  --image=nginx:latest \
  --replicas=3 \
  --env="ENV=prod" \
  --labels="app=myapp,tier=frontend"

# 试运行生成YAML
kubectl create deployment myapp-deploy --image=nginx --replicas=3 --dry-run=client -o yaml > deployment.yaml
```

### 3.2.2 扩缩容

```bash
# 扩缩容
kubectl scale deployment myapp-deploy --replicas=5

# 按当前副本数调整（扩缩容）
kubectl scale deployment myapp-deploy --current-replicas=3 --replicas=5

# 扩缩容多个Deployment
kubectl scale deployment myapp-deploy frontend-deploy --replicas=3

# HPA扩缩容（自动）
kubectl autoscale deployment myapp-deploy --min=2 --max=10 --cpu-percent=80

# 查看HPA
kubectl get hpa

# 删除HPA
kubectl delete hpa myapp-deploy
```

### 3.2.3 滚动更新

```bash
# 更新镜像
kubectl set image deployment/myapp-deploy myapp=nginx:1.21

# 查看滚动更新状态
kubectl rollout status deployment myapp-deploy

# 暂停滚动更新
kubectl rollout pause deployment myapp-deploy

# 恢复滚动更新
kubectl rollout resume deployment/myapp-deploy

# 查看历史
kubectl rollout history deployment myapp-deploy

# 回滚到上一版本
kubectl rollout undo deployment/myapp-deploy

# 回滚到指定版本
kubectl rollout undo deployment/myapp-deploy --to-revision=2

# 查看回滚状态
kubectl rollout status deployment myapp-deploy
```

### 3.2.4 编辑和删除

```bash
# 编辑Deployment
kubectl edit deployment myapp-deploy

# 更新Deployment配置
kubectl apply -f deployment.yaml

# 删除Deployment
kubectl delete deployment myapp-deploy

# 按标签删除
kubectl delete deployment -l app=myapp

# 从文件删除
kubectl delete -f deployment.yaml
```

---

# Service管理命令

## 4.1 Service查看命令

### 4.1.1 获取Service

```bash
# 获取所有Service
kubectl get services
kubectl get svc

# 获取指定命名空间的Service
kubectl get svc -n namespace-name

# 获取Service详细信息
kubectl get svc myapp-svc -o wide

# 获取Service的YAML
kubectl get svc myapp-svc -o yaml

# 查看Endpoints
kubectl get endpoints myapp-svc

# 查看所有Endpoints
kubectl get endpoints

# 查看Service选择器
kubectl get svc myapp-svc -o jsonpath='{.spec.selector}'
```

### 4.1.2 Service详情

```bash
# 查看Service详细信息
kubectl describe svc myapp-svc

# 查看Service的ClusterIP
kubectl get svc myapp-svc -o jsonpath='{.spec.clusterIP}'

# 查看Service的端口映射
kubectl get svc myapp-svc -o jsonpath='{.spec.ports}'

# 查看ExternalIPs
kubectl get svc -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.externalIPs}{"\n"}{end}'
```

### 4.2 Service操作命令

### 4.2.1 创建Service

```bash
# 从YAML创建
kubectl apply -f service.yaml

# 通过kubectl expose创建
kubectl expose deployment myapp-deploy --name=myapp-svc --port=80 --target-port=8080

# 创建ClusterIP类型Service
kubectl expose deployment myapp-deploy --name=myapp-svc --type=ClusterIP --port=80

# 创建NodePort类型Service
kubectl expose deployment myapp-deploy --name=myapp-svc --type=NodePort --port=80 --node-port=30080

# 创建LoadBalancer类型Service
kubectl expose deployment myapp-deploy --name=myapp-svc --type=LoadBalancer --port=80

# 创建Headless Service
kubectl expose deployment myapp-deploy --name=myapp-svc --cluster-ip=None --port=80

# 创建外部名称Service
kubectl create svc externalname --name=myapp-svc --external-name=myapp.example.com
```

### 4.2.2 编辑和删除

```bash
# 编辑Service
kubectl edit svc myapp-svc

# 修改Service类型
kubectl patch svc myapp-svc -p '{"spec":{"type":"LoadBalancer"}}'

# 添加标签
kubectl label svc myapp-svc tier=frontend

# 删除Service
kubectl delete svc myapp-svc

# 按标签删除
kubectl delete svc -l app=myapp
```

---

# Ingress管理命令

## 5.1 Ingress查看命令

### 5.1.1 获取Ingress

```bash
# 获取所有Ingress
kubectl get ingress
kubectl get ing

# 获取Ingress详细信息
kubectl get ingress myapp-ing -o wide

# 获取Ingress YAML
kubectl get ingress myapp-ing -o yaml

# 查看Ingress状态
kubectl describe ingress myapp-ing

# 查看TLS Secret
kubectl get secret tls-secret --namespace=default -o yaml
```

### 5.2 Ingress操作命令

### 5.2.1 创建Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ing
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-svc
            port:
              number: 80
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
```

```bash
# 创建Ingress
kubectl apply -f ingress.yaml

# 通过kubectl create创建（基础）
kubectl create ingress myapp-ing \
  --rule="myapp.example.com/*=myapp-svc:80"

# 创建带TLS的Ingress
kubectl create ingress myapp-ing \
  --rule="myapp.example.com/*=myapp-svc:80" \
  --tls="myapp.example.com=tls-secret"

# 创建带注解的Ingress
kubectl create ingress myapp-ing \
  --rule="myapp.example.com/*=myapp-svc:80" \
  --annotation="nginx.ingress.kubernetes.io/rewrite-target=/"
```

### 5.2.2 编辑和删除

```bash
# 编辑Ingress
kubectl edit ingress myapp-ing

# 修改Ingress规则
kubectl patch ingress myapp-ing -p '{"spec":{"rules":[{"host":"new.example.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"new-svc","port":{"number":80}}}}]}}]}}'

# 删除Ingress
kubectl delete ingress myapp-ing

# 按标签删除
kubectl delete ingress -l app=myapp
```

---

# ConfigMap和Secret命令

## 6.1 ConfigMap命令

### 6.1.1 获取ConfigMap

```bash
# 获取所有ConfigMap
kubectl get configmaps
kubectl get cm

# 获取指定ConfigMap
kubectl get configmap myapp-config -o yaml

# 查看ConfigMap内容
kubectl describe configmap myapp-config

# 列出所有ConfigMap的键
kubectl get configmap myapp-config -o jsonpath='{.data}'
```

### 6.1.2 创建ConfigMap

```bash
# 从YAML创建
kubectl apply -f configmap.yaml

# 从目录创建
kubectl create configmap myapp-config --from-file=/path/to/config/

# 从文件创建
kubectl create configmap myapp-config --from-file=config.json=/path/to/config.json

# 从环境变量创建
kubectl create configmap myapp-config --from-env-file=env.txt

# 从字面值创建
kubectl create configmap myapp-config \
  --from-literal=ENV=prod \
  --from-literal=LOG_LEVEL=info

# 试运行生成YAML
kubectl create configmap myapp-config --from-literal=key=value --dry-run=client -o yaml
```

### 6.1.3 使用ConfigMap

```bash
# 在Pod中使用ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: nginx
    env:
    - name: CONFIG_PATH
      valueFrom:
        configMapKeyRef:
          name: myapp-config
          key: config-path
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: myapp-config
EOF
```

## 6.2 Secret命令

### 6.2.1 获取Secret

```bash
# 获取所有Secret
kubectl get secrets

# 获取Secret类型
kubectl get secret myapp-secret -o yaml

# 查看Secret详情
kubectl describe secret myapp-secret

# 解码Secret值
kubectl get secret myapp-secret -o jsonpath='{.data.password}' | base64 --decode

# 列出Opaque类型Secret的键
kubectl get secret myapp-secret -o jsonpath='{.data}' | jq 'keys'
```

### 6.2.2 创建Secret

```bash
# 从YAML创建
kubectl apply -f secret.yaml

# 从文件创建（通用Secret）
kubectl create secret generic myapp-secret --from-file=/path/to/cert.pem --from-file=/path/to/key.pem

# 从字面值创建
kubectl create secret generic myapp-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# 创建TLS Secret
kubectl create secret tls myapp-tls \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key

# 创建Docker Registry Secret
kubectl create secret docker-registry myapp-registry \
  --docker-server=registry.example.com \
  --docker-username=admin \
  --docker-password=secret123 \
  --docker-email=admin@example.com

# 试运行生成YAML
kubectl create secret generic myapp-secret --from-literal=key=value --dry-run=client -o yaml
```

### 6.2.3 使用Secret

```bash
# 在Pod中使用Secret作为环境变量
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: nginx
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: myapp-secret
          key: password
EOF

# 使用imagePullSecrets
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  imagePullSecrets:
  - name: myapp-registry
  containers:
  - name: myapp
    image: registry.example.com/myapp:latest
EOF
```

---

# 存储管理命令

## 7.1 PV和PVC命令

### 7.1.1 获取PV和PVC

```bash
# 获取所有PV
kubectl get persistentvolumes
kubectl get pv

# 获取所有PVC
kubectl get persistentvolumeclaims
kubectl get pvc

# 获取指定命名空间的PVC
kubectl get pvc -n namespace-name

# 获取PV详情
kubectl describe pv my-pv

# 获取PVC详情
kubectl describe pvc my-pvc -n namespace-name

# 查看PV容量
kubectl get pv -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.capacity.storage}{"\n"}{end}'

# 查看PVC绑定状态
kubectl get pvc -o wide
# NAME        STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# my-pvc      Bound    my-pv    10Gi       RWO            standard       10d
```

### 7.1.2 创建PV和PVC

```bash
# 从YAML创建PV
kubectl apply -f pv.yaml

# 从YAML创建PVC
kubectl apply -f pvc.yaml

# 快速创建PVC
kubectl create pvc my-pvc \
  --storage-class-name=standard \
  --access-modes=ReadWriteOnce \
  --resources=requests.storage=10Gi

# 试运行
kubectl create pvc my-pvc --dry-run=client -o yaml
```

### 7.1.3 存储类命令

```bash
# 获取所有存储类
kubectl get storageclass
kubectl get sc

# 获取默认存储类
kubectl get storageclass -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}'

# 设置默认存储类
kubectl patch storageclass standard -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# 查看存储类详情
kubectl describe storageclass standard
```

---

# 集群管理命令

## 8.1 Node管理命令

### 8.1.1 获取Node

```bash
# 获取所有Node
kubectl get nodes
kubectl get no

# 获取Node详细信息
kubectl get nodes -o wide

# 查看Node标签
kubectl get nodes --show-labels

# 获取Node容量和可分配资源
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\t"}{.status.capacity.memory}{"\n"}{end}'

# 获取Node可分配资源
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.cpu}{"\t"}{.status.allocatable.memory}{"\n"}{end}'
```

### 8.1.2 Node详情和操作

```bash
# 查看Node详细信息
kubectl describe node node-name

# 查看Node状态
kubectl get node node-name -o yaml

# 查看Node资源使用
kubectl top node node-name

# 查看所有Node资源使用
kubectl top node

# 标记Node为不可调度
kubectl cordon node-name

# 解除Node不可调度
kubectl uncordon node-name

# 排除Node（相当于cordon + drain）
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data

# 强制排除
kubectl drain node-name --ignore-daemonsets --delete-emptydir-data --force

# 标签管理
kubectl label node node-name disk=ssd
kubectl label node node-name gpu=true
kubectl label node node-name node-role.kubernetes.io/worker=""
```

## 8.2 Namespace管理命令

### 8.2.1 Namespace操作

```bash
# 获取所有Namespace
kubectl get namespaces
kubectl get ns

# 获取指定Namespace
kubectl get ns namespace-name

# 创建Namespace
kubectl create namespace namespace-name

# 从YAML创建
kubectl apply -f namespace.yaml

# 查看Namespace详情
kubectl describe ns namespace-name

# 查看Namespace资源配额
kubectl describe ns namespace-name | grep -A 10 "ResourceQuota"

# 设置默认Namespace（临时）
kubectl config set-context --current --namespace=namespace-name

# 删除Namespace（会删除所有资源）
kubectl delete namespace namespace-name
```

## 8.3 资源配额和限制

```bash
# 获取资源配额
kubectl get resourcequota -n namespace-name
kubectl describe resourcequota -n namespace-name

# 获取LimitRange
kubectl get limitrange -n namespace-name
kubectl describe limitrange -n namespace-name

# 创建资源配额
kubectl create resourcequota my-quota \
  --hard=pods=10,cpu=20,memory=40Gi \
  -n namespace-name

# 创建LimitRange
kubectl create limitrange my-limits \
  --cpu-min=100m --cpu-max=2 \
  --memory-min=128Mi --memory-max=4Gi \
  -n namespace-name
```

---

# 调试和排错命令

## 9.1 事件查看

```bash
# 查看所有事件
kubectl get events
kubectl get ev

# 按命名空间查看事件
kubectl get events -n namespace-name

# 查看最近的事件
kubectl get events --sort-by='.lastTimestamp'

# 查看特定资源的事件
kubectl get events --field-selector involvedObject.name=myapp-pod

# 查看异常事件
kubectl get events --field-selector type=Warning

# 查看特定类型的事件
kubectl get events --field-selector type=Normal

# 实时监控事件
kubectl get events -w
```

## 9.2 资源诊断

```bash
# 检查资源是否存在
kubectl get pod myapp-pod

# 检查资源配额
kubectl describe resourcequota -n namespace-name

# 检查LimitRange
kubectl describe limitrange -n namespace-name

# 检查PV/PVC绑定状态
kubectl get pvc -n namespace-name

# 检查ServiceEndpoints
kubectl get endpoints myapp-svc

# 检查网络策略
kubectl get networkpolicy -n namespace-name

# 检查Pod调度状态
kubectl get pods -o wide | grep Pending
```

## 9.3 日志调试

```bash
# 查看Pod日志
kubectl logs myapp-pod

# 实时日志
kubectl logs -f myapp-pod

# 查看上一个容器的日志（容器重启后）
kubectl logs myapp-pod --previous

# 指定容器日志
kubectl logs myapp-pod -c container-name

# 查看多个Pod的日志
kubectl logs -l app=myapp

# 添加时间戳
kubectl logs myapp-pod -t

# 查看最近行数
kubectl logs myapp-pod --tail=100

# 使用stern查看多容器日志
stern myapp-pod --namespace=namespace-name

# 查看所有Pod日志
kubectl logs -l app=myapp --all-containers=true
```

## 9.4 网络调试

```bash
# 检查Service端口
kubectl get svc myapp-svc

# 检查Endpoints
kubectl get endpoints myapp-svc

# 检查网络策略
kubectl get networkpolicy -A

# 检查Ingress
kubectl get ing -A

# 端口连通性测试
kubectl run test --rm -it --image=busybox -- wget -qO- http://myapp-svc

# DNS调试
kubectl run dnsutils --rm -it --image=tutum/dnsutils -- nslookup myapp-svc.namespace.svc.cluster.local

# 网络策略测试
kubectl run test --rm -it --image=busybox -- /bin/sh
# 在容器内执行
# ping 10.244.1.5
# wget http://myapp-svc:80
```

## 9.5 性能调试

```bash
# 查看资源使用
kubectl top pod
kubectl top pod --containers

# 查看Node资源使用
kubectl top node

# 查看Pod资源限制
kubectl get pod myapp-pod -o jsonpath='{.spec.containers[*].resources}'

# 检查Pod QoS等级
kubectl get pod myapp-pod -o jsonpath='{.spec.qosClass}'

# 查看CPU/内存使用百分比
kubectl get pod -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[0].resources.requests.cpu,MEMORY:.spec.containers[0].resources.requests.memory
```

---

# 高级命令

## 10.1 diff和dry-run

```bash
# 查看配置差异
kubectl diff -f deployment.yaml

# 服务器端试运行
kubectl apply -f deployment.yaml --dry-run=server

# 客户端试运行
kubectl apply -f deployment.yaml --dry-run=client

# 生成标准YAML
kubectl apply -f deployment.yaml --dry-run=client -o yaml > deployment-standard.yaml

# 验证YAML语法
kubectl create --dry-run=client -f deployment.yaml

# 查看将要删除的资源
kubectl delete -f deployment.yaml --dry-run=client
```

## 10.2 标签和注解

```bash
# 添加标签
kubectl label pods myapp-pod env=prod

# 更新标签
kubectl label pods myapp-pod env=prod --overwrite

# 删除标签
kubectl label pods myapp-pod env-

# 按标签筛选
kubectl get pods -l env=prod
kubectl get pods -l 'env in (prod, dev)'
kubectl get pods -l 'env notin (test)'

# 添加注解
kubectl annotate pods myapp-pod description="Production pod"

# 查看注解
kubectl annotate pods myapp-pod --list

# 删除注解
kubectl annotate pods myapp-pod description-
```

## 10.3 资源清理

```bash
# 删除所有已终止的Pod
kubectl delete pods --field-selector=status.phase=Failed

# 删除所有未被使用的镜像
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.status.phase!="Running") | .metadata.name' | xargs -I {} kubectl delete pod {} -n {}

# 清理所有标记的Pod
kubectl delete pods -l cleanup=temp

# 批量删除
kubectl delete deployments,services,pods -l app=old-app

# 删除所有命名空间的资源
kubectl delete all --all -A

# 删除PVC（谨慎）
kubectl delete pvc --all -n namespace-name
```

## 10.4 资源转移

```bash
# 导出资源YAML
kubectl get deployment myapp-deploy -o yaml > deployment.yaml

# 导出所有资源
kubectl get all -o yaml > all-resources.yaml

# 导出特定标签的资源
kubectl get pods -l app=myapp -o yaml > pods.yaml

# 导出命名空间所有资源
kubectl get all -n namespace-name -o yaml > namespace-resources.yaml

# 迁移命名空间（需要先导出再导入）
kubectl get ns namespace-name -o yaml > ns.yaml
kubectl create -f ns.yaml
```

---

## 本章小结

- kubectl命令遵循统一结构：`kubectl [command] [TYPE] [NAME] [flags]`
- 输出格式可通过`-o`选项定制，支持yaml/json/wide/custom-columns/jsonpath
- Pod管理包括创建、查看、编辑、删除、调试等完整生命周期
- Deployment提供声明式的滚动更新和回滚机制
- Service、Ingress、ConfigMap、Secret等资源管理遵循类似模式
- 调试命令包括日志、事件、网络检测等
- 高级命令支持dry-run、diff、标签管理等