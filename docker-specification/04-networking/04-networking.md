# Docker网络深度解析

## 4.1 Docker网络原理

### 4.1.1 网络命名空间

```
网络命名空间隔离：

┌─────────────────────────────────────────────────────────────────┐
│  网络命名空间隔离机制                                    │
└─────────────────────────────────────────────────────────────────┘

隔离内容：

1. 网络接口
   ├── 独立的网络设备
   ├── 独立的IP地址
   ├── 独立的MAC地址
   └── 独立的路由表

2. 网络协议栈
   ├── 独立的TCP/IP栈
   ├── 独立的套接字
   ├── 独立的连接状态
   └── 独立的防火墙规则

3. 网络配置
   ├── 独立的DNS配置
   ├── 独立的hosts文件
   ├── 独立的网络参数
   └── 独立的网络工具

网络命名空间操作：

1. 创建网络命名空间
   ├── ip netns add <name>
   ├── 创建新的命名空间
   ├── 隔离网络环境
   └── 示例：ip netns add myns

2. 列出网络命名空间
   ├── ip netns list
   ├── 查看所有命名空间
   ├── 显示命名空间名称
   └── 示例：ip netns list

3. 删除网络命名空间
   ├── ip netns delete <name>
   ├── 删除指定命名空间
   ├── 清理网络资源
   └── 示例：ip netns delete myns

4. 在网络命名空间中执行命令
   ├── ip netns exec <name> <command>
   ├── 在指定命名空间执行
   ├── 隔离执行环境
   └── 示例：ip netns exec myns ip addr
```

### 4.1.2 Linux网桥

```
Linux网桥原理：

┌─────────────────────────────────────────────────────────────────┐
│  Linux网桥工作原理                                      │
└─────────────────────────────────────────────────────────────────┘

网桥功能：

1. 二层转发
   ├── 基于MAC地址转发
   ├── 学习MAC地址表
   ├── 广播和组播
   └── 隔离广播域

2. 网络隔离
   ├── 隔离不同网段
   ├── 控制网络流量
   ├── 提高安全性
   └── 优化网络性能

3. 网络扩展
   ├── 连接多个网络
   ├── 扩展网络范围
   ├── 支持VLAN
   └── 支持STP

Docker网桥：

1. docker0网桥
   ├── 默认创建
   ├── 连接所有容器
   ├── 提供NAT
   └── 支持端口映射

2. 自定义网桥
   ├── 用户创建
   ├── 网络隔离
   ├── 服务发现
   └── 支持DNS

网桥工作流程：

1. 容器创建
   ├── 创建veth对
   ├── 一端在容器内
   ├── 一端在网桥上
   └── 配置IP地址

2. 网络通信
   ├── 容器间通信
   ├── 通过网桥转发
   ├── 基于MAC地址
   └── 二层转发

3. 外部访问
   ├── 端口映射
   ├── NAT转换
   ├── DNAT规则
   └── SNAT规则
```

### 4.1.3 iptables和NAT

```
iptables和NAT原理：

┌─────────────────────────────────────────────────────────────────┐
│  iptables和NAT工作原理                                  │
└─────────────────────────────────────────────────────────────────┘

iptables表和链：

1. Filter表（默认表）
   ├── INPUT链
   ├── FORWARD链
   ├── OUTPUT链
   └── 用于过滤数据包

2. NAT表
   ├── PREROUTING链
   ├── POSTROUTING链
   ├── OUTPUT链
   └── 用于地址转换

3. Mangle表
   ├── PREROUTING链
   ├── INPUT链
   ├── FORWARD链
   ├── OUTPUT链
   ├── POSTROUTING链
   └── 用于修改数据包

4. Raw表
   ├── PREROUTING链
   ├── OUTPUT链
   └── 用于连接跟踪

NAT类型：

1. SNAT（Source NAT）
   ├── 修改源IP地址
   ├── 用于出站流量
   ├── 容器访问外部
   └── 示例：-j SNAT --to-source 192.168.1.100

2. DNAT（Destination NAT）
   ├── 修改目标IP地址
   ├── 用于入站流量
   ├── 外部访问容器
   └── 示例：-j DNAT --to-destination 172.17.0.2:80

3. MASQUERADE（伪装）
   ├── 动态SNAT
   ├── 用于动态IP
   ├── 容器访问外部
   └── 示例：-j MASQUERADE

Docker NAT规则：

1. 端口映射
   ├── DNAT规则
   ├── 外部访问容器
   ├── 宿主机端口到容器端口
   └── 示例：-A DOCKER -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.17.0.2:80

2. 容器访问外部
   ├── MASQUERADE规则
   ├── 容器访问外部
   ├── 源IP转换为宿主机IP
   └── 示例：-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE

3. 容器间通信
   ├── ACCEPT规则
   ├── 允许容器间通信
   ├── 通过网桥转发
   └── 示例：-A FORWARD -i docker0 -o docker0 -j ACCEPT
```

---

## 4.2 Docker网络驱动

### 4.2.1 Bridge驱动

```
Bridge网络驱动：

┌─────────────────────────────────────────────────────────────────┐
│  Bridge网络驱动原理                                    │
└─────────────────────────────────────────────────────────────────┘

Bridge网络特点：

1. 网络隔离
   ├── 独立的网络命名空间
   ├── 独立的IP地址段
   ├── 独立的网络配置
   └── 网络间隔离

2. 容器间通信
   ├── 同一网络可以通信
   ├── 不同网络隔离
   ├── 使用内部DNS
   └── 服务发现

3. 外部访问
   ├── 端口映射
   ├── NAT转换
   ├── 防火墙规则
   └── 安全访问

Bridge网络配置：

1. 默认bridge网络
   ├── 自动创建
   ├── 使用docker0网桥
   ├── 默认网络
   └── 不支持DNS

2. 自定义bridge网络
   ├── 用户创建
   ├── 使用自定义网桥
   ├── 支持DNS
   └── 服务发现

3. overlay网络
   ├── 跨主机通信
   ├── 使用VXLAN封装
   ├── 支持加密
   └── 适合集群
```

```bash
# 创建自定义bridge网络
docker network create my-bridge

# 查看网络
docker network ls

# 输出：
# NETWORK ID     NAME        DRIVER    SCOPE
# abc123def456   bridge      bridge    local
# abc123def456   host        host      local
# abc123def456   my-bridge   bridge    local
# abc123def456   none        null      local

# 查看网络详细信息
docker network inspect my-bridge

# 输出：
# [
#     {
#         "Name": "my-bridge",
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Scope": "local",
#         "Driver": "bridge",
#         "EnableIPv6": false,
#         "IPAM": {
#             "Driver": "default",
#             "Options": {},
#             "Config": [
#                 {
#                     "Subnet": "172.18.0.0/16",
#                     "Gateway": "172.18.0.1"
#                 }
#             ]
#         },
#         "Internal": false,
#         "Attachable": false,
#         "Ingress": false,
#         "ConfigFrom": {
#             "Network": ""
#         },
#         "ConfigOnly": false,
#         "Containers": {},
#         "Options": {},
#         "Labels": {}
#     }
# ]

# 创建容器并连接到自定义bridge网络
docker run -d \
  --name web-server \
  --network my-bridge \
  nginx

# 将运行中的容器连接到网络
docker network connect my-bridge web-server

# 断开容器与网络的连接
docker network disconnect my-bridge web-server

# 删除网络
docker network rm my-bridge
```

### 4.2.2 Host驱动

```
Host网络驱动：

┌─────────────────────────────────────────────────────────────────┐
│  Host网络驱动原理                                      │
└─────────────────────────────────────────────────────────────────┘

Host网络特点：

1. 共享宿主机网络
   ├── 使用宿主机网络命名空间
   ├── 使用宿主机IP地址
   ├── 使用宿主机端口
   └── 性能最好

2. 无网络隔离
   ├── 容器可以访问宿主机网络
   ├── 宿主机可以访问容器网络
   ├── 端口冲突风险
   └── 安全性较低

3. 适用场景
   ├── 高性能应用
   ├── 网络监控
   ├── 网络调试
   └── 系统服务

Host网络限制：

1. 端口冲突
   ├── 不能映射端口
   ├── 需要手动管理端口
   ├── 容器间端口冲突
   └── 需要规划端口

2. 网络隔离
   ├── 无网络隔离
   ├── 安全性较低
   ├── 不适合多租户
   └── 需要额外安全措施
```

```bash
# 使用host网络运行容器
docker run -d \
  --name web-server \
  --network host \
  nginx

# 查看容器网络配置
docker inspect web-server | grep -A 20 Networks

# 输出：
# "Networks": {
#     "host": {
#         "IPAMConfig": null,
#         "Links": null,
#         "Aliases": null,
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "",
#         "IPAddress": "",
#         "IPPrefixLen": 0,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "",
#         "DriverOpts": null
#     }
# }
```

### 4.2.3 None驱动

```
None网络驱动：

┌─────────────────────────────────────────────────────────────────┐
│  None网络驱动原理                                      │
└─────────────────────────────────────────────────────────────────┘

None网络特点：

1. 无网络配置
   ├── 不配置网络
   ├── 只有loopback接口
   ├── 完全隔离
   └── 需要手动配置

2. 完全隔离
   ├── 无法访问外部网络
   ├── 无法被外部访问
   ├── 无法与其他容器通信
   └── 适合批处理任务

3. 适用场景
   ├── 批处理任务
   ├── 数据处理
   ├── 安全隔离
   └── 测试环境

None网络限制：

1. 无网络访问
   ├── 无法访问外部网络
   ├── 无法下载依赖
   ├── 无法访问API
   └── 需要预先准备

2. 手动配置
   ├── 需要手动配置网络
   ├── 需要手动配置路由
   ├── 需要手动配置DNS
   └── 配置复杂
```

```bash
# 使用none网络运行容器
docker run -d \
  --name isolated-container \
  --network none \
  nginx

# 查看容器网络配置
docker inspect isolated-container | grep -A 20 Networks

# 输出：
# "Networks": {
#     "none": {
#         "IPAMConfig": null,
#         "Links": null,
#         "Aliases": null,
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "",
#         "IPAddress": "",
#         "IPPrefixLen": 0,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "",
#         "DriverOpts": null
#     }
# }
```

### 4.2.4 Overlay驱动

```
Overlay网络驱动：

┌─────────────────────────────────────────────────────────────────┐
│  Overlay网络驱动原理                                    │
└─────────────────────────────────────────────────────────────────┘

Overlay网络特点：

1. 跨主机通信
   ├── 支持跨主机容器通信
   ├── 使用VXLAN封装
   ├── 支持加密
   └── 适合集群

2. 网络隔离
   ├── 独立的网络命名空间
   ├── 独立的IP地址段
   ├── 独立的网络配置
   └── 网络间隔离

3. 服务发现
   ├── 内置DNS
   ├── 自动服务发现
   ├── 负载均衡
   └── 健康检查

Overlay网络配置：

1. 键值存储
   ├── Consul
   ├── Etcd
   ├── ZooKeeper
   └── 存储网络状态

2. 网络加密
   ├── AES加密
   ├── 自动密钥轮换
   ├── 安全传输
   └── 符合合规要求

3. 网络性能
   ├── VXLAN封装开销
   ├── 网络延迟增加
   ├── 带宽利用率降低
   └── 需要优化
```

```bash
# 创建overlay网络（需要Swarm集群）
docker network create \
  --driver overlay \
  --subnet 10.0.0.0/24 \
  --opt encrypted \
  my-overlay

# 查看网络
docker network ls

# 输出：
# NETWORK ID     NAME        DRIVER    SCOPE
# abc123def456   bridge      bridge    local
# abc123def456   host        host      local
# abc123def456   my-overlay  overlay   swarm
# abc123def456   none        null      local

# 查看网络详细信息
docker network inspect my-overlay

# 输出：
# [
#     {
#         "Name": "my-overlay",
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Scope": "swarm",
#         "Driver": "overlay",
#         "EnableIPv6": false,
#         "IPAM": {
#             "Driver": "default",
#             "Options": {},
#             "Config": [
#                 {
#                     "Subnet": "10.0.0.0/24",
#                     "Gateway": "10.0.0.1"
#                 }
#             ]
#         },
#         "Internal": false,
#         "Attachable": false,
#         "Ingress": false,
#         "ConfigFrom": {
#             "Network": ""
#         },
#         "ConfigOnly": false,
#         "Containers": {},
#         "Options": {
#             "encrypted": ""
#         },
#         "Labels": {}
#     }
# ]
```

---

## 4.3 容器间通信

### 4.3.1 同一网络容器通信

```bash
# 创建自定义bridge网络
docker network create my-network

# 运行第一个容器
docker run -d \
  --name web-server \
  --network my-network \
  nginx

# 运行第二个容器
docker run -d \
  --name app-server \
  --network my-network \
  python:3.11-slim \
  python -m http.server 8000

# 在第一个容器中访问第二个容器
docker exec web-server curl http://app-server:8000

# 输出：
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
# <html>
# <head>
# <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
# <title>Directory listing for /</title>
# </head>
# <body>
# <h1>Directory listing for /</h1>
# <hr>
# <ul>
# <li><a href=".dockerenv">.dockerenv</a></li>
# <li><a href="app.py">app.py</a></li>
# <li><a href="bin/">bin/</a></li>
# <li><a href="dev/">dev/</a></li>
# <li><a href="etc/">etc/</a></li>
# <li><a href="home/">home/</a></li>
# <li><a href="lib/">lib/</a></li>
# <li><a href="media/">media/</a></li>
# <li><a href="mnt/">mnt/</a></li>
# <li><a href="opt/">opt/</a></li>
# <li><a href="proc/">proc/</a></li>
# <li><a href="root/">root/</a></li>
# <li><a href="run/">run/</a></li>
# <li><a href="sbin/">sbin/</a></li>
# <li><a href="srv/">srv/</a></li>
# <li><a href="sys/">sys/</a></li>
# <li><a href="tmp/">tmp/</a></li>
# <li><a href="usr/">usr/</a></li>
# <li><a href="var/">var/</a></li>
# </ul>
# <hr>
# </body>
# </html>

# 查看容器IP地址
docker inspect web-server | grep IPAddress
docker inspect app-server | grep IPAddress

# 输出：
# "SecondaryIPAddresses": null,
# "IPAddress": "172.18.0.2",
# "IPPrefixLen": 16,
# "IPv6Gateway": "",
# "GlobalIPv6Address": "",
# "GlobalIPv6PrefixLen": 0,
```

### 4.3.2 跨网络容器通信

```bash
# 创建两个网络
docker network create network-a
docker network create network-b

# 运行第一个容器并连接到network-a
docker run -d \
  --name container-a \
  --network network-a \
  nginx

# 运行第二个容器并连接到network-b
docker run -d \
  --name container-b \
  --network network-b \
  python:3.11-slim \
  python -m http.server 8000

# 尝试从container-a访问container-b（会失败）
docker exec container-a curl http://container-b:8000

# 输出：
# curl: (6) Could not resolve host: container-b

# 将container-b也连接到network-a
docker network connect network-a container-b

# 再次尝试访问（成功）
docker exec container-a curl http://container-b:8000

# 输出：
# <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
# <html>
# <head>
# <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
# <title>Directory listing for /</title>
# </head>
# <body>
# <h1>Directory listing for /</h1>
# <hr>
# <ul>
# <li><a href=".dockerenv">.dockerenv</a></li>
# <li><a href="app.py">app.py</a></li>
# <li><a href="bin/">bin/</a></li>
# <li><a href="dev/">dev/</a></li>
# <li><a href="etc/">etc/</a></li>
# <li><a href="home/">home/</a></li>
# <li><a href="lib/">lib/</a></li>
# <li><a href="media/">media/</a></li>
# <li><a href="mnt/">mnt/</a></li>
# <li><a href="opt/">opt/</a></li>
# <li><a href="proc/">proc/</a></li>
# <li><a href="root/">root/</a></li>
# <li><a href="run/">run/</a></li>
# <li><a href="sbin/">sbin/</a></li>
# <li><a href="srv/">srv/</a></li>
# <li><a href="sys/">sys/</a></li>
# <li><a href="tmp/">tmp/</a></li>
# <li><a href="usr/">usr/</a></li>
# <li><a href="var/">var/</a></li>
# </ul>
# <hr>
# </body>
# </html>

# 查看容器连接的网络
docker inspect container-b | grep -A 10 Networks

# 输出：
# "Networks": {
#     "network-a": {
#         "IPAMConfig": {},
#         "Links": null,
#         "Aliases": [
#             "container-b"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.19.0.1",
#         "IPAddress": "172.19.0.3",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:13:00:03",
#         "DriverOpts": {}
#     },
#     "network-b": {
#         "IPAMConfig": {},
#         "Links": null,
#         "Aliases": [
#             "container-b"
#         ],
#         "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Gateway": "172.20.0.1",
#         "IPAddress": "172.20.0.2",
#         "IPPrefixLen": 16,
#         "IPv6Gateway": "",
#         "GlobalIPv6Address": "",
#         "GlobalIPv6PrefixLen": 0,
#         "MacAddress": "02:42:ac:14:00:02",
#         "DriverOpts": {}
#     }
# }
```

---

## 4.4 外部访问配置

### 4.4.1 端口映射

```bash
# 映射单个端口
docker run -d \
  --name web-server \
  -p 80:80 \
  nginx

# 映射多个端口
docker run -d \
  --name web-server \
  -p 80:80 \
  -p 443:443 \
  nginx

# 映射随机端口
docker run -d \
  --name web-server \
  -p 80 \
  nginx

# 查看端口映射
docker port web-server

# 输出：
# 80/tcp -> 0.0.0.0:32768

# 绑定到特定接口
docker run -d \
  --name web-server \
  -p 127.0.0.1:80:80 \
  nginx

# 绑定到特定接口和端口
docker run -d \
  --name web-server \
  -p 192.168.1.100:8080:80 \
  nginx

# 映射UDP端口
docker run -d \
  --name dns-server \
  -p 53:53/udp \
  dns-server

# 映射端口范围
docker run -d \
  --name web-server \
  -p 8000-8010:8000-8010 \
  nginx

# 查看iptables规则
iptables -t nat -L -n -v | grep DOCKER

# 输出：
# Chain DOCKER (2 references)
# pkts bytes target     prot opt in     out     source               destination
#    0     0 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:172.17.0.2:80
```

### 4.4.2 负载均衡

```bash
# 运行多个容器
docker run -d \
  --name web-server-1 \
  -p 8081:80 \
  nginx

docker run -d \
  --name web-server-2 \
  -p 8082:80 \
  nginx

docker run -d \
  --name web-server-3 \
  -p 8083:80 \
  nginx

# 使用HAProxy进行负载均衡
docker run -d \
  --name haproxy \
  -p 80:80 \
  -v /path/to/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  haproxy:latest

# haproxy.cfg
# frontend http-in
#     bind *:80
#     default_backend web-servers
#
# backend web-servers
#     balance roundrobin
#     server web1 web-server-1:80 check
#     server web2 web-server-2:80 check
#     server web3 web-server-3:80 check

# 测试负载均衡
for i in {1..10}; do
  curl http://localhost
  echo ""
done

# 输出：
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
# ...
```

---

## 本章小结

- Docker网络使用网络命名空间隔离
- Bridge网络提供容器间通信和外部访问
- Host网络提供最高性能但无隔离
- None网络提供完全隔离
- Overlay网络支持跨主机通信
- 容器间通信可以通过容器名称或IP地址
- 端口映射实现外部访问容器
- 负载均衡可以提高应用可用性

---

**下一章：Docker存储**
