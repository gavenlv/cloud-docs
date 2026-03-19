# GCP命令参考速查表

## 本速查表说明

本速查表整理了GCP最常用的命令行操作，按服务分类，方便快速查阅。所有命令都适配了Windows PowerShell环境（使用反引号 ` 作为换行符）。

---

## 目录

1. [基础配置命令](#1-基础配置命令)
2. [Compute Engine](#2-compute-engine)
3. [GKE (Kubernetes)](#3-gke-kubernetes)
4. [Cloud Run](#4-cloud-run)
5. [Cloud Storage](#5-cloud-storage)
6. [BigQuery](#6-bigquery)
7. [Cloud SQL](#7-cloud-sql)
8. [Firestore](#8-firestore)
9. [VPC网络](#9-vpc网络)
10. [IAM和权限](#10-iam和权限)
11. [Secret Manager](#11-secret-manager)
12. [Pub/Sub](#12-pubsub)
13. [Cloud Functions](#13-cloud-functions)
14. [Cloud Build](#14-cloud-build)
15. [Cloud Deploy](#15-cloud-deploy)
16. [Artifact Registry](#16-artifact-registry)
17. [常用操作](#17-常用操作)

---

## 1. 基础配置命令

```powershell
# ============================================================
# 基础配置命令
# ============================================================

# 安装gcloud SDK（需要先下载安装）
# 官网: https://cloud.google.com/sdk/docs/install

# 初始化gcloud
gcloud init

# 登录
gcloud auth login

# 列出所有账号
gcloud auth list

# 切换账号
gcloud auth activate-service-account --key-file=KEY_FILE.json

# 退出登录
gcloud auth revoke

# 设置项目
gcloud config set project PROJECT_ID

# 设置默认区域
gcloud config set compute/region us-central1

# 设置默认区域
gcloud config set compute/zone us-central1-a

# 查看配置
gcloud config list

# 启用API服务
gcloud services enable SERVICE_NAME.googleapis.com

# 列出所有可用的API
gcloud services list --available

# 安装额外的gcloud组件
gcloud components install COMPONENT_ID

# 更新gcloud
gcloud components update
```

---

## 2. Compute Engine

```powershell
# ============================================================
# Compute Engine (虚拟机)
# ============================================================

# ---------- 基础操作 ----------

# 列出所有实例
gcloud compute instances list

# 列出特定区域的实例
gcloud compute instances list --filter="zone:us-central1-a"

# 创建实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB `
    --boot-disk-type=pd-ssd

# 创建带自定义网络的实例
gcloud compute instances create my-instance `
    --zone=us-central1-a `
    --machine-type=e2-medium `
    --subnet=my-subnet `
    --network-tier=PREMIUM `
    --tags=http-server,https-server

# 启动实例
gcloud compute instances start my-instance --zone=us-central1-a

# 停止实例
gcloud compute instances stop my-instance --zone=us-central1-a

# 删除实例
gcloud compute instances delete my-instance --zone=us-central1-a

# 查看实例详情
gcloud compute instances describe my-instance --zone=us-central1-a

# 远程连接（SSH）
gcloud compute ssh my-instance --zone=us-central1-a

# 远程连接（Windows RDP）
gcloud compute instances get-serial-port-output my-instance --zone=us-central1-a

# ---------- 磁盘操作 ----------

# 列出磁盘
gcloud compute disks list

# 创建磁盘
gcloud compute disks create my-disk `
    --zone=us-central1-a `
    --size=50GB `
    --type=pd-ssd

# 挂载磁盘到实例
gcloud compute instances attach-disk my-instance `
    --zone=us-central1-a `
    --disk=my-disk `
    --mode=rw

# 从实例卸载磁盘
gcloud compute instances detach-disk my-instance `
    --zone=us-central1-a `
    --disk=my-disk

# 创建快照
gcloud compute snapshots create my-snapshot `
    --source-disk=my-disk `
    --source-zone=us-central1-a

# 从快照创建磁盘
gcloud compute disks create new-disk `
    --zone=us-central1-a `
    --source-snapshot=my-snapshot `
    --type=pd-ssd

# ---------- 模板操作 ----------

# 创建实例模板
gcloud compute instance-templates create my-template `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --boot-disk-size=20GB

# 列出实例模板
gcloud compute instance-templates list

# 使用模板创建实例组
gcloud compute instance-groups managed create my-instance-group `
    --zone=us-central1-a `
    --template=my-template `
    --size=3
```

---

## 3. GKE (Kubernetes)

```powershell
# ============================================================
# GKE (Google Kubernetes Engine)
# ============================================================

# ---------- 集群操作 ----------

# 创建集群
gcloud container clusters create my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4 `
    --disk-type=pd-ssd `
    --disk-size=100GB

# 列出集群
gcloud container clusters list

# 获取集群凭证（配置kubectl）
gcloud container clusters get-credentials my-cluster --zone=us-central1-a

# 查看集群详情
gcloud container clusters describe my-cluster --zone=us-central1-a

# 更新集群
gcloud container clusters update my-cluster `
    --zone=us-central1-a `
    --enable-autoscaling `
    --min-nodes=1 `
    --max-nodes=10

# 删除集群
gcloud container clusters delete my-cluster --zone=us-central1-a

# ---------- 节点池操作 ----------

# 列出节点池
gcloud container node-pools list --cluster=my-cluster --zone=us-central1-a

# 创建节点池
gcloud container node-pools create my-nodepool `
    --cluster=my-cluster `
    --zone=us-central1-a `
    --num-nodes=3 `
    --machine-type=n2-standard-4

# ---------- kubectl 操作 ----------

# 查看节点
kubectl get nodes

# 查看Pods
kubectl get pods -A

# 查看服务
kubectl get services

# 部署应用
kubectl apply -f deployment.yaml

# 查看部署状态
kubectl get deployments

# 扩缩容
kubectl scale deployment my-app --replicas=5

# 查看日志
kubectl logs -f deployment/my-app

# 进入Pod
kubectl exec -it pod-name -- /bin/bash

# 删除资源
kubectl delete -f deployment.yaml
```

---

## 4. Cloud Run

```powershell
# ============================================================
# Cloud Run (无服务器容器)
# ============================================================

# ---------- 服务操作 ----------

# 部署服务
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --allow-unauthenticated

# 部署服务（带环境变量）
gcloud run deploy my-service `
    --image gcr.io/PROJECT_ID/my-image `
    --region us-central1 `
    --platform managed `
    --set-env-vars KEY=VALUE `
    --allow-unauthenticated

# 列出服务
gcloud run services list --region us-central1

# 查看服务详情
gcloud run services describe my-service --region us-central1

# 获取服务URL
gcloud run services describe my-service --region us-central1 --format="value(status.url)"

# 更新服务
gcloud run services update my-service `
    --region us-central1 `
    --min-instances=2 `
    --max-instances=100

# 删除服务
gcloud run services delete my-service --region us-central1

# ---------- revision操作 ----------

# 列出修订版本
gcloud run revisions list --region us-central1 --service=my-service

# 查看修订版本详情
gcloud run revisions describe my-service-00001-abc --region us-central1

# 流量控制
gcloud run services update-traffic my-service `
    --region us-central1 `
    --to-revisions=my-service-00001-abc=100
```

---

## 5. Cloud Storage

```powershell
# ============================================================
# Cloud Storage (对象存储)
# ============================================================

# ---------- 桶操作 ----------

# 创建存储桶
gsutil mb -l us-central1 gs://my-bucket-name

# 列出存储桶
gsutil ls

# 查看存储桶详情
gsutil ls -L gs://my-bucket-name

# 删除存储桶
gsutil rb gs://my-bucket-name

# 设置存储桶权限
gsutil iam ch allUsers:objectViewer gs://my-bucket-name

# 设置存储桶生命周期
gsutil lifecycle set lifecycle-config.json gs://my-bucket-name

# ---------- 对象操作 ----------

# 上传文件
gsutil cp file.txt gs://my-bucket-name/

# 上传文件夹
gsutil cp -r ./folder gs://my-bucket-name/

# 下载文件
gsutil cp gs://my-bucket-name/file.txt ./

# 列出对象
gsutil ls gs://my-bucket-name/

# 删除对象
gsutil rm gs://my-bucket-name/file.txt

# 移动对象
gsutil mv gs://my-bucket-name/file1.txt gs://my-bucket-name/file2.txt

# 复制对象
gsutil cp gs://my-bucket-name/file1.txt gs://my-bucket-name/backup/file1.txt

# 设置对象权限
gsutil acl ch -u allUsers:R gs://my-bucket-name/file.txt

# 开启版本控制
gsutil versioning set on gs://my-bucket-name

# 列出对象版本
gsutil ls -a gs://my-bucket-name/

# ---------- 签名URL ----------

# 生成签名URL（需要服务账号）
gsutil signurl -d 1h key.json gs://my-bucket-name/file.txt
```

---

## 6. BigQuery

```powershell
# ============================================================
# BigQuery (数据仓库)
# ============================================================

# ---------- 数据集操作 ----------

# 创建数据集
bq mk my_dataset

# 列出数据集
bq ls

# 查看数据集信息
bq show PROJECT:my_dataset

# 删除数据集
bq rm -r my_dataset

# ---------- 表操作 ----------

# 创建表（从CSV）
bq mk --table --source_format=CSV my_dataset.my_table schema.json gs://bucket/data.csv

# 列出表
bq ls my_dataset

# 查看表信息
bq show my_dataset.my_table

# 查询表 schema
bq show --schema my_dataset.my_table

# 删除表
bq rm my_dataset.my_table

# ---------- 查询操作 ----------

# 执行查询
bq query "SELECT * FROM my_dataset.my_table LIMIT 10"

# 执行查询（无结果输出）
bq query --use_legacy_sql=false "SELECT COUNT(*) FROM my_dataset.my_table"

# 查询并保存结果
bq query --destination_table=my_dataset.result_table "SELECT * FROM my_dataset.my_table"

# 查询并写入存储桶
bq extract my_dataset.my_table gs://bucket/output.csv

# ---------- 加载数据 ----------

# 从CSV加载
bq load my_dataset.my_table gs://bucket/data.csv schema.json

# 从JSON加载
bq load --source_format=NEWLINE_DELIMITED_JSON my_dataset.my_table gs://bucket/data.json schema.json
```

---

## 7. Cloud SQL

```powershell
# ============================================================
# Cloud SQL (云数据库)
# ============================================================

# ---------- 实例操作 ----------

# 创建MySQL实例
gcloud sql instances create my-instance `
    --database-version=MYSQL_8_0 `
    --tier=db-n1-standard-2 `
    --region=us-central1 `
    --storage-size=20GB

# 创建PostgreSQL实例
gcloud sql instances create my-instance `
    --database-version=POSTGRES_14 `
    --tier=db-n1-standard-2 `
    --region=us-central1

# 创建SQL Server实例
gcloud sql instances create my-instance `
    --database-version=SQLSERVER_2019_STANDARD `
    --tier=db-n1-standard-2 `
    --region=us-central1

# 列出实例
gcloud sql instances list

# 查看实例详情
gcloud sql instances describe my-instance

# 删除实例
gcloud sql instances delete my-instance

# ---------- 数据库操作 ----------

# 创建数据库
gcloud sql databases create my-database --instance=my-instance

# 列出数据库
gcloud sql databases list --instance=my-instance

# 删除数据库
gcloud sql databases delete my-database --instance=my-instance

# ---------- 用户操作 ----------

# 创建用户
gcloud sql users create user_name --instance=my-instance --password=PASSWORD

# 列出用户
gcloud sql users list --instance=my-instance

# 删除用户
gcloud sql users delete user_name --instance=my-instance

# ---------- 连接操作 ----------

# 获取连接名
gcloud sql instances describe my-instance --format="get(connectionName)"

# 导出数据
gcloud sql export sql my-instance gs://bucket/backup.sql --database=my-database

# 导入数据
gcloud sql import sql my-instance gs://bucket/backup.sql --database=my-database

# 开启高可用
gcloud sql instances patch my-instance --availability-type=regional

# 创建只读副本
gcloud sql instances create my-replica `
    --master-instance-name=my-instance `
    --replica-type=READ `
    --region=us-east1
```

---

## 8. Firestore

```powershell
# ============================================================
# Firestore (NoSQL数据库)
# ============================================================

# ---------- 集合操作 ----------

# 列出集合（使用gcloud）
gcloud firestore databases list

# 创建集合（通过写入文档自动创建）
# 使用控制台或SDK创建

# ---------- 文档操作 ----------

# 导出数据
gcloud firestore export gs://bucket/name

# 导入数据
gcloud firestore import gs://bucket/name

# ---------- SDK操作（Python示例）----------

# pip install google-cloud-firestore
# from google.cloud import firestore
# db = firestore.Client()
# 
# # 创建文档
# db.collection('users').document('user1').set({'name': 'Alice', 'age': 30})
# 
# # 读取文档
# doc = db.collection('users').document('user1').get()
# print(doc.to_dict())
# 
# # 查询
# users = db.collection('users').where('age', '>', 25).stream()
```

---

## 9. VPC网络

```powershell
# ============================================================
# VPC网络
# ============================================================

# ---------- VPC操作 ----------

# 创建VPC（自动模式）
gcloud compute networks create auto-vpc --subnet-mode=auto

# 创建VPC（自定义模式）
gcloud compute networks create custom-vpc --subnet-mode=custom

# 列出VPC
gcloud compute networks list

# 查看VPC详情
gcloud compute networks describe custom-vpc

# 删除VPC
gcloud compute networks delete custom-vpc

# ---------- 子网操作 ----------

# 创建子网
gcloud compute networks subnets create my-subnet `
    --network=custom-vpc `
    --region=us-central1 `
    --range=10.0.1.0/24

# 列出子网
gcloud compute networks subnets list

# 列出特定VPC的子网
gcloud compute networks subnets list --network=custom-vpc

# 删除子网
gcloud compute networks subnets delete my-subnet --region=us-central1

# ---------- 防火墙规则 ----------

# 创建防火墙规则
gcloud compute firewall-rules create allow-ssh `
    --network=custom-vpc `
    --allow=tcp:22 `
    --source-ranges=0.0.0.0/0

# 列出防火墙规则
gcloud compute firewall-rules list

# 列出特定网络的规则
gcloud compute firewall-rules list --filter="network:custom-vpc"

# 删除防火墙规则
gcloud compute firewall-rules delete allow-ssh

# ---------- 路由 ----------

# 列出路由
gcloud compute routes list

# 创建路由
gcloud compute routes create my-route `
    --network=custom-vpc `
    --destination-range=192.168.0.0/24 `
    --next-hop-gateway=default-internet-gateway

# ---------- 负载均衡 ----------

# 创建健康检查
gcloud compute health-checks create http my-health-check --port 80

# 创建后端服务
gcloud compute backend-services create my-backend `
    --protocol=HTTPS `
    --health-checks=my-health-check

# 创建URL映射
gcloud compute url-maps create my-url-map --default-service=my-backend

# 创建目标HTTPS代理
gcloud compute target-https-proxies create my-proxy `
    --url-map=my-url-map `
    --ssl-certificates=my-cert
```

---

## 10. IAM和权限

```powershell
# ============================================================
# IAM (身份和访问管理)
# ============================================================

# ---------- 项目IAM ----------

# 查看项目IAM策略
gcloud projects get-iam-policy PROJECT_ID

# 添加IAM策略绑定
gcloud projects add-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# 移除IAM策略绑定
gcloud projects remove-iam-policy-binding PROJECT_ID `
    --member=user:email@example.com `
    --role=roles/viewer

# ---------- 服务账号 ----------

# 创建服务账号
gcloud iam service-accounts create my-sa `
    --display-name="My Service Account"

# 列出服务账号
gcloud iam service-accounts list

# 获取服务账号邮箱
gcloud iam service-accounts describe my-sa@PROJECT_ID.iam.gserviceaccount.com

# 删除服务账号
gcloud iam service-accounts delete my-sa@PROJECT_ID.iam.gserviceaccount.com

# ---------- 服务账号密钥 ----------

# 创建密钥
gcloud iam service-accounts keys create key.json `
    --iam-account=my-sa@PROJECT_ID.iam.gserviceaccount.com

# 列出密钥
gcloud iam service-accounts keys list `
    --iam-account=my-sa@PROJECT_ID.iam.gserviceaccount.com

# 删除密钥
gcloud iam service-accounts keys delete KEY_ID `
    --iam-account=my-sa@PROJECT_ID.iam.gserviceaccount.com

# ---------- 自定义角色 ----------

# 创建自定义角色
gcloud iam roles create custom.role `
    --project=PROJECT_ID `
    --title="Custom Role" `
    --description="Custom role description" `
    --permissions=compute.instances.get,compute.instances.list

# 列出角色
gcloud iam roles list --project=PROJECT_ID

# 更新自定义角色
gcloud iam roles update custom.role `
    --project=PROJECT_ID `
    --add-permissions=compute.instances.create
```

---

## 11. Secret Manager

```powershell
# ============================================================
# Secret Manager (敏感信息管理)
# ============================================================

# ---------- Secret操作 ----------

# 启用Secret Manager
gcloud services enable secretmanager.googleapis.com

# 创建Secret
gcloud secrets create my-secret --replication-policy=automatic

# 创建带值的Secret
echo "my-secret-value" | gcloud secrets create my-secret --replication-policy=automatic --data-file=-

# 列出Secret
gcloud secrets list

# 查看Secret详情
gcloud secrets describe my-secret

# 删除Secret
gcloud secrets delete my-secret

# ---------- 版本操作 ----------

# 添加版本
echo "new-value" | gcloud secrets versions add my-secret --data-file=-

# 列出版本
gcloud secrets versions list my-secret

# 访问最新版本
gcloud secrets versions access latest --secret=my-secret

# 访问特定版本
gcloud secrets versions access 1 --secret=my-secret

# 禁用版本
gcloud secrets versions disable 1 --secret=my-secret

# 销毁版本
gcloud secrets versions destroy 1 --secret=my-secret

# ---------- IAM操作 ----------

# 添加访问权限
gcloud secrets add-iam-policy-binding my-secret `
    --member="serviceAccount:sa@PROJECT_ID.iam.gserviceaccount.com" `
    --role="roles/secretmanager.secretAccessor"

# 查看访问策略
gcloud secrets get-iam-policy my-secret
```

---

## 12. Pub/Sub

```powershell
# ============================================================
# Pub/Sub (消息队列)
# ============================================================

# ---------- 主题操作 ----------

# 创建主题
gcloud pubsub topics create my-topic

# 列出主题
gcloud pubsub topics list

# 发布消息
gcloud pubsub topics publish my-topic --message="Hello World"

# 发布JSON消息
gcloud pubsub topics publish my-topic --message='{"key": "value"}'

# 删除主题
gcloud pubsub topics delete my-topic

# ---------- 订阅操作 ----------

# 创建订阅（拉取模式）
gcloud pubsub subscriptions create my-sub --topic=my-topic

# 创建订阅（推送模式）
gcloud pubsub subscriptions create my-sub `
    --topic=my-topic `
    --push-endpoint=https://example.com/push

# 列出订阅
gcloud pubsub subscriptions list

# 拉取消息
gcloud pubsub subscriptions pull my-sub --limit=10

# 删除订阅
gcloud pubsub subscriptions delete my-sub

# ---------- 订阅配置 ----------

# 设置确认期限
gcloud pubsub subscriptions update my-sub --ack-deadline=60

# 设置消息保留时间
gcloud pubsub subscriptions update my-sub --message-retention-duration=604800

# 启用死信队列
gcloud pubsub subscriptions update my-sub --dead-letter-topic=my-dlq-topic
```

---

## 13. Cloud Functions

```powershell
# ============================================================
# Cloud Functions (无服务器函数)
# ============================================================

# ---------- 函数操作 ----------

# 部署HTTP函数
gcloud functions deploy my-function `
    --runtime python311 `
    --trigger-http `
    --entry-point hello_world `
    --region us-central1 `
    --allow-unauthenticated

# 部署触发函数（Pub/Sub）
gcloud functions deploy my-function `
    --runtime python311 `
    --trigger-topic my-topic `
    --entry-point process_message `
    --region us-central1

# 部署触发函数（存储桶）
gcloud functions deploy my-function `
    --runtime python311 `
    --trigger-bucket my-bucket `
    --entry-point process_file `
    --region us-central1

# 列出函数
gcloud functions list

# 查看函数详情
gcloud functions describe my-function --region us-central1

# 调用HTTP函数
gcloud functions call my-function --region us-central1

# 获取函数URL
gcloud functions describe my-function --region us-central1 --format="value(httpsTrigger.url)"

# 删除函数
gcloud functions delete my-function --region us-central1
```

---

## 14. Cloud Build

```powershell
# ============================================================
# Cloud Build (持续集成)
# ============================================================

# ---------- 构建操作 ----------

# 启用Cloud Build
gcloud services enable cloudbuild.googleapis.com

# 手动触发构建
gcloud builds submit --config=cloudbuild.yaml .

# 使用变量触发构建
gcloud builds submit --config=cloudbuild.yaml . `
    --substitutions _VERSION=1.0.0

# 列出构建
gcloud builds list --limit=10

# 查看构建详情
gcloud builds describe BUILD_ID

# 获取构建日志
gcloud builds log BUILD_ID

# ---------- 触发器操作 ----------

# 创建GitHub触发器
gcloud builds triggers create github `
    --repo-name=my-repo `
    --repo-owner=my-owner `
    --branch-pattern="^main$" `
    --build-config=cloudbuild.yaml

# 列出触发器
gcloud builds triggers list

# 删除触发器
gcloud builds triggers delete TRIGGER_NAME
```

---

## 15. Cloud Deploy

```powershell
# ============================================================
# Cloud Deploy (持续部署)
# ============================================================

# ---------- 部署操作 ----------

# 启用Cloud Deploy
gcloud services enable deploy.googleapis.com

# 创建发布
gcloud deploy releases create release-001 `
    --delivery-pipeline=my-pipeline `
    --skaffold-file=skaffold.yaml

# 列出发布
gcloud deploy releases list --delivery-pipeline=my-pipeline

# 推广发布
gcloud deploy releases promote `
    --release=release-001 `
    --delivery-pipeline=my-pipeline `
    --to-target=production

# 回滚
gcloud deploy rollouts undo release-001 `
    --delivery-pipeline=my-pipeline `
    --phase-id=production

# 查看部署状态
gcloud deploy rollouts list `
    --release=release-001 `
    --delivery-pipeline=my-pipeline
```

---

## 16. Artifact Registry

```powershell
# ============================================================
# Artifact Registry (镜像仓库)
# ============================================================

# ---------- 仓库操作 ----------

# 启用Artifact Registry
gcloud services enable artifactregistry.googleapis.com

# 创建Docker仓库
gcloud artifacts repositories create my-repo `
    --repository-format=docker `
    --location=us-central1

# 列出仓库
gcloud artifacts repositories list

# 查看仓库详情
gcloud artifacts repositories describe my-repo --location=us-central1

# 删除仓库
gcloud artifacts repositories delete my-repo --location=us-central1

# ---------- 镜像操作 ----------

# 配置Docker认证
gcloud auth configure-docker us-central1-docker.pkg.dev

# 标记镜像
docker tag my-image:latest us-central1-docker.pkg.dev/PROJECT_ID/my-repo/my-image:latest

# 推送镜像
docker push us-central1-docker.pkg.dev/PROJECT_ID/my-repo/my-image:latest

# 拉取镜像
docker pull us-central1-docker.pkg.dev/PROJECT_ID/my-repo/my-image:latest

# 列出镜像
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/my-repo

# 删除镜像
gcloud artifacts versions delete VERSION --package=my-image --repository=my-repo --location=us-central1
```

---

## 17. 常用操作

```powershell
# ============================================================
# 常用操作
# ============================================================

# ---------- 成本管理 ----------

# 列出账单账户
gcloud beta billing accounts list

# 关联项目到账单账户
gcloud beta billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT

# 查看预算
gcloud beta billing budgets list --billing-account=BILLING_ACCOUNT

# ---------- 监控 ----------

# 列出监控指标
gcloud monitoring metrics list

# 列出告警策略
gcloud alpha monitoring policies list

# 创建告警策略
gcloud alpha monitoring policies create --policy-from-file=policy.json

# ---------- 日志 ----------

# 查看日志
gcloud logging read "resource.type=gce_instance" --limit=10

# 查看特定资源日志
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=my-service"

# 写入日志
gcloud logging write my-log "Test message" --severity=INFO

# 删除日志
gcloud logging sinks delete SINK_NAME
```

---

## 附录：常见问题

### 0. gcloud命令执行流程深度解析

**gcloud是怎么将你的命令转发到GCP的？**

```
┌─────────────────────────────────────────────────────────────────┐
│              gcloud命令执行流程                                   │
└─────────────────────────────────────────────────────────────────┘

当你执行 gcloud compute instances list 时：

┌─────────────────────────────────────────────────────────────────┐
│  1. 命令解析阶段                                                │
│                                                                  │
│  gcloud → 解析命令结构                                         │
│     │                                                          │
│     ├── compute (组件组)                                       │
│     ├── instances (资源类型)                                   │
│     └── list (操作)                                           │
│                                                                  │
│  gcloud会自动：                                                │
│  - 查找对应的gcloud组件（如果没安装会提示安装）                 │
│  - 验证参数合法性                                              │
│  - 应用配置的默认项目/区域                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  2. 认证阶段                                                    │
│                                                                  │
│  gcloud使用以下凭证（按优先级）：                               │
│                                                                  │
│  1. --account 参数指定的账号                                   │
│  2. gcloud auth active-account 设置的当前账号                   │
│  3. 服务账号密钥（如果设置了 GOOGLE_APPLICATION_CREDENTIALS）   │
│                                                                  │
│  认证流程：                                                     │
│  - 获取OAuth2 Access Token                                      │
│  - Token附加到每个API请求                                       │
│  - GCP API验证Token有效性                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  3. API请求阶段                                                │
│                                                                  │
│  gcloud将命令转换为REST API调用：                               │
│                                                                  │
│  gcloud compute instances list                                 │
│     ↓                                                          │
│  GET https://compute.googleapis.com/compute/v1/projects/PROJECT/zones/us-central1-a/instances
│     ↓                                                          │
│  Headers:                                                      │
│     Authorization: Bearer ya29.a0AfH6...                      │
│     Content-Type: application/json                              │
│     User-Agent: google-cloud-sdk gcloud/...                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  4. 响应处理阶段                                                │
│                                                                  │
│  API返回JSON响应：                                              │
│                                                                  │
│  {                                                            │
│    "kind": "compute#instances",                               │
│    "items": [                                                 │
│      { "name": "my-instance", "status": "RUNNING", ... }      │
│    ]                                                          │
│  }                                                            │
│     ↓                                                          │
│  gcloud解析JSON                                               │
│     ↓                                                          │
│  格式化输出（表格/JSON/YAML）                                  │
└─────────────────────────────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────────────┐
│              gcloud配置文件解析                                   │
└─────────────────────────────────────────────────────────────────┘

gcloud配置存储位置：

┌─────────────────────────────────────────────────────────────────┐
│  Windows:                                                     │
│  C:\Users\<username>\AppData\Roaming\gcloud                    │
│  或 %APPDATA%\gcloud                                          │
│                                                                  │
│  Linux/macOS:                                                │
│  ~/.config/gcloud/                                            │
└─────────────────────────────────────────────────────────────────┘

配置文件结构：

┌─────────────────────────────────────────────────────────────────┐
│  ~/.config/gcloud/                                            │
│  ├── config_syntax.ini    ← 主配置文件                         │
│  ├── credentials/         ← 认证凭证                          │
│  │   └── credential.json ← OAuth token                        │
│  ├── active_config        ← 当前配置名称                       │
│  └── configurations/     ← 多配置支持                         │
│      ├── config_default  ← 默认配置                          │
│      └── config_dev     ← 开发配置                           │
└─────────────────────────────────────────────────────────────────┘

配置内容示例（config_syntax.ini）：

[core]
project = my-project-123
account = user@example.com
region = us-central1
zone = us-central1-a
disable_usage_reporting = True

[compute]
region = us-central1
zone = us-central1-a

[container]
cluster = my-cluster
```

```
┌─────────────────────────────────────────────────────────────────┐
│              gcloud组件架构                                       │
└─────────────────────────────────────────────────────────────────┘

gcloud是模块化设计：

┌─────────────────────────────────────────────────────────────────┐
│  gcloud (核心CLI)                                              │
│     │                                                          │
│     ├── gcloud compute     ← 计算服务组件                     │
│     ├── gcloud container   ← 容器服务组件                     │
│     ├── gcloud storage     ← 存储服务组件                     │
│     ├── gcloud beta        ← Beta功能                         │
│     └── gcloud alpha       ← Alpha功能                         │
│                                                                  │
│  组件安装：                                                    │
│  gcloud components install kubectl                              │
│  gcloud components update                                      │
│  gcloud components list                                        │
└─────────────────────────────────────────────────────────────────┘

组件与API的对应关系：

┌─────────────────────────────────────────────────────────────────┐
│  gcloud compute → Compute Engine API                            │
│  gcloud container → Kubernetes Engine API                      │
│  gcloud storage → Cloud Storage API (通过gsutil)               │
│  gcloud bigquery → BigQuery API (通过bq)                      │
│  gcloud sql → Cloud SQL Admin API                              │
└─────────────────────────────────────────────────────────────────┘
```

---

### 1. Windows PowerShell中使用gcloud命令注意事项

- 使用反引号 ` 进行换行（不是反斜杠 \）
- 变量引用使用 `$env:VARIABLE` 或直接使用环境变量
- 多行命令使用反引号结尾

### 2. 项目ID vs 项目名称

- 项目ID：唯一的、不可更改的标识符（如 `my-project-123`）
- 项目名称：可更改的显示名称（如 `My Project`）
- 大多数命令使用项目ID

### 3. 获取帮助

```powershell
# 查看命令帮助
gcloud compute instances create --help

# 查看可用命令
gcloud --help

# 查看特定服务的命令
gcloud compute --help
```

---

## 速查表索引

快速查找特定命令：

- **登录认证**: `gcloud auth login`
- **设置项目**: `gcloud config set project`
- **创建VM**: `gcloud compute instances create`
- **部署Cloud Run**: `gcloud run deploy`
- **创建GKE集群**: `gcloud container clusters create`
- **创建存储桶**: `gsutil mb`
- **执行BigQuery**: `bq query`
- **创建数据库**: `gcloud sql instances create`
- **创建VPC**: `gcloud compute networks create`
- **添加IAM**: `gcloud projects add-iam-policy-binding`
- **创建Secret**: `gcloud secrets create`
- **部署函数**: `gcloud functions deploy`
- **触发构建**: `gcloud builds submit`

---

*最后更新：2024*
