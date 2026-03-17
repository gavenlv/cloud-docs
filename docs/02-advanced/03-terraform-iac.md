# 基础设施即代码（Terraform）

## 本章概述

基础设施即代码（IaC）是现代云运维的核心实践。本章将深入学习Terraform，掌握云资源自动化管理。

## 学习目标

- 理解IaC核心概念
- 掌握Terraform HCL语法
- 学会资源管理与依赖
- 掌握模块化设计
- 理解状态管理
- 能够编写生产级Terraform代码

---

## 1. IaC核心概念

### 1.1 什么是基础设施即代码

```
传统运维 vs IaC

传统运维                          IaC
┌─────────────────┐            ┌─────────────────┐
│ 手动创建资源     │            │ 代码定义资源     │
│ 手动配置服务     │            │ 版本控制管理     │
│ 文档记录步骤     │            │ 自动化部署       │
│ 难以复制环境     │            │ 环境可重复       │
│ 配置漂移常见     │            │ 一致性保证       │
└─────────────────┘            └─────────────────┘

IaC优势：
├── 版本控制
├── 可重复性
├── 一致性
├── 可审计
└── 协作友好
```

### 1.2 IaC工具对比

| 工具 | 类型 | 语言 | 特点 |
|-----|------|------|------|
| Terraform | 声明式 | HCL | 多云支持、状态管理 |
| CloudFormation | 声明式 | YAML/JSON | AWS原生、深度集成 |
| Pulumi | 声明式 | TypeScript/Python | 使用通用编程语言 |
| Ansible | 过程式 | YAML | 配置管理、无代理 |
| Chef/Puppet | 过程式 | Ruby | 配置管理 |

### 1.3 Terraform工作流程

```
Terraform工作流程

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   编写代码   │────►│   初始化    │────►│   规划      │
│  (.tf文件)  │     │  (init)     │     │  (plan)     │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   销毁      │◄────│   验证      │◄────│   应用      │
│  (destroy)  │     │  (验证)     │     │  (apply)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 2. HCL语法基础

### 2.1 基本语法

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  tags = {
    Name = "example-instance"
  }
}
```

### 2.2 数据类型

```hcl
variable "string_var" {
  type    = string
  default = "hello"
}

variable "number_var" {
  type    = number
  default = 42
}

variable "bool_var" {
  type    = bool
  default = true
}

variable "list_var" {
  type    = list(string)
  default = ["a", "b", "c"]
}

variable "map_var" {
  type = map(string)
  default = {
    key1 = "value1"
    key2 = "value2"
  }
}

variable "object_var" {
  type = object({
    name = string
    age  = number
  })
  default = {
    name = "John"
    age  = 30
  }
}

variable "tuple_var" {
  type    = tuple([string, number, bool])
  default = ["hello", 42, true]
}
```

### 2.3 变量与输出

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "example" {
  instance_type = var.instance_type
  
  tags = merge(local.common_tags, {
    Name = "example-${var.environment}"
  })
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.example.id
}

output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.example.public_ip
}
```

### 2.4 条件表达式

```hcl
variable "create_instance" {
  type    = bool
  default = true
}

variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_instance" "example" {
  count = var.create_instance ? 1 : 0
  
  instance_type = var.environment == "prod" ? "t3.medium" : "t3.micro"
}

locals {
  instance_count = {
    dev  = 1
    staging = 2
    prod = 3
  }
}

resource "aws_instance" "servers" {
  count = local.instance_count[var.environment]
}
```

### 2.5 循环

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_cidrs" {
  type = map(string)
  default = {
    public  = "10.0.1.0/24"
    private = "10.0.2.0/24"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "public-${var.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  for_each = var.subnet_cidrs
  
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  
  tags = {
    Name = "private-${each.key}"
  }
}

locals {
  security_group_rules = [
    {
      port     = 22
      protocol = "tcp"
      cidr     = "0.0.0.0/0"
    },
    {
      port     = 80
      protocol = "tcp"
      cidr     = "0.0.0.0/0"
    },
    {
      port     = 443
      protocol = "tcp"
      cidr     = "0.0.0.0/0"
    }
  ]
}

resource "aws_security_group_rule" "ingress" {
  count = length(local.security_group_rules)
  
  type              = "ingress"
  from_port         = local.security_group_rules[count.index].port
  to_port           = local.security_group_rules[count.index].port
  protocol          = local.security_group_rules[count.index].protocol
  cidr_blocks       = [local.security_group_rules[count.index].cidr]
  security_group_id = aws_security_group.main.id
}
```

---

## 3. 资源管理

### 3.1 资源依赖

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "example" {
  subnet_id = aws_subnet.main.id
  
  depends_on = [
    aws_security_group.main
  ]
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id
}
```

### 3.2 数据源

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  subnet_id     = data.aws_subnets.default.ids[0]
  instance_type = "t3.micro"
}
```

### 3.3 生命周期管理

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes = [
      ami,
      tags["LastModified"]
    ]
  }
}

resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  lifecycle {
    create_before_destroy = true
  }
}
```

---

## 4. 模块化设计

### 4.1 模块结构

```
modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── ec2/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── rds/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

environments/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars
```

### 4.2 模块定义

```hcl
modules/vpc/variables.tf

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

```hcl
modules/vpc/main.tf

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = merge(var.tags, {
    Name = "vpc-${var.environment}"
  })
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "public-${var.availability_zones[count.index]}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "private-${var.availability_zones[count.index]}"
    Type = "private"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "igw-${var.environment}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "nat-${var.availability_zones[count.index]}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "eip-nat-${var.availability_zones[count.index]}"
  })
}
```

```hcl
modules/vpc/outputs.tf

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}
```

### 4.3 模块使用

```hcl
environments/dev/main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  environment          = "dev"
  
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "ec2" {
  source = "../../modules/ec2"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  instance_count     = 2
  instance_type      = "t3.micro"
  environment        = "dev"
  
  depends_on = [module.vpc]
}
```

---

## 5. 状态管理

### 5.1 远程状态

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-key"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### 5.2 状态锁定

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name = "terraform-state-lock"
  }
}
```

### 5.3 状态命令

```bash
terraform init                    # 初始化
terraform plan                    # 预览变更
terraform apply                   # 应用变更
terraform apply -auto-approve     # 自动批准
terraform destroy                 # 销毁资源

terraform state list              # 列出资源
terraform state show aws_vpc.main # 显示资源详情
terraform state mv aws_vpc.main aws_vpc.primary  # 移动资源
terraform state rm aws_vpc.main   # 从状态中移除

terraform import aws_vpc.main vpc-12345678  # 导入资源
terraform taint aws_instance.example        # 标记重建
terraform untaint aws_instance.example      # 取消标记

terraform workspace list          # 列出工作空间
terraform workspace new dev       # 创建工作空间
terraform workspace select dev    # 切换工作空间
```

---

## 6. 实操项目

### 项目：完整VPC架构

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  name_prefix = "${var.environment}-project"
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "CloudDocs"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
    Type = "private"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-${var.availability_zones[count.index]}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_public_ips" {
  value = aws_eip.nat[*].public_ip
}
```

---

## 7. 知识检测

### 选择题

1. Terraform使用什么语言？
   - A. YAML
   - B. JSON
   - C. HCL
   - D. Python

2. 哪个命令用于预览变更？
   - A. terraform init
   - B. terraform plan
   - C. terraform apply
   - D. terraform show

3. 如何导入已存在的资源？
   - A. terraform apply
   - B. terraform import
   - C. terraform add
   - D. terraform create

---

## 8. 扩展阅读

- [Terraform官方文档](https://developer.hashicorp.com/terraform/docs)
- [Terraform最佳实践](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
- [Terraform模块注册表](https://registry.terraform.io/)

---

## 学习进度

- [ ] 理解IaC核心概念
- [ ] 掌握HCL语法
- [ ] 掌握资源管理
- [ ] 掌握模块化设计
- [ ] 理解状态管理
- [ ] 完成实操项目
