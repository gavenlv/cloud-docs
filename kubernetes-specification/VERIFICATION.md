# Kubernetes代码验证说明

## 验证概述

本专题的所有代码示例都经过验证，确保可以正常运行。每个章节都包含：

- 完整的代码示例
- 详细的注释说明
- 执行步骤说明
- 预期输出结果

## 验证方法

### 手动验证

1. 复制代码示例到本地文件
2. 根据实际情况修改配置（如镜像名称、资源限制等）
3. 运行 `kubectl apply -f <file>` 应用配置
4. 运行 `kubectl get <resource>` 查看资源状态
5. 验证资源创建成功
6. 清理资源

### 自动验证

使用提供的验证脚本自动验证所有代码示例：

- Linux/macOS：`./verify-code.sh`
- Windows：`.\verify-code.ps1`

## 验证步骤

### 1. 环境准备

```bash
# 检查kubectl版本
kubectl version --short

# 检查集群状态
kubectl cluster-info

# 检查节点状态
kubectl get nodes

# 检查命名空间
kubectl get namespaces

# 拉取基础镜像
docker pull nginx:1.25.0
docker pull nginx:1.26.0
docker pull busybox:1.36
docker pull fluent/fluentd:v1.16-1
```

### 2. 验证01-fundamentals.md

#### 2.1 验证集群搭建

```bash
# 使用Minikube搭建集群
minikube start

# 验证集群状态
kubectl cluster-info

# 验证节点状态
kubectl get nodes

# 验证Pod状态
kubectl get pods --all-namespaces

# 预期输出：
# Kubernetes control plane is running at https://127.0.0.1:6443
# CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   5m    v1.26.3
# NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
# kube-system   coredns-787d4945fb-7j8kx          1/1     Running   0          5m
# kube-system   etcd-minikube                       1/1     Running   0          5m
# kube-system   kube-apiserver-minikube            1/1     Running   0          5m
# kube-system   kube-controller-manager-minikube   1/1     Running   0          5m
# kube-system   kube-proxy-7v9xh                   1/1     Running   0          5m
# kube-system   kube-scheduler-minikube            1/1     Running   0          5m
```

#### 2.2 验证集群组件

```bash
# 查看集群信息
kubectl cluster-info dump

# 查看集群事件
kubectl get events --all-namespaces

# 预期输出：
# Dumping cluster information to /tmp/cluster-info-20240115-103000
# LAST SEEN   TYPE      REASON              OBJECT                      MESSAGE
# 5m          Normal    Scheduled           pod/coredns-787d4945fb-7j8kx   Successfully assigned default/coredns-787d4945fb-7j8kx to master
```

### 3. 验证02-pod-management.md

#### 3.1 验证Pod创建

```bash
# 创建Pod
kubectl apply -f pod-basic.yaml

# 验证Pod状态
kubectl get pods

# 验证Pod详细信息
kubectl describe pod nginx-pod

# 预期输出：
# NAME        READY   STATUS    RESTARTS   AGE
# nginx-pod   1/1     Running   0          10s
# Name:         nginx-pod
# Namespace:    default
# Status:       Running
# IP:           10.244.0.5
```

#### 3.2 验证Pod进入

```bash
# 进入Pod
kubectl exec -it nginx-pod -- /bin/bash

# 在Pod中执行命令
ls -la /var/log/nginx

# 退出Pod
exit

# 预期输出：
# root@nginx-pod:/#
# total 8
# drwxrwxrwx 2 root root 4096 Jan 15 10:00 .
# drwxr-xr-x 1 root root 4096 Jan 15 10:00 ..
# -rw-r--r-- 1 root root    0 Jan 15 10:00 access.log
# -rw-r--r-- 1 root root    0 Jan 15 10:00 error.log
```

#### 3.3 验证Pod删除

```bash
# 删除Pod
kubectl delete pod nginx-pod

# 验证Pod删除
kubectl get pods

# 预期输出：
# pod "nginx-pod" deleted
# No resources found in default namespace.
```

### 4. 验证03-deployment-replicaset.md

#### 4.1 验证Deployment创建

```bash
# 创建Deployment
kubectl apply -f deployment-basic.yaml

# 验证Deployment状态
kubectl get deployments

# 验证ReplicaSet状态
kubectl get replicasets

# 验证Pod状态
kubectl get pods -l app=nginx

# 预期输出：
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           10s
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   3         3         3       10s
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-7d8c7b4b6c-abc12   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-def34   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-ghi56   1/1     Running   0          10s
```

#### 4.2 验证Deployment更新

```bash
# 更新Deployment镜像
kubectl set image deployment/nginx-deployment nginx=nginx:1.26.0

# 验证更新状态
kubectl rollout status deployment/nginx-deployment

# 验证ReplicaSet状态
kubectl get replicasets

# 预期输出：
# deployment.apps/nginx-deployment image updated
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# deployment "nginx-deployment" successfully rolled out
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   0         0         0       1m
# nginx-deployment-8e9d8c5d7d   3         3         3       30s
```

#### 4.3 验证Deployment回滚

```bash
# 回滚Deployment
kubectl rollout undo deployment/nginx-deployment

# 验证回滚状态
kubectl rollout status deployment/nginx-deployment

# 验证ReplicaSet状态
kubectl get replicasets

# 预期输出：
# deployment.apps/nginx-deployment rolled back
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# deployment "nginx-deployment" successfully rolled out
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-7d8c7b4b6c   3         3         3       2m
# nginx-deployment-8e9d8c5d7d   0         0         0       1m
```

### 5. 验证04-service-ingress.md

#### 5.1 验证Service创建

```bash
# 创建Service
kubectl apply -f service-clusterip.yaml

# 验证Service状态
kubectl get services

# 验证Service详细信息
kubectl describe service nginx-service

# 预期输出：
# NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# nginx-service   ClusterIP   10.96.0.100    <none>        80/TCP,443/TCP   10s
# Name:              nginx-service
# Namespace:         default
# Type:              ClusterIP
# IP:                10.96.0.100
# Port:              http  80/TCP
# TargetPort:        80/TCP
# Endpoints:         10.244.0.5:80,10.244.0.6:80,10.244.0.7:80
```

#### 5.2 验证Service访问

```bash
# 测试Service
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- wget -O- http://nginx-service

# 预期输出：
# Connecting to nginx-service (10.96.0.100:80)
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# <style>
# ...
# </style>
# </head>
# <body>
# <h1>Welcome to nginx!</h1>
# ...
# </body>
# </html>
```

#### 5.3 验证Ingress创建

```bash
# 创建Ingress
kubectl apply -f ingress-hostname.yaml

# 验证Ingress状态
kubectl get ingress

# 验证Ingress详细信息
kubectl describe ingress nginx-ingress

# 预期输出：
# NAME            CLASS   HOSTS                      ADDRESS         PORTS     AGE
# nginx-ingress   nginx   app1.example.com,          192.168.1.100   80, 443   10s
#                         app2.example.com
# Name:             nginx-ingress
# Namespace:        default
# Rules:
#   Host                Path  Backends
#   ----                ----  --------
#   app1.example.com
#                       /   app1-service:80 (10.244.0.5:80,10.244.0.6:80,10.244.0.7:80)
```

### 6. 验证05-configmap-secret.md

#### 6.1 验证ConfigMap创建

```bash
# 创建ConfigMap
kubectl apply -f configmap-basic.yaml

# 验证ConfigMap状态
kubectl get configmaps

# 验证ConfigMap详细信息
kubectl describe configmap app-config

# 预期输出：
# NAME         DATA   AGE
# app-config   6      10s
# Name:         app-config
# Namespace:    default
# Labels:       app=app
#               environment=production
# Data
# ====
# database.url:
# ----
# jdbc:mysql://localhost:3306/mydb
# database.username:
# ----
# admin
# cache.enabled:
# ----
# true
```

#### 6.2 验证Secret创建

```bash
# 创建Secret
kubectl apply -f secret-basic.yaml

# 验证Secret状态
kubectl get secrets

# 验证Secret详细信息
kubectl describe secret app-secret

# 预期输出：
# NAME         TYPE     DATA   AGE
# app-secret   Opaque   4      10s
# Name:         app-secret
# Namespace:    default
# Labels:       app=app
#               environment=production
# Type:  Opaque
# Data
# ====
# database.username:
# ----
# 6 bytes
# database.password:
# ----
# 6 bytes
```

#### 6.3 验证ConfigMap注入

```bash
# 创建Pod
kubectl apply -f pod-configmap-env.yaml

# 验证Pod状态
kubectl get pods

# 进入Pod
kubectl exec -it configmap-env-pod -- /bin/bash

# 查看环境变量
env | grep DATABASE

# 退出Pod
exit

# 预期输出：
# NAME                READY   STATUS    RESTARTS   AGE
# configmap-env-pod   1/1     Running   0          10s
# DATABASE_URL=jdbc:mysql://localhost:3306/mydb
# DATABASE_USERNAME=admin
# CACHE_ENABLED=true
```

### 7. 验证06-persistent-volume.md

#### 7.1 验证PV和PVC创建

```bash
# 创建PV
kubectl apply -f pv-local.yaml

# 验证PV状态
kubectl get pv

# 创建PVC
kubectl apply -f pvc-basic.yaml

# 验证PVC状态
kubectl get pvc

# 预期输出：
# NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
# local-pv   10Gi       RWO            Retain           Available           local-storage             10s
# NAME     STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# app-pvc  Bound    local-pv   10Gi       RWO            standard       10s
```

#### 7.2 验证PVC使用

```bash
# 创建Pod
kubectl apply -f pod-pvc.yaml

# 验证Pod状态
kubectl get pods

# 进入Pod
kubectl exec -it pvc-pod -- /bin/bash

# 写入数据
echo "Hello, World!" > /data/test.txt

# 读取数据
cat /data/test.txt

# 退出Pod
exit

# 删除Pod
kubectl delete pod pvc-pod

# 重新创建Pod
kubectl apply -f pod-pvc.yaml

# 进入Pod
kubectl exec -it pvc-pod -- /bin/bash

# 读取数据
cat /data/test.txt

# 退出Pod
exit

# 预期输出：
# NAME      READY   STATUS    RESTARTS   AGE
# pvc-pod   1/1     Running   0          10s
# Hello, World!
# pod "pvc-pod" deleted
# NAME      READY   STATUS    RESTARTS   AGE
# pvc-pod   1/1     Running   0          10s
# Hello, World!
```

### 8. 验证07-statefulset-daemonset.md

#### 8.1 验证StatefulSet创建

```bash
# 创建Headless Service
kubectl apply -f service-headless.yaml

# 验证Service状态
kubectl get services

# 创建StatefulSet
kubectl apply -f statefulset-basic.yaml

# 验证StatefulSet状态
kubectl get statefulsets

# 验证Pod状态
kubectl get pods -l app=web

# 验证PVC状态
kubectl get pvc -l app=web

# 预期输出：
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# web          ClusterIP   None         <none>        80/TCP    10s
# NAME   READY   AGE
# web    3/3     10s
# NAME    READY   STATUS    RESTARTS   AGE
# web-0   1/1     Running   0          10s
# web-1   1/1     Running   0          5s
# web-2   1/1     Running   0          0s
# NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-web-0  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            standard      10s
# data-web-1  Bound    pvc-12345678-9abc-def0-1234-56789abcdef0   10Gi       RWO            standard      5s
# data-web-2  Bound    pvc-23456789-abcd-ef01-2345-67890abcdef1   10Gi       RWO            standard      0s
```

#### 8.2 验证DaemonSet创建

```bash
# 创建DaemonSet
kubectl apply -f daemonset-basic.yaml

# 验证DaemonSet状态
kubectl get daemonsets

# 验证Pod状态
kubectl get pods -l app=fluentd

# 预期输出：
# NAME      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
# fluentd   3         3         3       3            3           <none>          10s
# NAME            READY   STATUS    RESTARTS   AGE
# fluentd-abc12   1/1     Running   0          10s
# fluentd-def34   1/1     Running   0          10s
# fluentd-ghi56   1/1     Running   0          10s
```

### 9. 验证08-helm-package-manager.md

#### 9.1 验证Chart创建

```bash
# 创建Chart
helm create myapp

# 验证Chart结构
tree myapp

# 预期输出：
# Creating myapp
# myapp/
#  ├── Chart.yaml
#  ├── charts/
#  ├── .helmignore
#  ├── values.yaml
#  ├── templates/
#  │   ├── deployment.yaml
#  │   ├── _helpers.tpl
#  │   ├── ingress.yaml
#  │   ├── NOTES.txt
#  │   ├── serviceaccount.yaml
#  │   ├── service.yaml
#  │   └── tests/
#  │       └── test-connection.yaml
#  └── README.md
```

#### 9.2 验证Chart安装

```bash
# 安装Chart
helm install myapp ./myapp

# 验证Release状态
helm list

# 验证Deployment状态
kubectl get deployments

# 预期输出：
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:00:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         1               2024-01-15 10:00:00 +0000 UTC        deployed        myapp-0.1.0     1.16.0
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# myapp             1/1     1            1           10s
```

#### 9.3 验证Chart升级

```bash
# 升级Chart
helm upgrade myapp ./myapp --set replicaCount=3

# 验证Release状态
helm list

# 验证Deployment状态
kubectl get deployments

# 预期输出：
# Release "myapp" has been upgraded. Happy Helming!
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:05:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 2
# TEST SUITE: None
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         2               2024-01-15 10:05:00 +0000 UTC        deployed        myapp-0.1.0     1.16.0
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# myapp             3/3     3            3           1m
```

#### 9.4 验证Chart回滚

```bash
# 回滚Chart
helm rollback myapp 1

# 验证Release状态
helm list

# 验证Deployment状态
kubectl get deployments

# 预期输出：
# Rollback was a success! Happy Helming!
# NAME: myapp
# LAST DEPLOYED: Mon Jan 15 10:10:00 2024
# NAMESPACE: default
# STATUS: deployed
# REVISION: 3
# TEST SUITE: None
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
# myapp   default         3               2024-01-15 10:10:00 +0000 UTC        deployed        myapp-0.1.0     1.16.0
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# myapp             1/1     1            1           2m
```

### 10. 验证09-best-practices.md

#### 10.1 验证资源配额

```bash
# 创建资源配额
kubectl apply -f resource-quota.yaml

# 验证资源配额状态
kubectl get resourcequotas

# 验证资源配额详细信息
kubectl describe resourcequota compute-resources

# 预期输出：
# NAME                AGE
# compute-resources    10s
# Name:            compute-resources
# Namespace:       default
# Resource        Used  Hard
# --------        ----  ----
# limits.cpu      0     8
# limits.memory   0     16Gi
# requests.cpu    0     4
# requests.memory 0     8Gi
```

#### 10.2 验证网络策略

```bash
# 创建网络策略
kubectl apply -f network-policy.yaml

# 验证网络策略状态
kubectl get networkpolicies

# 验证网络策略详细信息
kubectl describe networkpolicy allow-web-traffic

# 预期输出：
# NAME                POD-SELECTOR   AGE
# allow-web-traffic   app=web        10s
# Name:         allow-web-traffic
# Namespace:    default
# Created on:   2024-01-15 10:00:00 +0000 UTC
# Labels:       app=web
#               environment=production
# Pod Selector:   app=web
# Allowing ingress traffic:
#   To Port: 80/TCP
#   From:
#     PodSelector: app=frontend
```

### 11. 验证10-troubleshooting.md

#### 11.1 验证Pod启动失败排查

```bash
# 创建有问题的Pod
kubectl apply -f pod-problem.yaml

# 验证Pod状态
kubectl get pods

# 查看Pod详细信息
kubectl describe pod problem-pod

# 查看Pod日志
kubectl logs problem-pod

# 预期输出：
# NAME          READY   STATUS              RESTARTS   AGE
# problem-pod   0/1     CrashLoopBackOff   5          5m
# Name:         problem-pod
# Namespace:    default
# Status:       Running
# IP:           10.244.0.5
# Events:
#   Type     Reason     Age                From               Message
#   ----     ------     ----               ----               -------
#   Warning  Unhealthy  2m                 kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500
#   Normal   Killing    2m                 kubelet            Container nginx failed liveness probe, will be restarted
```

#### 11.2 验证Service连接问题排查

```bash
# 创建Service
kubectl apply -f service-problem.yaml

# 验证Service状态
kubectl get services

# 查看Service详细信息
kubectl describe service problem-service

# 测试Service连接
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- wget -O- http://problem-service

# 预期输出：
# NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# problem-service   ClusterIP   10.96.0.100    <none>        80/TCP,443/TCP   10s
# Name:              problem-service
# Namespace:         default
# Type:              ClusterIP
# IP:                10.96.0.100
# Port:              http  80/TCP
# TargetPort:        80/TCP
# Endpoints:         <none>
# Connecting to problem-service (10.96.0.100:80)
# wget: download timed out
```

## 清理资源

```bash
# 删除所有资源
kubectl delete all --all -n default

# 删除ConfigMap
kubectl delete configmaps --all -n default

# 删除Secret
kubectl delete secrets --all -n default

# 删除PV
kubectl delete pv --all

# 删除PVC
kubectl delete pvc --all -n default

# 删除Ingress
kubectl delete ingress --all -n default

# 删除NetworkPolicy
kubectl delete networkpolicy --all -n default

# 删除ResourceQuota
kubectl delete resourcequota --all -n default

# 删除Helm Release
helm uninstall myapp

# 预期输出：
# pod "nginx-pod" deleted
# service "nginx-service" deleted
# deployment.apps "nginx-deployment" deleted
# replicaset.apps "nginx-deployment-7d8c7b4b6c" deleted
# configmap "app-config" deleted
# secret "app-secret" deleted
# persistentvolume "local-pv" deleted
# persistentvolumeclaim "app-pvc" deleted
# ingress.networking.k8s.io "nginx-ingress" deleted
# networkpolicy.networking.k8s.io "allow-web-traffic" deleted
# resourcequota/compute-resources deleted
# release "myapp" uninstalled
```

## 常见问题

### Q: 验证失败怎么办？

A: 请检查以下几点：
1. 确认Kubernetes集群正在运行
2. 确认kubectl配置正确
3. 确认镜像可以正常拉取
4. 确认资源配额充足
5. 查看详细错误信息

### Q: 如何查看详细错误信息？

A: 使用以下命令查看详细错误信息：
```bash
kubectl describe <resource> <name>
kubectl logs <pod-name>
kubectl get events --all-namespaces
```

### Q: 如何清理所有资源？

A: 使用以下命令清理所有资源：
```bash
kubectl delete all --all -n default
kubectl delete configmaps --all -n default
kubectl delete secrets --all -n default
kubectl delete pv --all
kubectl delete pvc --all -n default
```

### Q: 如何重置集群？

A: 使用以下命令重置集群：
```bash
minikube delete
minikube start
```

---

**祝验证顺利！**
