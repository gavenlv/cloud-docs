# Kubernetes常见错误处理

## 10.1 Pod启动失败

### 10.1.1 Pod启动失败排查

```
Pod启动失败常见原因：

┌─────────────────────────────────────────────────────────────────┐
│  Pod启动失败排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. 镜像拉取失败

错误信息：
├── ImagePullBackOff
├── ErrImagePull
├── ErrImageNeverPull
└── Failed to pull image

常见原因：
├── 镜像不存在
├── 镜像标签错误
├── 镜像仓库不可访问
├── 镜像拉取凭证错误
└── 网络问题

解决方案：
# 检查镜像是否存在
kubectl describe pod <pod-name>

# 输出：
# Events:
#   Normal   Pulling    10s    kubelet            Pulling image "nginx:1.25.0"
#   Warning  Failed     5s     kubelet            Failed to pull image "nginx:1.25.0": rpc error: code = NotFound desc = failed to pull and unpack image "nginx:1.25.0": no match for platform in manifest sha256:01234567890abcdef

# 检查镜像标签
kubectl get pods <pod-name> -o jsonpath='{.spec.containers[*].image}'

# 输出：
# nginx:1.25.0

# 检查镜像仓库
docker pull nginx:1.25.0

# 输出：
# Error response from daemon: pull access denied for nginx, repository does not exist or may require 'docker login'

# 解决方案1：使用正确的镜像
kubectl set image deployment/<deployment-name> <container-name>=nginx:1.25.0

# 解决方案2：创建镜像拉取凭证
kubectl create secret docker-registry registry-secret \
  --docker-server=registry.example.com \
  --docker-username=admin \
  --docker-password=secret \
  --docker-email=admin@example.com

# 解决方案3：使用本地镜像
kubectl run test-pod --image=nginx:1.25.0 --image-pull-policy=Never

2. 容器启动失败

错误信息：
├── CrashLoopBackOff
├── Error
├── RunContainerError
└── ContainerCannotRun

常见原因：
├── 容器命令错误
├── 容器参数错误
├── 容器配置错误
├── 容器资源不足
└── 容器健康检查失败

解决方案：
# 检查容器日志
kubectl logs <pod-name>

# 输出：
# 2024/01/15 10:00:00 [error] 1#1: *1 directory index of "/var/www/html/" is forbidden

# 检查容器启动命令
kubectl describe pod <pod-name>

# 输出：
# Containers:
#   nginx:
#     Command:
#       - /bin/sh
#       - -c
#       - echo "Hello, World!"
#     Args:
#       - nginx
#       - -g
#       - daemon off;

# 解决方案1：修复容器启动命令
kubectl set image deployment/<deployment-name> <container-name>=nginx:1.25.0

# 解决方案2：增加资源限制
kubectl set resources deployment/<deployment-name> \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=100m,memory=128Mi

# 解决方案3：修复健康检查
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","livenessProbe":{"httpGet":{"path":"/","port":80},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5,"successThreshold":1,"failureThreshold":3}}]}}}}'

3. 资源不足

错误信息：
├── Insufficient cpu
├── Insufficient memory
├── Insufficient ephemeral-storage
└── Insufficient gpu

常见原因：
├── 节点资源不足
├── 节点资源预留
├── 资源配额限制
└── 资源限制配置

解决方案：
# 检查节点资源
kubectl describe node <node-name>

# 输出：
# Allocatable:
#   cpu:                2
#   ephemeral-storage:  123456789Ki
#   hugepages-2Mi:      0
#   memory:             4048228Ki
#   pods:               110
# Capacity:
#   cpu:                2
#   ephemeral-storage:  123456789Ki
#   hugepages-2Mi:      0
#   memory:             4048228Ki
#   pods:               110

# 检查Pod资源请求
kubectl describe pod <pod-name>

# 输出：
# Requests:
#   cpu:        100m
#   memory:     128Mi

# 解决方案1：增加节点资源
kubectl scale nodepool <nodepool-name> --replicas=<number>

# 解决方案2：减少Pod资源请求
kubectl set resources deployment/<deployment-name> \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=50m,memory=64Mi

# 解决方案3：使用节点亲和性
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-type","operator":"In","values":["high-performance"]}]}]}}}}}}}'
```

### 10.1.2 Pod调度失败

```
Pod调度失败排查：

┌─────────────────────────────────────────────────────────────────┐
│  Pod调度失败排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. 节点选择器不匹配

错误信息：
├── 0/1 nodes are available: 1 node(s) didn't match node selector
├── 0/1 nodes are available: 1 node(s) had taint {node-role.kubernetes.io/master: }, that the pod didn't tolerate
└── 0/1 nodes are available: 1 node(s) didn't have free ports for the requested pod ports

常见原因：
├── 节点标签不匹配
├── 节点污点不匹配
├── 节点端口不匹配
└── 节点资源不足

解决方案：
# 检查节点标签
kubectl get nodes --show-labels

# 输出：
# NAME     STATUS   ROLES           AGE   VERSION   LABELS
# master    Ready    control-plane   5m    v1.26.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=master,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane
# worker1   Ready    <none>          5m    v1.26.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker1,kubernetes.io/os=linux,zone=us-west-1a
# worker2   Ready    <none>          5m    v1.26.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker2,kubernetes.io/os=linux,zone=us-west-1b

# 检查Pod节点选择器
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeSelector}'

# 输出：
# {"disktype":"ssd","zone":"us-west-1a"}

# 解决方案1：添加节点标签
kubectl label node <node-name> disktype=ssd zone=us-west-1a

# 解决方案2：修改Pod节点选择器
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'

# 解决方案3：添加Pod容忍度
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Exists","effect":"NoSchedule"}]}}}}'

2. 资源不足

错误信息：
├── 0/3 nodes are available: 3 Insufficient cpu
├── 0/3 nodes are available: 3 Insufficient memory
├── 0/3 nodes are available: 3 Insufficient ephemeral-storage
└── 0/3 nodes are available: 3 Insufficient gpu

常见原因：
├── 节点CPU不足
├── 节点内存不足
├── 节点存储不足
├── 节点GPU不足
└── 资源配额限制

解决方案：
# 检查节点资源使用
kubectl top nodes

# 输出：
# NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# master    500m         25%     1024Mi          25%
# worker1   1800m        90%     4096Mi          100%
# worker2   1800m        90%     4096Mi          100%

# 检查Pod资源请求
kubectl describe pod <pod-name>

# 输出：
# Requests:
#   cpu:        100m
#   memory:     128Mi

# 解决方案1：增加节点资源
kubectl scale nodepool <nodepool-name> --replicas=<number>

# 解决方案2：减少Pod资源请求
kubectl set resources deployment/<deployment-name> \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=50m,memory=64Mi

# 解决方案3：使用节点亲和性
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"node-type","operator":"In","values":["high-performance"]}]}]}}}}}}'
```

---

## 10.2 网络连接问题

### 10.2.1 Service连接问题

```
Service连接问题排查：

┌─────────────────────────────────────────────────────────────────┐
│  Service连接问题排查                                    │
└─────────────────────────────────────────────────────────────────┘

1. Service无法访问

错误信息：
├── Connection refused
├── Connection timeout
├── No route to host
└── Host unreachable

常见原因：
├── Service不存在
├── Service端口错误
├── Service选择器错误
├── Pod未就绪
└── 网络策略限制

解决方案：
# 检查Service是否存在
kubectl get service <service-name>

# 输出：
# NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# nginx-service   ClusterIP   10.96.0.100    <none>        80/TCP,443/TCP   10s

# 检查Service端口
kubectl describe service <service-name>

# 输出：
# Port:              http  80/TCP
# TargetPort:        80/TCP
# Endpoints:         10.244.0.5:80,10.244.0.6:80,10.244.0.7:80

# 检查Service选择器
kubectl get service <service-name> -o jsonpath='{.spec.selector}'

# 输出：
# {"app":"nginx"}

# 检查Pod是否就绪
kubectl get pods -l app=nginx

# 输出：
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-7d8c7b4b6c-abc12   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-def34   1/1     Running   0          10s
# nginx-deployment-7d8c7b4b6c-ghi56   1/1     Running   0          10s

# 解决方案1：修复Service端口
kubectl patch service <service-name> -p '{"spec":{"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'

# 解决方案2：修复Service选择器
kubectl patch service <service-name> -p '{"spec":{"selector":{"app":"nginx"}}}'

# 解决方案3：检查网络策略
kubectl get networkpolicy -A

# 输出：
# NAME            POD-SELECTOR   AGE
# default-deny    <none>          10s
# allow-web-traffic   app=web     5s

2. Ingress无法访问

错误信息：
├── 502 Bad Gateway
├── 503 Service Unavailable
├── 504 Gateway Timeout
└── Connection refused

常见原因：
├── Ingress不存在
├── Ingress配置错误
├── Service不存在
├── Service端口错误
└── Ingress Controller问题

解决方案：
# 检查Ingress是否存在
kubectl get ingress <ingress-name>

# 输出：
# NAME            CLASS   HOSTS                      ADDRESS         PORTS     AGE
# nginx-ingress   nginx   app.example.com             192.168.1.100   80, 443   10s

# 检查Ingress配置
kubectl describe ingress <ingress-name>

# 输出：
# Rules:
#   Host                Path  Backends
#   ----                ----  --------
#   app.example.com
#                       /   app-service:80 (10.244.0.5:80,10.244.0.6:80,10.244.0.7:80)

# 检查Service是否存在
kubectl get service app-service

# 输出：
# NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
# app-service   ClusterIP   10.96.0.200    <none>        80/TCP    10s

# 检查Ingress Controller
kubectl get pods -n ingress-nginx

# 输出：
# NAME                                        READY   STATUS    RESTARTS   AGE
# ingress-nginx-controller-7d8c7b4b6c-abc12   1/1     Running   0          10s

# 解决方案1：修复Ingress配置
kubectl patch ingress <ingress-name> -p '{"spec":{"rules":[{"host":"app.example.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"app-service","port":{"number":80}}}}]}}]}}'

# 解决方案2：修复Service端口
kubectl patch service app-service -p '{"spec":{"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'

# 解决方案3：重启Ingress Controller
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
```

### 10.2.2 Pod间通信问题

```
Pod间通信问题排查：

┌─────────────────────────────────────────────────────────────────┐
│  Pod间通信问题排查                                      │
└─────────────────────────────────────────────────────────────────┘

1. Pod无法互相访问

错误信息：
├── Connection refused
├── Connection timeout
├── No route to host
└── Host unreachable

常见原因：
├── Pod IP错误
├── Pod端口错误
├── 网络策略限制
├── DNS解析失败
└── 网络插件问题

解决方案：
# 检查Pod IP
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'

# 输出：
# 10.244.0.5

# 检查Pod端口
kubectl describe pod <pod-name>

# 输出：
# Ports:
#   Name    Port     Protocol
#   ----    ----     --------
#   http    80/TCP   TCP

# 检查网络策略
kubectl get networkpolicy -A

# 输出：
# NAME            POD-SELECTOR   AGE
# default-deny    <none>          10s
# allow-web-traffic   app=web     5s

# 检查DNS解析
kubectl run test-pod --image=busybox:1.36 --rm -it --restart=Never -- nslookup <pod-name>.<namespace>.svc.cluster.local

# 输出：
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# 
# Name:      nginx-pod.default.svc.cluster.local
# Address 1: 10.244.0.5 nginx-pod.default.svc.cluster.local

# 解决方案1：修复Pod IP
kubectl delete pod <pod-name>

# 解决方案2：修复Pod端口
kubectl patch deployment <deployment-name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","ports":[{"containerPort":80,"protocol":"TCP"}]}]}}}}'

# 解决方案3：修复网络策略
kubectl patch networkpolicy <networkpolicy-name> -p '{"spec":{"podSelector":{"matchLabels":{"app":"nginx"}},"policyTypes":["Ingress","Egress"],"ingress":[{"from":[{"podSelector":{"matchLabels":{"app":"web"}}}],"ports":[{"protocol":"TCP","port":80}]}]}}'

# 解决方案4：修复DNS解析
kubectl rollout restart deployment coredns -n kube-system
```

---

## 10.3 存储访问问题

### 10.3.1 PVC绑定失败

```
PVC绑定失败排查：

┌─────────────────────────────────────────────────────────────────┐
│  PVC绑定失败排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. PVC无法绑定PV

错误信息：
├── PersistentVolumeClaim is not bound
├── no persistent volumes available for this claim
├── no matching volumes found
└── waiting for a volume to be created

常见原因：
├── PV不存在
├── PV容量不足
├── PV访问模式不匹配
├── PV存储类不匹配
└── PV状态错误

解决方案：
# 检查PVC状态
kubectl get pvc <pvc-name>

# 输出：
# NAME     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# app-pvc  Pending                                      standard      10s

# 检查PVC详细信息
kubectl describe pvc <pvc-name>

# 输出：
# Status:       Pending
# Capacity:     10Gi
# Access Modes: RWO
# StorageClass: standard
# Events:
#   Type     Reason              Age   From                         Message
#   ----     ------              ----  ----                         -------
#   Warning  ProvisioningFailed  10s    persistentvolume-controller  no persistent volumes available for this claim

# 检查PV是否存在
kubectl get pv

# 输出：
# NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
# local-pv   10Gi       RWO            Retain           Available           local-storage             10s

# 检查PV详细信息
kubectl describe pv <pv-name>

# 输出：
# Status:      Available
# Claim:
# Reclaim Policy:  Retain
# Access Modes:    RWO
# Capacity:      10Gi
# Storage Class:  local-storage

# 解决方案1：创建PV
kubectl apply -f pv-local.yaml

# 解决方案2：修改PVC存储类
kubectl patch pvc <pvc-name> -p '{"spec":{"storageClassName":"local-storage"}}'

# 解决方案3：修改PV访问模式
kubectl patch pv <pv-name> -p '{"spec":{"accessModes":["ReadWriteMany"]}}'

# 解决方案4：使用动态供应
kubectl patch pvc <pvc-name> -p '{"spec":{"storageClassName":"fast-ssd"}}'
```

### 10.3.2 存储挂载失败

```
存储挂载失败排查：

┌─────────────────────────────────────────────────────────────────┐
│  存储挂载失败排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. Pod无法挂载存储

错误信息：
├── MountVolume.SetUp failed for volume
├── Unable to attach or mount volumes
├── VolumeMounts are not ready
└── ContainerCreating

常见原因：
├── PVC未绑定
├── 存储类不存在
├── 存储驱动不支持
├── 节点存储不足
└── 存储权限错误

解决方案：
# 检查Pod状态
kubectl get pod <pod-name>

# 输出：
# NAME      READY   STATUS              RESTARTS   AGE
# pvc-pod   0/1     ContainerCreating   0          10s

# 检查Pod详细信息
kubectl describe pod <pod-name>

# 输出：
# Events:
#   Type     Reason       Age   From               Message
#   ----     ------       ----  ----               -------
#   Warning  FailedMount  10s    kubelet            MountVolume.SetUp failed for volume "app-data" : rpc error: code = Internal desc = Could not mount target "/var/lib/kubelet/pods/01234567-89ab-cdef-0123-456789abcdef/volumes/kubernetes.io~empty-dir/app-data": exit status 32

# 检查PVC状态
kubectl get pvc <pvc-name>

# 输出：
# NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# app-pvc  Bound    pvc-01234567-89ab-cdef-0123-456789abcdef   10Gi       RWO            standard      10s

# 检查存储类
kubectl get storageclass

# 输出：
# NAME                PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
# standard (default)  kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer  false                  5m

# 解决方案1：修复PVC绑定
kubectl delete pvc <pvc-name>
kubectl apply -f pvc-basic.yaml

# 解决方案2：修复存储类
kubectl patch pvc <pvc-name> -p '{"spec":{"storageClassName":"standard"}}'

# 解决方案3：修复存储驱动
kubectl patch storageclass <storageclass-name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# 解决方案4：增加节点存储
kubectl scale nodepool <nodepool-name> --replicas=<number>
```

---

## 10.4 集群问题

### 10.4.1 节点NotReady

```
节点NotReady排查：

┌─────────────────────────────────────────────────────────────────┐
│  节点NotReady排查                                       │
└─────────────────────────────────────────────────────────────────┘

1. 节点状态为NotReady

错误信息：
├── NodeNotReady
├── KubeletNotReady
├── ContainerRuntimeNotReady
└── NetworkNotReady

常见原因：
├── Kubelet未运行
├── 容器运行时未运行
├── 网络插件未运行
├── 节点资源不足
└── 节点系统问题

解决方案：
# 检查节点状态
kubectl get nodes

# 输出：
# NAME     STATUS     ROLES           AGE   VERSION
# master    Ready      control-plane   5m    v1.26.3
# worker1   NotReady   <none>          5m    v1.26.3
# worker2   Ready      <none>          5m    v1.26.3

# 检查节点详细信息
kubectl describe node <node-name>

# 输出：
# Conditions:
#   Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason              Message
#   ----             ------  -----------------                 -----------------                ------              -------
#   MemoryPressure   False   Mon, 15 Jan 2024 10:00:00 +0000  Mon, 15 Jan 2024 10:00:00 +0000  KubeletHasSufficientMemory    kubelet has sufficient memory available
#   DiskPressure     False   Mon, 15 Jan 2024 10:00:00 +0000  Mon, 15 Jan 2024 10:00:00 +0000  KubeletHasNoDiskPressure     kubelet has no disk pressure
#   PIDPressure      False   Mon, 15 Jan 2024 10:00:00 +0000  Mon, 15 Jan 2024 10:00:00 +0000  KubeletHasSufficientPID      kubelet has sufficient PID available
#   Ready            False   Mon, 15 Jan 2024 10:00:00 +0000  Mon, 15 Jan 2024 10:00:00 +0000  KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized

# 检查Kubelet状态
ssh <node-name>
systemctl status kubelet

# 输出：
# ● kubelet.service - Kubernetes Kubelet
#    Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: enabled)
#    Active: active (running) since Mon 2024-01-15 10:00:00 UTC; 10s ago
#      Docs: https://kubernetes.io/docs/home/
#  Main PID: 1234 (kubelet)
#     Tasks: 8 (limit: 4915)
#    Memory: 45.2M
#    CGroup: /system.slice/kubelet.service
#            └─1234 /usr/bin/kubelet --config=/var/lib/kubelet/config.yaml --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.7

# 检查容器运行时状态
ssh <node-name>
systemctl status docker

# 输出：
# ● docker.service - Docker Application Container Engine
#    Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
#    Active: active (running) since Mon 2024-01-15 10:00:00 UTC; 10s ago
#      Docs: https://docs.docker.com
#  Main PID: 5678 (dockerd)
#     Tasks: 23 (limit: 4915)
#    Memory: 123.4M
#    CGroup: /system.slice/docker.service
#            └─5678 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

# 检查网络插件状态
ssh <node-name>
kubectl get pods -n kube-system -l k8s-app=calico-node

# 输出：
# NAME                READY   STATUS    RESTARTS   AGE
# calico-node-abc12   0/1     Running   0          10s
# calico-node-def34   1/1     Running   0          10s
# calico-node-ghi56   1/1     Running   0          10s

# 解决方案1：重启Kubelet
ssh <node-name>
systemctl restart kubelet

# 解决方案2：重启容器运行时
ssh <node-name>
systemctl restart docker

# 解决方案3：重启网络插件
kubectl delete pod <calico-node-pod-name> -n kube-system

# 解决方案4：检查节点资源
kubectl top nodes
ssh <node-name>
df -h
free -h
```

### 10.4.2 控制平面问题

```
控制平面问题排查：

┌─────────────────────────────────────────────────────────────────┐
│  控制平面问题排查                                        │
└─────────────────────────────────────────────────────────────────┘

1. API Server无法访问

错误信息：
├── The connection to the server <server-name> was refused
├── Unable to connect to the server
├── Connection refused
└── Network unreachable

常见原因：
├── API Server未运行
├── API Server端口错误
├── 网络连接问题
├── 证书问题
└── 防火墙问题

解决方案：
# 检查API Server状态
ssh <master-node>
kubectl get pods -n kube-system -l component=kube-apiserver

# 输出：
# NAME                               READY   STATUS    RESTARTS   AGE
# kube-apiserver-master               1/1     Running   0          10s

# 检查API Server日志
ssh <master-node>
kubectl logs -n kube-system <kube-apiserver-pod-name>

# 输出：
# I0115 10:00:00.123456       1 controller.go:608] OpenAPI AggregationController: Processing item v1beta1.metrics.k8s.io
# I0115 10:00:00.123456       1 controller.go:608] OpenAPI AggregationController: Processing item v1beta1.custom.metrics.k8s.io
# I0115 10:00:00.123456       1 controller.go:608] OpenAPI AggregationController: Processing item v1beta1.external.metrics.k8s.io

# 检查API Server端口
ssh <master-node>
netstat -tlnp | grep 6443

# 输出：
# tcp        0      0 0.0.0.0:6443            0.0.0.0:*               LISTEN      1234/kube-apiserver

# 检查API Server证书
ssh <master-node>
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# 输出：
# Certificate:
#     Data:
#         Version: 3 (0x2)
#         Serial Number:
#             01:23:45:67:89:ab:cd:ef:01:23:45:67:89:ab:cd:ef:01:23
#         Signature Algorithm: SHA256-RSA
#         Issuer: CN=kubernetes
#         Validity
#             Not Before: Jan 15 00:00:00 2024 GMT
#             Not After : Jan 15 00:00:00 2025 GMT
#         Subject: CN=kube-apiserver
#         Subject Public Key Info:
#             Public Key Algorithm: rsaEncryption
#                 RSA Public-Key: (2048 bit)

# 解决方案1：重启API Server
ssh <master-node>
kubectl delete pod <kube-apiserver-pod-name> -n kube-system

# 解决方案2：检查API Server配置
ssh <master-node>
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# 解决方案3：检查网络连接
ssh <master-node>
ping <api-server-ip>
telnet <api-server-ip> 6443

# 解决方案4：检查防火墙
ssh <master-node>
iptables -L -n | grep 6443
firewall-cmd --list-ports
```

---

## 本章小结

- Pod启动失败常见原因包括镜像拉取失败、容器启动失败、资源不足
- Pod启动失败可以使用kubectl describe、kubectl logs进行排查
- Pod调度失败常见原因包括节点选择器不匹配、资源不足
- Pod调度失败可以使用kubectl describe进行排查
- Service连接问题常见原因包括Service不存在、Service端口错误、Service选择器错误
- Service连接问题可以使用kubectl describe、kubectl get进行排查
- Ingress连接问题常见原因包括Ingress不存在、Ingress配置错误、Service不存在
- Ingress连接问题可以使用kubectl describe、kubectl get进行排查
- Pod间通信问题常见原因包括Pod IP错误、Pod端口错误、网络策略限制
- Pod间通信问题可以使用kubectl describe、kubectl get、nslookup进行排查
- PVC绑定失败常见原因包括PV不存在、PV容量不足、PV访问模式不匹配
- PVC绑定失败可以使用kubectl describe、kubectl get进行排查
- 存储挂载失败常见原因包括PVC未绑定、存储类不存在、存储驱动不支持
- 存储挂载失败可以使用kubectl describe、kubectl get进行排查
- 节点NotReady常见原因包括Kubelet未运行、容器运行时未运行、网络插件未运行
- 节点NotReady可以使用kubectl describe、systemctl status进行排查
- 控制平面问题常见原因包括API Server未运行、API Server端口错误、网络连接问题
- 控制平面问题可以使用kubectl describe、kubectl logs、netstat进行排查

---

**恭喜！你已经完成了Kubernetes专题的学习！**
