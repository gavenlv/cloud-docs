# Terraform常见错误处理

## 8.1 状态文件相关错误

### 8.1.1 状态文件锁定错误

**错误信息：**
```
Error: Error acquiring the state lock

Error message: Error acquiring the state lock: Lock info:
  ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Path:      gs://my-terraform-state/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@example.com
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.000 UTC

Lock Info:
  ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Path:      gs://my-terraform-state/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@example.com
  Version:   1.5.0
  Created:   2024-01-15 10:30:00.000 UTC
```

**原因分析：**

```
状态锁定机制：

┌─────────────────────────────────────────────────────────────────┐
│  状态锁定原理                                             │
└─────────────────────────────────────────────────────────────────┘

1. 锁定流程
   ├── Terraform在操作前检查状态锁定
   ├── 如果锁定存在，拒绝操作
   ├── 如果锁定不存在，创建锁定
   ├── 执行操作
   └── 操作完成后释放锁定

2. 锁定信息
   ├── Lock ID：唯一标识符
   ├── Path：状态文件路径
   ├── Operation：操作类型（apply/plan/destroy）
   ├── Who：操作者信息
   ├── Version：Terraform版本
   └── Created：锁定创建时间

3. 锁定后端
   ├── 本地后端：.terraform.lock.hcl文件
   ├── GCS后端：.terraform.lock文件
   ├── S3后端：DynamoDB表
   └── Consul后端：Consul KV存储
```

**解决方案：**

```bash
# 方案1：等待锁定自动释放
# 锁定通常在操作完成后自动释放
# 如果操作异常终止，可能需要手动释放

# 方案2：强制解锁（谨慎使用）
terraform force-unlock <LOCK_ID>

# 示例：
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# 方案3：检查锁定状态
# GCS后端
gsutil stat gs://my-terraform-state/.terraform.lock

# S3后端
aws s3api get-object \
  --bucket my-terraform-state \
  --key .terraform.lock \
  /tmp/lock.json

# 方案4：删除锁定文件（最后手段）
# 本地后端
rm -f .terraform.lock.hcl

# GCS后端
gsutil rm gs://my-terraform-state/.terraform.lock

# S3后端
aws s3 rm s3://my-terraform-state/.terraform.lock
```

**预防措施：**

```bash
# 1. 使用远程后端
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"
  }
}

# 2. 设置锁定超时
# GCS后端默认锁定超时为5分钟
# 可以通过环境变量调整
export TF_LOCK_TIMEOUT=10m

# 3. 使用工作空间隔离
terraform workspace select dev
# 每个工作空间有独立的状态锁定

# 4. 避免并发操作
# 在CI/CD中使用互斥锁
# 或使用Terraform Cloud的自动队列
```

### 8.1.2 状态文件不一致错误

**错误信息：**
```
Error: Error refreshing state: error reading state

Error message: state data in S3 does not have the expected content
```

**原因分析：**

```
状态不一致原因：

┌─────────────────────────────────────────────────────────────────┐
│  状态不一致场景                                           │
└─────────────────────────────────────────────────────────────────┘

1. 手动修改状态文件
   ├── 直接编辑terraform.tfstate文件
   ├── 使用terraform state命令修改
   └── 使用第三方工具修改

2. 并发修改
   ├── 多个用户同时修改状态
   ├── 多个CI/CD任务同时运行
   └── 状态锁定失效

3. 后端故障
   ├── 网络中断
   ├── 存储服务故障
   └── 权限变更

4. 版本不兼容
   ├── Terraform版本升级
   ├── Provider版本升级
   └── 状态文件格式变更
```

**解决方案：**

```bash
# 方案1：刷新状态
terraform refresh

# 方案2：重新初始化
terraform init -reconfigure

# 方案3：从备份恢复
# 1. 备份当前状态
terraform state pull > current-state-backup.tfstate

# 2. 恢复备份
terraform state push backup-state.tfstate

# 3. 验证状态
terraform state list

# 方案4：重新导入资源
# 1. 删除不一致的资源状态
terraform state rm google_compute_instance.web_server

# 2. 重新导入资源
terraform import google_compute_instance.web_server \
  projects/my-project-id/zones/us-central1-a/instances/web-server

# 方案5：重建状态（最后手段）
# 1. 备份配置
cp main.tf main.tf.backup

# 2. 删除状态文件
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# 3. 重新初始化
terraform init

# 4. 导入现有资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>
```

**预防措施：**

```bash
# 1. 定期备份状态
# 添加到CI/CD流程
terraform state pull > state-backup-$(date +%Y%m%d).tfstate

# 2. 使用版本控制
# 将状态文件纳入版本控制（不推荐生产环境）
# 或使用专门的版本化存储

# 3. 启用状态版本化
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # GCS自动版本化
    # 每次更新都会创建新版本
  }
}

# 4. 监控状态变更
# 使用Terraform Cloud的状态监控
# 或自定义监控脚本
```

### 8.1.3 状态文件丢失错误

**错误信息：**
```
Error: Error loading state: state file was not found

Error message: open terraform.tfstate: no such file or directory
```

**原因分析：**

```
状态文件丢失原因：

┌─────────────────────────────────────────────────────────────────┐
│  状态文件丢失场景                                         │
└─────────────────────────────────────────────────────────────────┘

1. 意外删除
   ├── 手动删除状态文件
   ├── 清理脚本误删
   └── 存储桶清空

2. 存储故障
   ├── 存储服务故障
   ├── 网络中断
   └── 权限变更

3. 工作空间切换
   ├── 切换到不存在的工作空间
   ├── 工作空间状态文件丢失
   └── 工作空间配置错误

4. 后端配置错误
   ├── 后端路径错误
   ├── 后端配置变更
   └── 凭证失效
```

**解决方案：**

```bash
# 方案1：从备份恢复
# 如果有备份
terraform state push backup-state.tfstate

# 方案2：从远程后端恢复
# GCS
gsutil cp \
  gs://my-terraform-state/terraform.tfstate.backup \
  terraform.tfstate

# S3
aws s3 cp \
  s3://my-terraform-state/terraform.tfstate.backup \
  terraform.tfstate

# 方案3：重新导入所有资源
# 1. 查询现有资源
gcloud compute instances list
gcloud compute networks list

# 2. 重新导入
terraform import google_compute_network.vpc \
  projects/my-project-id/global/networks/my-vpc

terraform import google_compute_instance.web_server \
  projects/my-project-id/zones/us-central1-a/instances/web-server

# 方案4：重建状态（从配置）
# 1. 创建新状态
terraform init

# 2. 导入资源
terraform import <RESOURCE_ADDRESS> <IMPORT_ID>

# 3. 验证状态
terraform state list
terraform plan
```

**预防措施：**

```bash
# 1. 启用状态版本化
terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "production"
    credentials = "path/to/service-account.json"

    # GCS自动版本化
    # 可以恢复到任意版本
  }
}

# 2. 定期备份
# 添加到cron任务
0 0 * * * terraform state pull > /backup/terraform-state-$(date +\%Y\%m\%d).tfstate

# 3. 使用Terraform Cloud
# Terraform Cloud提供自动备份
# 可以恢复到任意历史版本

# 4. 监控状态文件
# 设置告警
# 当状态文件丢失时立即通知
```

---

## 8.2 部署相关错误

### 8.2.1 资源创建失败错误

**错误信息：**
```
Error: Error creating instance: googleapi: Error 403: Insufficient Permission

Error message: googleapi: Error 403: The caller does not have permission
```

**原因分析：**

```
资源创建失败原因：

┌─────────────────────────────────────────────────────────────────┐
│  资源创建失败场景                                         │
└─────────────────────────────────────────────────────────────────┘

1. 权限不足
   ├── 服务账号权限不足
   ├── IAM策略配置错误
   └── 资源配额限制

2. 配置错误
   ├── 资源名称冲突
   ├── 参数值无效
   └── 依赖关系错误

3. 资源限制
   ├── 配额超限
   ├── 区域不可用
   └── 资源类型不支持

4. 网络问题
   ├── 网络连接失败
   ├── DNS解析失败
   └── 防火墙规则阻止
```

**解决方案：**

```bash
# 方案1：检查权限
# 1. 检查服务账号权限
gcloud iam service-accounts get-iam-policy \
  terraform@my-project-id.iam.gserviceaccount.com

# 2. 检查项目权限
gcloud projects get-iam-policy my-project-id

# 3. 测试权限
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --project=my-project-id

# 方案2：检查配额
# 1. 查看配额
gcloud compute project-info describe \
  --project=my-project-id

# 2. 查看特定配额
gcloud compute regions describe us-central1 \
  --project=my-project-id \
  --format="table(quotas.metric,quotas.limit,quotas.usage)"

# 3. 申请配额增加
# 访问GCP控制台申请配额增加

# 方案3：检查配置
# 1. 验证配置
terraform validate

# 2. 查看执行计划
terraform plan -out=tfplan

# 3. 查看详细错误
TF_LOG=DEBUG terraform apply

# 方案4：分步部署
# 1. 先创建依赖资源
terraform apply -target=google_compute_network.vpc

# 2. 再创建其他资源
terraform apply -target=google_compute_instance.web_server

# 3. 最后应用所有资源
terraform apply
```

**预防措施：**

```bash
# 1. 使用最小权限原则
# 只授予必要的权限
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# 2. 使用条件IAM
# 限制访问范围
gcloud projects add-iam-policy-binding my-project-id \
  --member="serviceAccount:terraform@my-project-id.iam.gserviceaccount.com" \
  --role="roles/compute.admin" \
  --condition="title='Only from specific IP',expression='request.ip in ['1.2.3.4/32']"

# 3. 监控配额使用
# 设置配额告警
gcloud alpha monitoring policies create \
  --policy-from-file=quota-policy.yaml

# 4. 使用预检查
# 在部署前检查权限和配额
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes[] | select(.change.actions[] == "create")'
```

### 8.2.2 依赖关系错误

**错误信息：**
```
Error: Error: Cycle: module.vpc.google_compute_network.vpc, module.subnet.google_compute_subnetwork.subnet

Error message: Cycle: module.vpc.google_compute_network.vpc, module.subnet.google_compute_subnetwork.subnet
```

**原因分析：**

```
依赖关系错误原因：

┌─────────────────────────────────────────────────────────────────┐
│  依赖关系错误场景                                         │
└─────────────────────────────────────────────────────────────────┘

1. 循环依赖
   ├── 资源A依赖资源B
   ├── 资源B依赖资源A
   └── 形成循环

2. 隐式依赖
   ├── 使用depends_on创建不必要的依赖
   ├── 输出值创建隐式依赖
   └── 数据源创建隐式依赖

3. 模块间依赖
   ├── 模块A依赖模块B
   ├── 模块B依赖模块A
   └── 形成循环

4. 条件依赖
   ├── 条件资源创建依赖
   ├── 动态块创建依赖
   └── 循环创建依赖
```

**解决方案：**

```bash
# 方案1：查看依赖图
# 生成依赖图
terraform graph | dot -Tpng > dependency-graph.png

# 查看文本依赖图
terraform graph

# 方案2：移除不必要的依赖
# 错误示例
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_compute_network" "vpc" {
  name = "my-vpc"

  depends_on = [
    google_compute_subnetwork.subnet  # 错误：循环依赖
  ]
}

# 正确示例
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

# 方案3：拆分模块
# 错误示例：模块间循环依赖
module "vpc" {
  source = "./modules/vpc"
}

module "subnet" {
  source = "./modules/subnet"
  vpc_id  = module.vpc.vpc_id
}

module "vpc" {
  source = "./modules/vpc"
  subnet_id = module.subnet.subnet_id  # 错误：循环依赖
}

# 正确示例：拆分模块
module "network" {
  source = "./modules/network"
}

# 方案4：使用数据源
# 错误示例：循环依赖
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_compute_network" "vpc" {
  name = "my-vpc"
  subnet_id = google_compute_subnetwork.subnet.id  # 错误：循环依赖
}

# 正确示例：使用数据源
data "google_compute_network" "existing_vpc" {
  name = "existing-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = data.google_compute_network.existing_vpc.id
}
```

**预防措施：**

```bash
# 1. 使用隐式依赖
# 避免使用depends_on
# 让Terraform自动推断依赖关系

# 2. 查看依赖图
# 在部署前检查依赖关系
terraform graph

# 3. 使用模块化设计
# 将相关资源放在同一模块
# 减少模块间依赖

# 4. 使用数据源
# 避免循环依赖
# 使用数据源查询现有资源
```

### 8.2.3 超时错误

**错误信息：**
```
Error: Error waiting for instance to create: timeout while waiting for state to become 'RUNNING'

Error message: timeout while waiting for state to become 'RUNNING'
```

**原因分析：**

```
超时错误原因：

┌─────────────────────────────────────────────────────────────────┐
│  超时错误场景                                             │
└─────────────────────────────────────────────────────────────────┘

1. 资源创建时间过长
   ├── 大型实例创建
   ├── 镜像下载缓慢
   └── 网络延迟

2. 资源状态异常
   ├── 资源创建失败
   ├── 资源状态卡住
   └── 资源配置错误

3. 网络问题
   ├── 网络连接不稳定
   ├── DNS解析失败
   └── 防火墙规则阻止

4. 配额限制
   ├── 并发创建限制
   ├── API速率限制
   └── 资源配额限制
```

**解决方案：**

```bash
# 方案1：增加超时时间
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"

  timeouts {
    create = "30m"  # 默认10分钟
    update = "30m"
    delete = "30m"
  }
}

# 方案2：分步创建
# 1. 先创建基础资源
terraform apply -target=google_compute_network.vpc

# 2. 再创建其他资源
terraform apply -target=google_compute_instance.web_server

# 3. 最后应用所有资源
terraform apply

# 方案3：检查资源状态
# 1. 手动检查资源状态
gcloud compute instances describe web-server \
  --zone=us-central1-a \
  --project=my-project-id

# 2. 查看资源日志
gcloud compute instances get-serial-port-output web-server \
  --zone=us-central1-a \
  --project=my-project-id \
  --port=1

# 方案4：删除卡住的资源
# 1. 手动删除资源
gcloud compute instances delete web-server \
  --zone=us-central1-a \
  --project=my-project-id

# 2. 从状态中移除
terraform state rm google_compute_instance.web_server

# 3. 重新创建
terraform apply
```

**预防措施：**

```bash
# 1. 设置合理的超时时间
# 根据资源类型设置超时
# 大型实例设置更长的超时

# 2. 使用预构建镜像
# 减少镜像下载时间
# 使用自定义镜像

# 3. 优化网络
# 使用更快的网络
# 减少网络延迟

# 4. 监控资源创建
# 使用Terraform Cloud的实时日志
# 或自定义监控脚本
```

---

## 8.3 配置相关错误

### 8.3.1 语法错误

**错误信息：**
```
Error: Error loading config: Error reading main.tf: 1:1: unknown token

Error message: 1:1: unknown token
```

**原因分析：**

```
语法错误原因：

┌─────────────────────────────────────────────────────────────────┐
│  语法错误场景                                             │
└─────────────────────────────────────────────────────────────────┘

1. 拼写错误
   ├── 资源名称拼写错误
   ├── 参数名称拼写错误
   └── 变量名称拼写错误

2. 格式错误
   ├── 缺少引号
   ├── 缺少括号
   └── 缺少逗号

3. 类型错误
   ├── 参数类型不匹配
   ├── 变量类型不匹配
   └── 表达式类型不匹配

4. 版本不兼容
   ├── Terraform版本过低
   ├── Provider版本过低
   └── 语法不支持
```

**解决方案：**

```bash
# 方案1：使用格式化工具
# 自动修复格式错误
terraform fmt

# 检查格式
terraform fmt -check

# 方案2：验证配置
# 验证语法
terraform validate

# 方案3：查看详细错误
# 启用调试日志
TF_LOG=DEBUG terraform validate

# 方案4：检查版本
# 检查Terraform版本
terraform version

# 检查Provider版本
terraform providers
```

**预防措施：**

```bash
# 1. 使用IDE插件
# VS Code插件：hashicorp.terraform
# 语法高亮
# 自动补全
# 错误提示

# 2. 使用pre-commit钩子
# 在提交前验证
#!/bin/bash
terraform fmt -check
terraform validate

# 3. 使用CI/CD验证
# 在PR中验证
name: Terraform Validate
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check
      - run: terraform validate

# 4. 使用版本约束
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
```

### 8.3.2 变量未定义错误

**错误信息：**
```
Error: Error: No value for required variable

Error message: on main.tf line 10, in resource "google_compute_instance" "web_server":
  10:   project = var.project_id

The root module does not have a variable named "project_id". To pass a value
to this variable use the -var or -var-file command line flags.
```

**原因分析：**

```
变量未定义原因：

┌─────────────────────────────────────────────────────────────────┐
│  变量未定义场景                                           │
└─────────────────────────────────────────────────────────────────┘

1. 变量未定义
   ├── 使用了未定义的变量
   ├── 变量名称拼写错误
   └── 变量文件未加载

2. 变量未赋值
   ├── 必需变量未赋值
   ├── 变量文件路径错误
   └── 环境变量未设置

3. 变量类型错误
   ├── 变量类型不匹配
   ├── 变量值格式错误
   └── 变量验证失败
```

**解决方案：**

```bash
# 方案1：定义变量
# 在variables.tf中定义
variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

# 方案2：提供变量值
# 方法1：命令行
terraform apply -var="project_id=my-project-id"

# 方法2：变量文件
terraform apply -var-file="terraform.tfvars"

# 方法3：环境变量
export TF_VAR_project_id="my-project-id"
terraform apply

# 方法4：自动加载
# 创建terraform.tfvars文件
project_id = "my-project-id"
region = "us-central1"

# 方案3：设置默认值
variable "project_id" {
  description = "GCP项目ID"
  type        = string
  default     = "my-project-id"
}

# 方案4：使用交互式输入
terraform apply
# Terraform会提示输入变量值
```

**预防措施：**

```bash
# 1. 定义所有变量
# 在variables.tf中定义所有变量
variable "project_id" {
  description = "GCP项目ID"
  type        = string
  default     = "my-project-id"
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

# 2. 提供示例变量文件
# 创建terraform.tfvars.example
project_id = "my-project-id"
region = "us-central1"

# 3. 使用环境变量
# 在CI/CD中使用
export TF_VAR_project_id="my-project-id"
export TF_VAR_region="us-central1"

# 4. 验证变量
# 检查变量定义
terraform validate

# 查看变量
terraform output -json | jq '.values'
```

### 8.3.3 Provider配置错误

**错误信息：**
```
Error: Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.

Error message: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
```

**原因分析：**

```
Provider配置错误原因：

┌─────────────────────────────────────────────────────────────────┐
│  Provider配置错误场景                                       │
└─────────────────────────────────────────────────────────────────┘

1. 凭证错误
   ├── 凭证未配置
   ├── 凭证路径错误
   ├── 凭证格式错误
   └── 凭证权限不足

2. 版本错误
   ├── Provider版本不匹配
   ├── Terraform版本不兼容
   └── 插件下载失败

3. 配置错误
   ├── Provider配置错误
   ├── 参数值错误
   └── 配置文件错误
```

**解决方案：**

```bash
# 方案1：检查凭证
# 1. 检查环境变量
echo $GOOGLE_CREDENTIALS
echo $GOOGLE_APPLICATION_CREDENTIALS

# 2. 检查凭证文件
cat ~/service-account.json

# 3. 测试凭证
gcloud auth application-default print-access-token

# 方案2：重新初始化
terraform init -reconfigure

# 方案3：检查版本
# 1. 检查Terraform版本
terraform version

# 2. 检查Provider版本
terraform providers

# 3. 更新Provider
terraform init -upgrade

# 方案4：检查配置
# 1. 验证配置
terraform validate

# 2. 查看执行计划
terraform plan

# 3. 查看详细错误
TF_LOG=DEBUG terraform plan
```

**预防措施：**

```bash
# 1. 使用环境变量
# 设置凭证环境变量
export GOOGLE_CREDENTIALS=$(cat ~/service-account.json)

# 2. 使用Workload Identity
# 避免使用长期凭证
# 使用临时令牌

# 3. 版本约束
# 指定Provider版本
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# 4. 验证配置
# 在部署前验证
terraform validate
terraform plan
```

---

## 8.4 网络相关错误

### 8.4.1 网络连接错误

**错误信息：**
```
Error: Error: Provider request failed: Get "https://www.googleapis.com/compute/v1/projects/my-project-id/regions/us-central1": dial tcp: lookup www.googleapis.com: no such host

Error message: dial tcp: lookup www.googleapis.com: no such host
```

**原因分析：**

```
网络连接错误原因：

┌─────────────────────────────────────────────────────────────────┐
│  网络连接错误场景                                         │
└─────────────────────────────────────────────────────────────────┘

1. DNS解析失败
   ├── DNS服务器配置错误
   ├── DNS缓存问题
   └── DNS记录错误

2. 网络连接失败
   ├── 网络中断
   ├── 防火墙阻止
   └── 代理配置错误

3. API不可用
   ├── GCP API故障
   ├── 区域不可用
   └── 服务降级
```

**解决方案：**

```bash
# 方案1：检查DNS
# 1. 测试DNS解析
nslookup www.googleapis.com
dig www.googleapis.com

# 2. 刷新DNS缓存
# Linux
sudo systemd-resolve --flush-caches

# macOS
sudo dscacheutil -flushcache

# Windows
ipconfig /flushdns

# 方案2：检查网络连接
# 1. 测试网络连接
ping www.googleapis.com

# 2. 测试API连接
curl https://www.googleapis.com/compute/v1/projects

# 3. 测试代理
curl -x http://proxy.example.com:8080 \
  https://www.googleapis.com/compute/v1/projects

# 方案3：配置代理
# 设置HTTP代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# 在Terraform配置中设置
provider "google" {
  project = "my-project-id"
  region  = "us-central1"

  http_proxy {
    url = "http://proxy.example.com:8080"
  }
}

# 方案4：检查GCP状态
# 1. 检查GCP状态
curl https://status.cloud.google.com/

# 2. 检查API状态
gcloud services list --enabled
```

**预防措施：**

```bash
# 1. 使用可靠的DNS
# 配置公共DNS
# 或使用企业DNS

# 2. 配置代理
# 在企业环境中配置代理
# 或使用VPN

# 3. 监控网络
# 设置网络监控
# 及时发现网络问题

# 4. 使用重试机制
# 在Terraform配置中设置重试
provider "google" {
  project = "my-project-id"
  region  = "us-central1"

  request_timeout = "60s"
  request_retry = {
    max_retries = 5
    retry_delay  = "5s"
  }
}
```

### 8.4.2 API速率限制错误

**错误信息：**
```
Error: Error: Error waiting for instance to create: googleapi: Error 429: Quota exceeded for quota metric 'Create requests' and limit 'Create requests limit' of service 'compute.googleapis.com'

Error message: Quota exceeded for quota metric 'Create requests' and limit 'Create requests limit' of service 'compute.googleapis.com'
```

**原因分析：**

```
API速率限制原因：

┌─────────────────────────────────────────────────────────────────┐
│  API速率限制场景                                           │
└─────────────────────────────────────────────────────────────────┘

1. 并发请求过多
   ├── 同时创建多个资源
   ├── 并发CI/CD任务
   └── 批量操作

2. API配额限制
   ├── 创建请求限制
   ├── 读取请求限制
   └── 更新请求限制

3. 区域限制
   ├── 区域配额限制
   ├── 区域API限制
   └── 区域不可用
```

**解决方案：**

```bash
# 方案1：减少并发
# 1. 使用串行创建
resource "google_compute_instance" "web_server" {
  count = 3
  name  = "web-server-${count.index}"

  # Terraform默认串行创建
  # 可以使用parallelism控制并发
}

# 2. 使用Terraform并发控制
terraform apply -parallelism=1

# 方案2：分批创建
# 1. 分批创建资源
terraform apply -target=google_compute_instance.web_server[0]
terraform apply -target=google_compute_instance.web_server[1]
terraform apply -target=google_compute_instance.web_server[2]

# 2. 使用sleep延迟
resource "google_compute_instance" "web_server" {
  count = 3
  name  = "web-server-${count.index}"

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# 方案3：申请配额增加
# 1. 查看配额
gcloud compute project-info describe \
  --project=my-project-id

# 2. 申请配额增加
# 访问GCP控制台申请配额增加

# 方案4：使用指数退避
# 在CI/CD中使用指数退避
#!/bin/bash
for i in {1..3}; do
  terraform apply -auto-approve && break
  sleep $((2 ** i))
done
```

**预防措施：**

```bash
# 1. 使用串行创建
# 控制并发数量
terraform apply -parallelism=1

# 2. 监控配额使用
# 设置配额告警
gcloud alpha monitoring policies create \
  --policy-from-file=quota-policy.yaml

# 3. 使用批量操作
# 使用Terraform的批量操作
# 减少API调用次数

# 4. 优化资源创建
# 使用实例模板
# 使用实例组
# 减少API调用
```

---

## 8.5 调试技巧

### 8.5.1 启用调试日志

```bash
# 启用调试日志
export TF_LOG=DEBUG

# 指定日志文件
export TF_LOG_PATH=terraform.log

# 运行Terraform
terraform apply

# 查看日志
cat terraform.log

# 日志级别：
# TRACE：最详细的日志
# DEBUG：调试信息
# INFO：一般信息
# WARN：警告信息
# ERROR：错误信息
```

### 8.5.2 使用JSON输出

```bash
# 生成JSON格式的执行计划
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# 分析执行计划
cat plan.json | jq '.resource_changes[] | select(.change.actions[] == "create")'

# 查看资源变更
cat plan.json | jq '.resource_changes[] | {address: .address, actions: .change.actions}'
```

### 8.5.3 使用状态命令

```bash
# 列出状态中的资源
terraform state list

# 显示资源详细信息
terraform state show google_compute_instance.web_server

# 从状态中移除资源
terraform state rm google_compute_instance.web_server

# 移动资源
terraform state mv google_compute_instance.web_server google_compute_instance.web_server_new

# 拉取状态
terraform state pull > state.json

# 推送状态
terraform state push state.json
```

### 8.5.4 使用依赖图

```bash
# 生成依赖图
terraform graph > graph.dot

# 转换为PNG
dot -Tpng graph.dot -o graph.png

# 查看依赖图
# 使用Graphviz查看graph.png

# 查看文本依赖图
terraform graph
```

---

## 本章小结

- 状态文件锁定需要谨慎处理
- 状态不一致需要及时恢复
- 部署失败需要检查权限和配置
- 依赖关系错误需要查看依赖图
- 超时错误需要增加超时时间
- 语法错误需要使用格式化工具
- 变量未定义需要定义变量或提供值
- Provider配置错误需要检查凭证和版本
- 网络连接错误需要检查DNS和代理
- API速率限制需要减少并发

---

**推荐资源**

- [Terraform故障排查](https://www.terraform.io/docs/troubleshooting)
- [GCP错误代码](https://cloud.google.com/apis/docs/errors)
- [Terraform社区论坛](https://discuss.hashicorp.com/c/terraform-core)
