# GCP命令详解

## 本章导学

**学完本章后，你将能够：**

- 从**命令结构**掌握gcloud CLI的组织方式
- 从**输出格式**理解GCP命令的不同展示方式
- 从**服务分类**熟练操作GCP各种计算资源
- 从**调试技巧**快速定位和解决GCP问题
- 从**实战场景**应对日常工作需求

**学习方法：**

```
命令结构 → 输出格式 → 服务操作 → 调试排错 → 实战场景
```

---

# 命令目录

## 按服务类别索引

| 服务类别 | 命令章节 |
|---------|---------|
| **gcloud基础** | [1.1 命令结构](#11-gcloud命令结构) / [1.2 输出格式](#12-输出格式) |
| **计算服务** | |
| &nbsp;&nbsp;&nbsp;• Compute Engine | [2.1 实例操作](#21-实例操作) / [2.2 磁盘操作](#22-磁盘操作) |
| &nbsp;&nbsp;&nbsp;• GKE | [3.1 集群操作](#31-集群操作) |
| &nbsp;&nbsp;&nbsp;• Cloud Run | [4.1 服务操作](#41-服务操作) |
| **数据服务** | |
| &nbsp;&nbsp;&nbsp;• Cloud Storage | [5.1 存储桶操作](#51-存储桶操作) / [5.2 对象操作](#52-对象操作) |
| &nbsp;&nbsp;&nbsp;• BigQuery | [6.1 数据集操作](#61-数据集操作) / [6.2 表操作](#62-表操作) / [6.3 查询操作](#63-查询操作) |
| &nbsp;&nbsp;&nbsp;• Cloud SQL | [7.1 实例操作](#71-实例操作) / [7.2 数据库和用户操作](#72-数据库和用户操作) |
| &nbsp;&nbsp;&nbsp;• AlloyDB | [6.5 AlloyDB操作](#65-alloydb操作) |
| &nbsp;&nbsp;&nbsp;• Memorystore | [10.1 Redis实例](#101-redis实例操作) |
| **网络服务** | |
| &nbsp;&nbsp;&nbsp;• VPC Network | [8.1 VPC操作](#81-vpc操作) / [8.2 防火墙和路由](#82-防火墙和路由) |
| **安全服务** | |
| &nbsp;&nbsp;&nbsp;• IAM | [9.1 策略操作](#91-策略操作) / [9.2 服务账号操作](#92-服务账号操作) |
| &nbsp;&nbsp;&nbsp;• Secret Manager | [9.3 密钥操作](#93-密钥操作) / [9.4 密钥访问和IAM](#94-密钥访问和iam) |
| **开发者工具** | |
| &nbsp;&nbsp;&nbsp;• Cloud Functions | [10.1 函数部署](#101-函数部署) |
| **调试和排错** | [11.1 日志查看](#111-日志查看) / [11.2 诊断命令](#112-诊断命令) / [11.3 操作验证](#113-操作验证) |
| **高级命令** | [12.1 批量操作](#121-批量操作) / [12.2 导出导入配置](#122-导出导入配置) / [12.3 过滤器组合](#123-过滤器组合) |

## 常用命令速查表

| 操作 | 命令 |
|-----|------|
| 列出资源 | `gcloud <service> list` |
| 查看详情 | `gcloud <service> describe <name>` |
| 创建资源 | `gcloud <service> create <name>` |
| 更新资源 | `gcloud <service> update <name>` |
| 删除资源 | `gcloud <service> delete <name>` |
| 启用API | `gcloud services enable <api>` |
| 查看配置 | `gcloud config list` |
| 设置项目 | `gcloud config set project <project>` |
| 认证登录 | `gcloud auth login` |

---

# gcloud CLI基础

## 1.1 gcloud命令结构

```
┌─────────────────────────────────────────────────────────────────┐
│                    gcloud命令结构                                    │
└─────────────────────────────────────────────────────────────────┘

gcloud [GLOBAL FLAGS] <command> <group> [subgroup] <action> [FLAGS]

┌─────────────────────────────────────────────────────────────────┐
│  GLOBAL FLAGS: 全局选项                                          │
├─────────────────────────────────────────────────────────────────┤
│  --project=PROJECT_ID      - 指定项目                              │
│  --quiet                   - 静默模式（不提示确认）                 │
│  --verbosity=LEVEL        - 日志级别（debug/info/warning/error）  │
│  --format=FORMAT          - 输出格式                              │
│  --dry-run                - 试运行                                │
│  --configuration=NAME     - 使用指定配置                           │
│  --help                   - 显示帮助                              │
│  --version                - 显示版本                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  command: 服务组                                                │
├─────────────────────────────────────────────────────────────────┤
│  compute            - 计算资源                                    │
│  container         - 容器（Kubernetes）                           │
│  run               - Cloud Run                                   │
│  storage           - 存储                                        │
│  sql               - Cloud SQL                                   │
│  pubsub            - Pub/Sub                                    │
│  functions         - Cloud Functions                             │
│  iam               - IAM                                        │
│  projects          - 项目管理                                    │
│  services          - API服务                                     │
│  firestore         - Firestore                                  │
│  builds            - Cloud Build                                │
│  deploy            - Cloud Deploy                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  action: 操作动作                                                │
├─────────────────────────────────────────────────────────────────┤
│  list              - 列出资源                                    │
│  describe          - 查看详情                                    │
│  create            - 创建资源                                    │
│  delete            - 删除资源                                    │
│  update            - 更新资源                                    │
│  start/stop        - 启动/停止                                  │
│  add-iam-policy-binding   - 添加IAM策略                          │
│  get-iam-policy    - 获取IAM策略                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.1.2 常用全局命令

```bash
# gcloud基础命令

# 初始化gcloud
gcloud init

# 登录认证
gcloud auth login
gcloud auth activate-service-account --key-file=KEY_FILE.json
gcloud auth list

# 退出登录
gcloud auth revoke

# 设置默认项目
gcloud config set project PROJECT_ID

# 设置默认区域和区域
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# 查看当前配置
gcloud config list
gcloud config get-value project
gcloud config get-value compute/region

# 启用API服务
gcloud services enable SERVICE_NAME.googleapis.com

# 列出所有可用的API
gcloud services list --available

# 更新gcloud组件
gcloud components update

# 安装额外组件
gcloud components install COMPONENT_ID

# 显示帮助
gcloud --help
gcloud compute --help
gcloud compute instances --help
```

[← 返回目录](#命令目录)

---

## 1.2 输出格式

```
┌─────────────────────────────────────────────────────────────────┐
│                    gcloud输出格式详解                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  --format=FORMAT 选项                                           │
└─────────────────────────────────────────────────────────────────┘

# 默认输出（简洁表格）
gcloud compute instances list
# NAME        ZONE           MACHINE_TYPE  STATUS
# instance-1  us-central1-a  e2-medium     RUNNING

# JSON输出
gcloud compute instances list --format=json
gcloud compute instances list -o json

# YAML输出
gcloud compute instances list --format=yaml

# CSV输出
gcloud compute instances list --format=csv

# 扁平化输出（适合脚本）
gcloud compute instances list --format="value(name,status)"

# 自定义表格
gcloud compute instances list --format="table(name:label=NAME,status:label=STATUS,machine_type:label=TYPE)"

# 只获取特定字段
gcloud compute instances describe instance-1 --format="value(selfLink)"
gcloud sql instances describe instance-1 --format="value(connectionName)"

┌─────────────────────────────────────────────────────────────────┐
│  常用format模板                                                  │
└─────────────────────────────────────────────────────────────────┘

# 获取单个值（用于脚本）
--format="value(字段名)"

# 获取列表
--format="csv(字段1,字段2)"

# 美化表格
--format="table(字段1,字段2)"

# JSON数组
--format="json"

# 带标题的表格（默认）
--format="table"

# 无标题简洁格式
--format="list"
```

[← 返回目录](#命令目录)

---

# Compute Engine命令

## 2.1 实例操作

### 2.1.1 获取实例

```bash
# 获取所有实例
gcloud compute instances list

# 获取特定项目的实例
gcloud compute instances list --project=PROJECT_ID

# 按区域筛选
gcloud compute instances list --filter="zone:us-central1-a"

# 按名称筛选
gcloud compute instances list --filter="name~my-instance*"

# 宽表输出（增加显示列）
gcloud compute instances list --format="table(name,status,machine_type,zone)"

# 只获取名称列表
gcloud compute instances list --format="value(name)"

# 统计实例数量
gcloud compute instances list --format="value(name)" | wc -l
```

### 2.1.2 实例详情

```bash
# 查看实例详情
gcloud compute instances describe instance-name --zone=us-central1-a

# 获取内网IP
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(networkInterfaces[0].networkIP)"

# 获取外网IP
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(networkInterfaces[0].accessConfigs[0].natIP)"

# 获取实例状态
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(status)"

# 获取机器类型
gcloud compute instances describe instance-name --zone=us-central1-a --format="value(machineType)" | cut -d'/' -f5

# 获取启动脚本输出
gcloud compute instances get-serial-port-output instance-name --zone=us-central1-a
```

### 2.1.3 创建实例

```bash
# 创建基础实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud

# 创建带自定义配置实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=50GB `
    --boot-disk-type=pd-ssd `
    --subnet=my-subnet `
    --network-tier=PREMIUM `
    --tags=http-server,https-server `
    --metadata=startup-script='#!/bin/bash echo "Hello" > /var/www/html/index.html'

# 创建带服务账号实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --service-account=my-sa@PROJECT_ID.iam.gserviceaccount.com `
    --scopes=cloud-platform

# 创建带GPU实例
gcloud compute instances create gpu-instance `
    --zone=us-central1-a `
    --accelerator=type=nvidia-tesla-t4,count=1 `
    --machine-type=n1-standard-4 `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=100GB `
    --boot-disk-type=pd-ssd

# 从模板创建实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --source-instance-template=my-template

# 试运行（不实际创建）
gcloud compute instances create my-instance --zone=us-central1-a --dry-run
```

### 2.1.4 编辑和更新实例

```bash
# 编辑实例（元数据、标签等）
gcloud compute instances update my-instance `
    --zone=us-central1-a `
    --metadata=ENV=prod `
    --tags=new-tag

# 添加标签
gcloud compute instances add-labels my-instance --zone=us-central1-a --labels=env=prod

# 修改机器类型（需要先停止）
gcloud compute instances set-machine-type my-instance --zone=us-central1-a --machine-type=n2-standard-8

# 修改服务账号
gcloud compute instances set-service-account my-instance --zone=us-central1-a --service-account=new-sa@PROJECT_ID.iam.gserviceaccount.com

# 设置.metadata文件
gcloud compute instances add-metadata my-instance --zone=us-central1-a --metadata-from-file=startup-script=startup.sh
```

### 2.1.5 启动停止删除

```bash
# 启动实例
gcloud compute instances start my-instance --zone=us-central1-a

# 停止实例
gcloud compute instances stop my-instance --zone=us-central1-a

# 重启实例（先停再开）
gcloud compute instances stop my-instance --zone=us-central1-a
gcloud compute instances start my-instance --zone=us-central1-a

# 删除实例
gcloud compute instances delete my-instance --zone=us-central1-a

# 强制删除（不等待确认）
gcloud compute instances delete my-instance --zone=us-central1-a --quiet

# 批量删除
gcloud compute instances delete instance-1 instance-2 --zone=us-central1-a --quiet
```

### 2.1.6 连接实例

```bash
# SSH连接（Linux）
gcloud compute ssh my-instance --zone=us-central1-a

# 指定用户SSH
gcloud compute ssh user@my-instance --zone=us-central1-a

# 使用特定密钥连接
gcloud compute ssh my-instance --zone=us-central1-a --ssh-key-file=~/.ssh/my_key

# Windows RDP获取密码
gcloud compute instances get-password my-instance --zone=us-central1-a

# 获取串口输出（调试）
gcloud compute instances get-serial-port-output my-instance --zone=us-central1-a

# 重置Windows密码
gcloud compute instances reset-windows-password my-instance --zone=us-central1-a
```

[← 返回目录](#命令目录)

---

## 2.2 磁盘操作

### 2.2.1 磁盘管理

```bash
# 列出磁盘
gcloud compute disks list

# 按区域筛选
gcloud compute disks list --filter="zone:us-central1-a"

# 查看磁盘详情
gcloud compute disks describe my-disk --zone=us-central1-a

# 创建磁盘
gcloud compute disks create my-disk `
    --zone=us-central1-a `
    --size=50GB `
    --type=pd-ssd

# 从快照创建磁盘
gcloud compute disks create new-disk `
    --zone=us-central1-a `
    --source-snapshot=my-snapshot `
    --type=pd-ssd

# 调整磁盘大小
gcloud compute disks resize my-disk --zone=us-central1-a --size=100GB

# 删除磁盘
gcloud compute disks delete my-disk --zone=us-central1-a
```

### 2.2.2 快照管理

```bash
# 创建快照
gcloud compute snapshots create my-snapshot `
    --source-disk=my-disk `
    --source-zone=us-central1-a

# 列出快照
gcloud compute snapshots list

# 查看快照详情
gcloud compute snapshots describe my-snapshot

# 删除快照
gcloud compute snapshots delete my-snapshot

# 从快照创建磁盘
gcloud compute disks create my-new-disk `
    --zone=us-central1-a `
    --source-snapshot=my-snapshot
```

### 2.2.3 实例模板

```bash
# 创建实例模板
gcloud compute instance-templates create my-template `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB `
    --boot-disk-type=pd-ssd

# 创建带自定义网络的模板
gcloud compute instance-templates create my-template `
    --machine-type=n2-standard-4 `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --network=my-vpc `
    --subnet=my-subnet

# 列出模板
gcloud compute instance-templates list

# 查看模板详情
gcloud compute instance-templates describe my-template

# 使用模板创建实例组
gcloud compute instance-groups managed create my-group `
    --zone=us-central1-a `
    --template=my-template `
    --size=3

# 更新实例组大小
gcloud compute instance-groups managed resize my-group --zone=us-central1-a --size=5

# 删除模板
gcloud compute instance-templates delete my-template
```

[← 返回目录](#命令目录)

---

# GKE命令

## 3.1 集群操作

### 3.1.1 获取集群

```bash
# 列出所有集群
gcloud container clusters list

# 获取特定项目的集群
gcloud container clusters list --project=PROJECT_ID

# 按区域筛选
gcloud container clusters list --filter="location:us-central1"

# 查看集群详情
gcloud container clusters describe my-cluster --zone=us-central1-a

# 获取集群凭证（配置kubectl）
gcloud container clusters get-credentials my-cluster --zone=us-central1-a

# 查看集群端点
gcloud container clusters describe my-cluster --zone=us-central1-a --format="value(endpoint)"

# 查看集群版本
gcloud container clusters describe my-cluster --zone=us-central1-a --format="value(currentMasterVersion)"
```

### 3.1.2 创建集群

```bash
# 创建基础集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4

# 创建高可用集群
gcloud container clusters create my-cluster `
    --region=us-central1 `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10 `
    --enable-autorepair `
    --enable-autoupgrade `
    --workload-pool=PROJECT_ID.svc.id.goog

# 创建私有集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --enable-private-nodes `
    --master-ipv4-cidr=172.16.0.0/28 `
    --enable-ip-alias

# 创建GPU集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=2 `
    --machine-type=n1-standard-4 `
    --accelerator=type=nvidia-tesla-t4,count=1 `
    --image-type=UBUNTU `
    --boot-disk-size=100GB
```

### 3.1.3 更新和删除集群

```bash
# 更新集群
gcloud container clusters update my-cluster `
    --zone=us-central1-a `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10

# 启用addon
gcloud container clusters update my-cluster --zone=us-central1-a --enable-network-policy

# 升级集群版本
gcloud container clusters upgrade my-cluster --zone=us-central1-a --master

# 删除集群
gcloud container clusters delete my-cluster --zone=us-central1-a

# 快速删除（跳过确认）
gcloud container clusters delete my-cluster --zone=us-central1-a --quiet
```

### 3.1.4 节点池操作

```bash
# 列出节点池
gcloud container node-pools list --cluster=my-cluster --zone=us-central1-a

# 创建节点池
gcloud container node-pools create my-nodepool `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4

# 创建GPU节点池
gcloud container node-pools create gpu-nodepool `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --num-nodes=2 `
    --machine-type=n1-standard-4 `
    --accelerator=type=nvidia-tesla-t4,count=1

# 删除节点池
gcloud container node-pools delete my-nodepool --cluster=my-cluster --zone=us-central1-a
```

[← 返回目录](#命令目录)

---

# Cloud Run命令

## 4.1 服务操作

### 4.1.1 获取服务

```bash
# 列出所有服务
gcloud run services list --region=us-central1

# 查看服务详情
gcloud run services describe my-service --region=us-central1

# 获取服务URL
gcloud run services describe my-service --region=us-central1 --format="value(status.url)"

# 获取服务副本数
gcloud run services describe my-service --region=us-central1 --format="value(status.conditions[0].message)"

# 查看修订版本列表
gcloud run revisions list --region=us-central1 --service=my-service

# 查看特定修订版本
gcloud run revisions describe my-service-00001-abc --region=us-central1
```

### 4.1.2 部署服务

```bash
# 基础部署
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# 部署带环境变量
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --set-env-vars ENV=prod,VERSION=1.0.0 `
    --allow-unauthenticated

# 部署带内存和超时配置
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --memory=512Mi `
    --timeout=300 `
    --concurrency=80 `
    --max-instances=100 `
    --min-instances=2

# 部署带VPC连接
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --vpc-connector=my-connector `
    --vpc-egress=all-traffic

# 从源部署（Cloud Build）
gcloud run deploy my-service `
    --source . `
    --region us-central1 `
    --platform managed
```

### 4.1.3 更新和删除服务

```bash
# 更新服务配置
gcloud run services update my-service `
    --region us-central1 `
    --min-instances=2 `
    --max-instances=100 `
    --concurrency=100

# 更新环境变量
gcloud run services update my-service `
    --region us-central1 `
    --set-env-vars NEW_VAR=value

# 移除环境变量
gcloud run services update my-service --region us-central1 --remove-env-vars OLD_VAR

# 流量控制
gcloud run services update-traffic my-service `
    --region us-central1 `
    --to-revisions=my-service-00002-xyz=80,my-service-00001-abc=20

# 删除服务
gcloud run services delete my-service --region us-central1
```

[← 返回目录](#命令目录)

---

# Cloud Storage命令

## 5.1 存储桶操作

### 5.1.1 获取存储桶

```bash
# 列出所有存储桶
gsutil ls

# 列出特定前缀的存储桶
gsutil ls gs://my-bucket-*/

# 查看存储桶详情
gsutil ls -L gs://my-bucket

# 查看存储桶元数据
gsutil ls -s gs://my-bucket

# 获取存储桶URL
gsutil ls -b gs://my-bucket
```

### 5.1.2 创建和删除存储桶

```bash
# 创建存储桶
gsutil mb -l us-central1 gs://my-bucket-name

# 创建存储桶（指定存储类型）
gsutil mb -c nearline -l us-central1 gs://my-bucket-name

# 删除空存储桶
gsutil rb gs://my-bucket-name

# 强制删除（含所有对象）
gsutil rm -r gs://my-bucket-name
```

### 5.1.3 存储桶配置

```bash
# 设置存储桶标签
gsutil label set label.json gs://my-bucket

# 获取存储桶标签
gsutil label get gs://my-bucket

# 设置生命周期
gsutil lifecycle set lifecycle.json gs://my-bucket

# 设置CORS配置
gsutil cors set cors.json gs://my-bucket

# 设置版本控制
gsutil versioning set on gs://my-bucket

# 设置访问权限（IAM）
gsutil iam ch allUsers:objectViewer gs://my-bucket
```

[← 返回目录](#命令目录)

---

## 5.2 对象操作

### 5.2.1 上传下载

```bash
# 上传单个文件
gsutil cp file.txt gs://my-bucket/

# 上传文件夹
gsutil cp -r ./folder gs://my-bucket/

# 上传带元数据
gsutil cp -h "Content-Type:text/html" file.txt gs://my-bucket/

# 下载文件
gsutil cp gs://my-bucket/file.txt ./

# 下载整个桶
gsutil cp -r gs://my-bucket/ ./

# 并行上传（提高速度）
gsutil -m cp -r ./large-folder gs://my-bucket/
```

### 5.2.2 对象管理

```bash
# 列出对象
gsutil ls gs://my-bucket/

# 列出带详情的对象
gsutil ls -l gs://my-bucket/

# 重命名对象
gsutil mv gs://my-bucket/old.txt gs://my-bucket/new.txt

# 复制对象
gsutil cp gs://my-bucket/file1.txt gs://my-bucket/backup/file1.txt

# 删除对象
gsutil rm gs://my-bucket/file.txt

# 删除所有对象
gsutil rm gs://my-bucket/**

# 同步文件夹
gsutil rsync -r ./local-folder gs://my-bucket/
```

### 5.2.3 签名URL

```bash
# 生成签名URL（1小时有效）
gsutil signurl -d 1h key.json gs://my-bucket/file.txt

# 生成带自定义方法的签名URL
gsutil signurl -d 1h -m GET key.json gs://my-bucket/file.txt
```

[← 返回目录](#命令目录)

---

# BigQuery命令

## 6.1 数据集操作

### 6.1.1 获取数据集

```bash
# 列出数据集
bq ls

# 列出特定项目的数据集
bq ls --project_id=PROJECT_ID

# 查看数据集详情
bq show PROJECT:my_dataset

# 查看数据集访问控制
bq show --format=prettyjson PROJECT:my_dataset | grep access
```

### 6.1.2 创建和删除数据集

```bash
# 创建数据集
bq mk my_dataset

# 创建带位置的数据集
bq mk --location=us-central1 my_dataset

# 创建带访问控制的数据集
bq mk --dataset_id=my_dataset --description="My dataset" PROJECT

# 删除数据集
bq rm -r my_dataset

# 删除空数据集
bq rm my_dataset
```

[← 返回目录](#命令目录)

---

## 6.2 表操作

### 6.2.1 获取表

```bash
# 列出表
bq ls my_dataset

# 查看表详情
bq show my_dataset.my_table

# 查看表schema
bq show --schema my_dataset.my_table

# 查看表分区信息
bq show --format=prettyjson my_dataset.my_table | grep -A 10 partitioning

# 查看表大小
bq query --use_legacy_sql=false "SELECT SUM(size_bytes) FROM my_dataset.__TABLES__ WHERE table_id='my_table'"
```

### 6.2.2 创建和删除表

```bash
# 从CSV创建表
bq load --source_format=CSV my_dataset.my_table gs://bucket/data.csv schema.json

# 从查询结果创建表
bq query --use_legacy_sql=false --destination_table=my_dataset.new_table "SELECT * FROM my_dataset.old_table"

# 创建带分区的表
bq mk --table --time_partitioning_type=DAY my_dataset.my_table schema.json

# 创建带聚簇的表
bq mk --table --clustering_fields=field1,field2 my_dataset.my_table schema.json

# 删除表
bq rm my_dataset.my_table
```

[← 返回目录](#命令目录)

---

## 6.3 查询操作

### 6.3.1 执行查询

```bash
# 简单查询
bq query "SELECT * FROM my_dataset.my_table LIMIT 10"

# 标准SQL查询
bq query --use_legacy_sql=false "SELECT COUNT(*) FROM my_dataset.my_table"

# 查询带参数
bq query --use_legacy_sql=false --parameter=value "SELECT * FROM my_dataset.my_table WHERE id = @id"

# 查询并格式化输出
bq query --format=prettyjson "SELECT * FROM my_dataset.my_table LIMIT 1"
```

### 6.3.2 查询结果处理

```bash
# 查询并保存到表
bq query --destination_table=my_dataset.result_table "SELECT * FROM my_dataset.my_table"

# 查询并写入存储桶
bq extract my_dataset.my_table gs://bucket/output.csv

# 估算查询费用
bq query --dry_run "SELECT COUNT(*) FROM my_dataset.my_table"

# 查看查询计划
bq query --explain=compute "SELECT * FROM my_dataset.my_table"
```

[← 返回目录](#命令目录)

---

# Cloud SQL命令

## 7.1 实例操作

### 7.1.1 获取实例

```bash
# 列出实例
gcloud sql instances list

# 查看实例详情
gcloud sql instances describe my-instance

# 获取连接名
gcloud sql instances describe my-instance --format="value(connectionName)"

# 获取IP
gcloud sql instances describe my-instance --format="value(ipAddresses[0].ipAddress)"

# 查看实例状态
gcloud sql instances describe my-instance --format="value(state)"
```

### 7.1.2 创建实例

```bash
# 创建MySQL实例
gcloud sql instances create my-instance `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --storage-size=20GB `
    --storage-type=SSD `
    --availability-type=regional

# 创建PostgreSQL实例
gcloud sql instances create my-instance `
    --database-version=POSTGRES_14 `
    --tier=db-n1-standard-2 `
    --region=us-central1

# 创建高可用实例
gcloud sql instances create my-instance `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --availability-type=regional `
    --backup-start-time=02:00

# 创建只读副本
gcloud sql instances create my-replica `
    --master-instance-name=my-instance `
    --replica-type=READ `
    --region=us-east1
```

### 7.1.3 更新和删除实例

```bash
# 更新实例配置
gcloud sql instances patch my-instance `
    --tier=db-n1-standard-4 `
    --storage-size=50GB

# 启用高可用
gcloud sql instances patch my-instance --availability-type=regional

# 开启备份
gcloud sql instances patch my-instance --backup-start-time=02:00

# 开启SSL
gcloud sql instances patch my-instance --require-ssl

# 删除实例
gcloud sql instances delete my-instance

# 强制删除
gcloud sql instances delete my-instance --async
```

---

## 7.2 数据库和用户操作

### 7.2.1 数据库操作

```bash
# 创建数据库
gcloud sql databases create my-database --instance=my-instance

# 列出数据库
gcloud sql databases list --instance=my-instance

# 删除数据库
gcloud sql databases delete my-database --instance=my-instance
```

### 7.2.2 用户操作

```bash
# 创建用户
gcloud sql users create user_name --instance=my-instance --password=PASSWORD

# 创建随机密码用户
gcloud sql users create user_name --instance=my-instance --random-password-length=16

# 列出用户
gcloud sql users list --instance=my-instance

# 更新用户密码
gcloud sql users set-password user_name --instance=my-instance --password=NEW_PASSWORD

# 删除用户
gcloud sql users delete user_name --instance=my-instance
```

[← 返回目录](#命令目录)

---

# VPC网络命令

## 8.1 VPC操作

### 8.1.1 获取VPC

```bash
# 列出VPC
gcloud compute networks list

# 查看VPC详情
gcloud compute networks describe my-vpc

# 列出子网
gcloud compute networks subnets list

# 列出特定VPC的子网
gcloud compute networks subnets list --network=my-vpc
```

### 8.1.2 创建VPC

```bash
# 创建自动模式VPC
gcloud compute networks create auto-vpc --subnet-mode=auto

# 创建自定义模式VPC
gcloud compute networks create custom-vpc --subnet-mode=custom

# 创建子网
gcloud compute networks subnets create my-subnet `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24

# 创建带私有IP的子网
gcloud compute networks subnets create my-subnet `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24 `
    --enable-private-ip-google-access
```

### 8.1.3 VPC对等连接

```bash
# 创建VPC网络 peering
gcloud compute networks peerings create my-peering `
    --network=my-vpc `
    --peer-network=other-vpc

# 列出peering
gcloud compute networks peerings list --network=my-vpc

# 启用peering流量
gcloud compute networks peerings update my-peering `
    --network=my-vpc `
    --export-custom-routes `
    --import-custom-routes
```

[← 返回目录](#命令目录)

---

## 8.2 防火墙和路由

### 8.2.1 防火墙规则

```bash
# 列出防火墙规则
gcloud compute firewall-rules list

# 按网络筛选
gcloud compute firewall-rules list --filter="network:my-vpc"

# 查看规则详情
gcloud compute firewall-rules describe allow-ssh

# 创建规则
gcloud compute firewall-rules create allow-ssh `
    --network=my-vpc `
    --allow=tcp:22 `
    --source-ranges=0.0.0.0/0

# 创建允许内部流量的规则
gcloud compute firewall-rules create allow-internal `
    --network=my-vpc `
    --allow=tcp:0-65535,udp:0-65535,icmp `
    --source-ranges=10.0.0.0/8

# 更新规则
gcloud compute firewall-rules update allow-ssh --disabled=false

# 删除规则
gcloud compute firewall-rules delete allow-ssh
```

### 8.2.2 路由

```bash
# 列出路由
gcloud compute routes list

# 创建路由
gcloud compute routes create my-route `
    --network=my-vpc `
    --destination-range=192.168.0.0/24 `
    --next-hop-gateway=default-internet-gateway

# 删除路由
gcloud compute routes delete my-route
```

[← 返回目录](#命令目录)

---

# IAM命令

## 9.1 策略操作

### 9.1.1 获取策略

```bash
# 查看项目IAM策略
gcloud projects get-iam-policy PROJECT_ID --format=json

# 查看服务账号IAM策略
gcloud iam service-accounts get-iam-policy sa@PROJECT_ID.iam.gserviceaccount.com

# 查看资源IAM策略
gcloud pubsub topics get-iam-policy my-topic
gcloud storage buckets get-iam-policy gs://my-bucket
```

### 9.1.2 添加和移除策略

```bash
# 添加项目级IAM策略
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# 添加服务账号角色
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=serviceAccount:sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/editor

# 移除IAM策略
gcloud projects remove-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# 为资源添加IAM
gcloud storage buckets add-iam-policy-binding gs://my-bucket `
    --member=user:email@example.com `
    --role=roles/storage.objectViewer
```

[← 返回目录](#命令目录)

---

## 9.2 服务账号操作

### 9.2.1 服务账号管理

```bash
# 创建服务账号
gcloud iam service-accounts create my-sa `
    --display-name="My Service Account" `
    --description="Service account for my application"

# 列出服务账号
gcloud iam service-accounts list

# 查看服务账号详情
gcloud iam service-accounts describe sa@PROJECT_ID.iam.gserviceaccount.com

# 更新服务账号
gcloud iam service-accounts update sa@PROJECT_ID.iam.gserviceaccount.com `
    --display-name="New Name"

# 删除服务账号
gcloud iam service-accounts delete sa@PROJECT_ID.iam.gserviceaccount.com
```

### 9.2.2 服务账号密钥

```bash
# 创建密钥
gcloud iam service-accounts keys create key.json `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com

# 列出密钥
gcloud iam service-accounts keys list `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com

# 删除密钥
gcloud iam service-accounts keys delete KEY_ID `
    --iam-account=sa@PROJECT_ID.iam.gserviceaccount.com
```

[← 返回目录](#命令目录)

---

# Secret Manager命令

## 9.1 密钥操作

### 9.1.1 获取密钥

```bash
# 列出所有密钥
gcloud secrets list

# 按项目筛选
gcloud secrets list --project=PROJECT_ID

# 查看密钥详情
gcloud secrets describe my-secret

# 获取密钥最新版本的值
gcloud secrets versions describe latest --secret=my-secret

# 列出密钥的所有版本
gcloud secrets versions list my-secret
```

### 9.1.2 创建和删除密钥

```bash
# 从文件创建密钥
gcloud secrets create my-secret --data-file=./secret.txt

# 从标准输入创建密钥
echo -n "my-secret-value" | gcloud secrets create my-secret --data-file=-

# 从.env文件批量创建密钥
gcloud secrets create api-key --data-file=./api-key.txt
gcloud secrets create db-password --data-file=./db-password.txt

# 删除密钥（会删除所有版本）
gcloud secrets delete my-secret

# 强制删除（跳过确认）
gcloud secrets delete my-secret --quiet
```

### 9.1.3 密钥版本管理

```bash
# 添加新版本
gcloud secrets versions add my-secret --data-file=./new-secret.txt

# 禁用版本
gcloud secrets versions disable 1 --secret=my-secret

# 启用版本
gcloud secrets versions enable 1 --secret=my-secret

# 销毁版本
gcloud secrets versions destroy 1 --secret=my-secret

# 查看版本访问状态
gcloud secrets versions describe 1 --secret=my-secret
```

[← 返回目录](#命令目录)

---

## 9.2 密钥访问和IAM

### 9.2.1 访问密钥

```bash
# 获取密钥值（最新版本）
gcloud secrets versions access latest --secret=my-secret

# 获取特定版本的值
gcloud secrets versions access 1 --secret=my-secret

# 访问并保存到文件
gcloud secrets versions access latest --secret=my-secret --out-file=./retrieved-secret.txt
```

### 9.2.2 密钥IAM策略

```bash
# 查看密钥IAM策略
gcloud secrets get-iam-policy my-secret

# 添加访问者
gcloud secrets add-iam-policy-binding my-secret `
    --member=user:email@example.com `
    --role=roles/secretmanager.secretAccessor

# 添加服务账号访问权限
gcloud secrets add-iam-policy-binding my-secret `
    --member=serviceAccount:sa@PROJECT_ID.iam.gserviceaccount.com `
    --role=roles/secretmanager.secretAccessor

# 移除访问权限
gcloud secrets remove-iam-policy-binding my-secret `
    --member=user:email@example.com `
    --role=roles/secretmanager.secretAccessor
```

[← 返回目录](#命令目录)

---

## 9.3 密钥标签和 replication

### 9.3.1 标签管理

```bash
# 创建带标签的密钥
gcloud secrets create my-secret --data-file=./secret.txt --labels=env=prod,team=backend

# 更新标签
gcloud secrets update my-secret --update-labels=env=staging

# 移除标签
gcloud secrets update my-secret --remove-labels=team
```

### 9.3.2 replication配置

```bash
# 创建自动 replication 的密钥（默认）
gcloud secrets create my-secret --data-file=./secret.txt --replication-policy=automatic

# 创建手动 replication 的密钥
gcloud secrets create my-secret --data-file=./secret.txt --replication-policy=manual

# 创建指定区域的密钥
gcloud secrets create my-secret --data-file=./secret.txt `
    --locations=us-central1 `
    --replication-policy=manual

# 创建多区域密钥
gcloud secrets create my-secret --data-file=./secret.txt `
    --locations=us-central1,europe-west1,asia-east1 `
    --replication-policy=manual
```

[← 返回目录](#命令目录)

---

# Memorystore (Redis)命令

## 10.1 实例操作

### 10.1.1 获取实例

```bash
# 列出所有Redis实例
gcloud redis instances list

# 按项目筛选
gcloud redis instances list --project=PROJECT_ID

# 查看实例详情
gcloud redis instances describe my-redis --region=us-central1

# 获取实例IP和端口
gcloud redis instances describe my-redis --region=us-central1 --format="value(host,port)"

# 获取实例状态
gcloud redis instances describe my-redis --region=us-central1 --format="value(status)"
```

### 10.1.2 创建实例

```bash
# 创建基础层Redis实例
gcloud redis instances create my-redis `
    --size=1 `
    --region=us-central1 `
    --redis-version=redis_7_0

# 创建标准层Redis实例(带高可用)
gcloud redis instances create my-redis-standard `
    --size=2 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc

# 创建带AUTH和TLS的Redis实例
gcloud redis instances create my-redis-secure `
    --size=1 `
    --region=us-central1 `
    --tier=STANDARD `
    --redis-version=redis_7_0 `
    --network=projects/PROJECT_ID/global/networks/my-vpc `
    --enable-auth `
    --transit-encryption-mode=SERVER_AUTHENTICATION

# 创建带自定义配置的Redis实例
gcloud redis instances create my-redis-config `
    --size=1 `
    --region=us-central1 `
    --redis-version=redis_7_0 `
    --redis-config=maxmemory-policy=allkeys-lru,timeout=300
```

### 10.1.3 更新和删除实例

```bash
# 修改实例大小
gcloud redis instances update my-redis --region=us-central1 --size=3

# 修改实例层级
gcloud redis instances update my-redis --region=us-central1 --tier=STANDARD

# 更新Redis配置
gcloud redis instances update my-redis --region=us-central1 --redis-config=maxmemory-policy=allkeys-lru

# 启用AUTH
gcloud redis instances update my-redis --region=us-central1 --enable-auth

# 启用TLS
gcloud redis instances update my-redis --region=us-central1 --transit-encryption-mode=SERVER_AUTHENTICATION

# 删除实例
gcloud redis instances delete my-redis --region=us-central1

# 强制删除
gcloud redis instances delete my-redis --region=us-central1 --quiet
```

### 10.1.4 高可用操作

```bash
# 触发手动故障转移(标准层)
gcloud redis instances failover my-redis-standard --region=us-central1

# 测试连接
gcloud redis instances test-connection my-redis --region=us-central1

# 创建手动备份
gcloud redis instances export my-redis --region=us-central1 --output-directory=gs://my-bucket/backups/

# 查看备份列表
gcloud redis instances backups list my-redis --region=us-central1

# 设置维护窗口
gcloud redis instances update my-redis --region=us-central1 --maintenance-window-day=sunday --maintenance-window-start-time=03:00
```

[← 返回目录](#命令目录)

---

# 调试和排错

## 11.1 日志查看

### 11.1.1 gcloud日志命令

```bash
# 查看项目日志
gcloud logging read "resource.type=gce_instance" --limit=10

# 按时间过滤
gcloud logging read "timestamp>=2024-01-01T00:00:00Z" --limit=10

# 按严重程度过滤
gcloud logging read "severity>=ERROR" --limit=10

# 查看特定资源日志
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" --limit=10

# 实时跟踪日志
gcloud logging read "resource.type=gce_instance" --follow --limit=10
```

### 11.1.2 实例日志

```bash
# 查看实例串口输出
gcloud compute instances get-serial-port-output instance-name --zone=us-central1-a

# 查看Cloud Run日志
gcloud run services logs read my-service --region=us-central1

# 查看Cloud Build日志
gcloud builds log BUILD_ID
```

[← 返回目录](#命令目录)

---

## 11.2 诊断命令

### 11.2.1 网络诊断

```bash
# 测试连通性
gcloud compute ssh instance-name --zone=us-central1-a -- command="ping -c 4 8.8.8.8"

# 查看防火墙规则
gcloud compute firewall-rules list --filter="network:my-vpc AND disabled=false"

# 查看实例网络接口
gcloud compute instances describe instance-name --zone=us-central1-a --format="yaml(networkInterfaces)"

# 测试VPC peering
gcloud compute networks peerings list --network=my-vpc
```

### 11.2.2 资源诊断

```bash
# 查看配额使用
gcloud compute regions describe us-central1 --format="yaml(quotas)"

# 查看资源配额
gcloud compute project-info describe --project=PROJECT_ID

# 查看API启用状态
gcloud services list --enabled

# 检查服务账号权限
gcloud iam service-accounts get-iam-policy sa@PROJECT_ID.iam.gserviceaccount.com
```

[← 返回目录](#命令目录)

---

## 11.3 操作验证

### 11.3.1 Dry-run和Async

```bash
# 试运行（不实际执行）
gcloud compute instances create my-instance --zone=us-central1-a --dry-run

# 异步操作（不等待完成）
gcloud sql instances delete my-instance --async

# 查看操作状态
gcloud operations list --limit=10

# 查看特定操作
gcloud operations describe OPERATION_ID --zone=us-central1-a
```

[← 返回目录](#命令目录)

---

# 高级命令

## 12.1 批量操作

```bash
# 批量创建实例
gcloud compute instances create instance-{1,2,3} `
    --zone=us-central1-a `
    --machine-type=e2-medium

# 批量停止实例
gcloud compute instances stop instance-{1,2,3} --zone=us-central1-a

# 使用脚本批量操作
for i in {1..10}; do
    gcloud compute instances delete instance-$i --zone=us-central1-a --quiet
done
```

[← 返回目录](#命令目录)

## 12.2 导出导入配置

```bash
# 导出实例配置
gcloud compute instances export my-instance --zone=us-central1-a --destination=instance.yaml

# 从配置导入实例
gcloud compute instances import my-instance --zone=us-central1-a --source=instance.yaml

# 导出集群配置
gcloud container clusters describe my-cluster --zone=us-central1-a --format=yaml > cluster.yaml
```

## 12.3 过滤器组合

```bash
# 组合过滤条件
gcloud compute instances list --filter="zone:us-central1-a AND status:RUNNING AND machineType:e2-medium"

# 正则匹配
gcloud compute instances list --filter="name~my-instance-.*"

# 按标签筛选
gcloud compute instances list --filter="labels.env=prod"

# 时间范围筛选
gcloud logging read "timestamp>=2024-01-01T00:00:00Z AND timestamp<2024-01-02T00:00:00Z" --limit=10
```

[← 返回目录](#命令目录)

---

## 本章小结

- gcloud命令遵循 `gcloud <service> <action> <resource>` 结构
- 输出格式可通过 `--format` 选项定制，支持json/yaml/csv/value/table
- Compute Engine命令提供完整的实例生命周期管理
- GKE命令与kubectl配合使用，通过 `gcloud container clusters get-credentials` 获取凭证
- Cloud Run命令支持无服务器容器部署
- Cloud Storage使用 `gsutil` 命令，支持 `cp/rsync/mv` 等文件操作
- BigQuery使用 `bq` 命令进行数据查询和表管理
- Cloud SQL提供关系数据库生命周期管理
- IAM命令支持服务账号和权限的完整管理
- Secret Manager命令支持密钥的创建、版本管理和IAM访问控制
- Memorystore命令支持Redis实例的创建、高可用配置和故障转移
- 日志和诊断命令帮助快速定位问题