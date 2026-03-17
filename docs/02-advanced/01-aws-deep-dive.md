# AWS深入路径

## 本章概述

本章将深入学习AWS核心服务，掌握AWS平台的高级特性和最佳实践。

## 学习目标

- 掌握EC2高级特性与最佳实践
- 理解S3高级功能与存储策略
- 掌握RDS与Aurora数据库
- 理解Lambda无服务器计算
- 掌握CloudFormation基础设施即代码
- 熟练使用CloudWatch监控与日志

---

## 1. EC2深入

### 1.1 实例类型详解

```
EC2实例类型命名规则

示例：m5.large
│  │  │
│  │  └── 实例大小
│  └───── 实例代数
└──────── 实例系列

实例系列：
├── 通用型：T3, T4g, M5, M6, M6i
├── 计算优化：C5, C6, C6i
├── 内存优化：R5, R6, X2, z1d
├── 存储优化：I3, I4, D3, H1
├── 加速计算：P4, P3, G5, Inf1
└── Graviton(Arm)：T4g, M6g, C6g, R6g
```

### 1.2 实例购买选项

| 选项 | 特点 | 折扣 | 适用场景 |
|-----|------|------|---------|
| On-Demand | 按秒计费 | 无 | 短期、不可预测 |
| Reserved | 1年或3年承诺 | 最高72% | 稳定工作负载 |
| Savings Plans | 承诺消费金额 | 最高72% | 灵活的工作负载 |
| Spot | 竞价实例 | 最高90% | 容错、批处理 |
| Dedicated | 专用主机 | 无 | 合规要求 |

### 1.3 Placement Groups

```
Placement Groups类型

Cluster（集群）
┌─────────────────────────────────┐
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐      │
│  │EC2│ │EC2│ │EC2│ │EC2│      │
│  └───┘ └───┘ └───┘ └───┘      │
│        同一可用区               │
│    低延迟、高吞吐               │
└─────────────────────────────────┘

Spread（分散）
┌─────────────────────────────────┐
│  AZ-A        AZ-B        AZ-C   │
│  ┌───┐      ┌───┐      ┌───┐   │
│  │EC2│      │EC2│      │EC2│   │
│  └───┘      └───┘      └───┘   │
│        不同硬件/可用区           │
│       高可用、关键实例           │
└─────────────────────────────────┘

Partition（分区）
┌─────────────────────────────────┐
│  Partition 1  Partition 2       │
│  ┌─┐ ┌─┐ ┌─┐  ┌─┐ ┌─┐ ┌─┐     │
│  │ │ │ │ │ │  │ │ │ │ │ │     │
│  └─┘ └─┘ └─┘  └─┘ └─┘ └─┘     │
│      大型分布式系统              │
│      Hadoop、Cassandra          │
└─────────────────────────────────┘
```

### 1.4 实例存储与EBS

**EBS卷类型**：

| 类型 | 名称 | 最大IOPS | 最大吞吐量 | 用途 |
|-----|------|---------|-----------|------|
| gp3 | 通用SSD | 16,000 | 1,000 MB/s | 通用工作负载 |
| io2 | 预置IOPS | 256,000 | 4,000 MB/s | 数据库 |
| st1 | 吞吐优化HDD | 500 | 500 MB/s | 大数据 |
| sc1 | 冷HDD | 250 | 250 MB/s | 冷数据 |

**EBS快照**：
```bash
aws ec2 create-snapshot \
    --volume-id vol-12345678 \
    --description "Daily backup"

aws ec2 create-volume \
    --snapshot-id snap-12345678 \
    --volume-type gp3 \
    --availability-zone us-east-1a
```

### 1.5 实战：高可用Web服务器

```yaml
template.yaml (CloudFormation):

Parameters:
  VpcId:
    Type: AWS::EC2::VPC::Id
  SubnetIds:
    Type: List<AWS::EC2::Subnet::Id>

Resources:
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Web Server Security Group
      VpcId: !Ref VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  WebServerLaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        InstanceType: t3.medium
        ImageId: ami-0c55b159cbfafe1f0
        SecurityGroupIds:
          - !Ref WebServerSecurityGroup
        UserData: !Base64 |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd

  WebServerASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      VPCZoneIdentifier: !Ref SubnetIds
      LaunchTemplate:
        LaunchTemplateId: !Ref WebServerLaunchTemplate
        Version: !GetAtt WebServerLaunchTemplate.LatestVersionNumber
      MinSize: 2
      MaxSize: 6
      TargetGroupARNs:
        - !Ref WebServerTargetGroup

  WebServerTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Port: 80
      Protocol: HTTP
      VpcId: !Ref VpcId
      HealthCheckPath: /health

  WebServerLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets: !Ref SubnetIds
      Type: application
```

---

## 2. S3深入

### 2.1 存储类别

```
S3存储类别层级

┌─────────────────────────────────────────────────┐
│ S3 Standard                                     │
│ 频繁访问数据                                     │
│ 毫秒级访问                                       │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ S3 Standard-IA (Infrequent Access)              │
│ 不频繁访问数据                                   │
│ 最小存储期：30天                                 │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ S3 One Zone-IA                                  │
│ 不频繁访问、可重建数据                           │
│ 单可用区存储                                     │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ S3 Glacier Instant Retrieval                    │
│ 归档数据、即时访问                               │
│ 最小存储期：90天                                 │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ S3 Glacier Flexible Retrieval                   │
│ 归档数据、分钟到小时检索                         │
│ 最小存储期：90天                                 │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│ S3 Glacier Deep Archive                         │
│ 长期归档、12-48小时检索                          │
│ 最小存储期：180天                                │
└─────────────────────────────────────────────────┘
```

### 2.2 生命周期策略

```json
{
  "Rules": [
    {
      "ID": "MoveToIA",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "logs/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    },
    {
      "ID": "DeleteOldVersions",
      "Status": "Enabled",
      "Filter": {},
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 30
      }
    }
  ]
}
```

### 2.3 S3高级功能

**版本控制**：
```bash
aws s3api put-bucket-versioning \
    --bucket my-bucket \
    --versioning-configuration Status=Enabled

aws s3api list-object-versions \
    --bucket my-bucket \
    --prefix file.txt
```

**跨区域复制**：
```json
{
  "Role": "arn:aws:iam::123456789012:role/s3-replication-role",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 1,
      "DeleteMarkerReplication": { "Status": "Disabled" },
      "Filter": {},
      "Destination": {
        "Bucket": "arn:aws:s3:::destination-bucket",
        "StorageClass": "STANDARD"
      }
    }
  ]
}
```

**S3 Select**：
```bash
aws s3api select-object-content \
    --bucket my-bucket \
    --key data.csv \
    --expression "SELECT * FROM s3object s WHERE s.age > 25" \
    --expression-type SQL \
    --input-serialization '{"CSV": {}}' \
    --output-serialization '{"CSV": {}}' \
    output.csv
```

### 2.4 S3最佳实践

```
S3性能优化

1. 命名优化
   ├── 使用前缀分散热点
   │   如：2024/01/15/file1.jpg
   │       2024/01/16/file2.jpg
   └── 避免顺序命名

2. 分片上传
   ├── 大于100MB推荐使用
   ├── 大于5GB必须使用
   └── 并行上传提高速度

3. S3 Transfer Acceleration
   ├── 全球加速传输
   └── 适合跨区域大文件

4. S3事件通知
   ├── SNS通知
   ├── SQS队列
   └── Lambda触发
```

---

## 3. RDS与Aurora

### 3.1 RDS引擎支持

| 引擎 | 版本 | 特点 |
|-----|------|------|
| MySQL | 5.7, 8.0 | 开源、广泛使用 |
| PostgreSQL | 12-15 | 高级特性、扩展性强 |
| MariaDB | 10.x | MySQL兼容、开源 |
| Oracle | 12c, 19c | 企业级、商业授权 |
| SQL Server | 2016-2022 | 微软生态 |
| Aurora | MySQL/PG兼容 | AWS云原生 |

### 3.2 Aurora架构

```
Aurora集群架构

┌─────────────────────────────────────────────────────────────┐
│                        Aurora Cluster                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Cluster Volume                      │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │   │
│  │  │ Copy 1  │ │ Copy 2  │ │ Copy 3  │ │ Copy 4  │    │   │
│  │  │  AZ-A   │ │  AZ-B   │ │  AZ-C   │ │  AZ-D   │    │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│  │ Primary  │    │ Reader 1 │    │ Reader 2 │             │
│  │ Writer   │    │ AZ-B     │    │ AZ-C     │             │
│  │ AZ-A     │    │          │    │          │             │
│  └──────────┘    └──────────┘    └──────────┘             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

特点：
- 存储自动扩展（最大128TB）
- 6副本跨3AZ存储
- 写入延迟低（典型10ms）
- 只读副本延迟低（毫秒级）
- 自动故障转移（通常<30秒）
```

### 3.3 高可用配置

**多可用区部署**：
```bash
aws rds create-db-instance \
    --db-instance-identifier mydb \
    --db-instance-class db.t3.medium \
    --engine mysql \
    --master-username admin \
    --master-user-password password \
    --allocated-storage 100 \
    --multi-az \
    --backup-retention-period 7
```

**只读副本**：
```bash
aws rds create-db-instance-read-replica \
    --db-instance-identifier mydb-replica \
    --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:mydb
```

### 3.4 性能优化

```
RDS性能优化清单

参数优化
├── innodb_buffer_pool_size = 总内存的70-80%
├── max_connections = 适当值
└── query_cache_size = 根据工作负载调整

索引优化
├── 分析慢查询日志
├── 创建合适的索引
└── 避免过度索引

连接优化
├── 使用连接池
├── 避免短连接
└── 合理设置超时

存储优化
├── 选择正确的存储类型
├── 预置IOPS for 高负载
└── 使用读写分离
```

---

## 4. Lambda无服务器

### 4.1 Lambda基础

```python
import json

def lambda_handler(event, context):
    """
    Lambda函数入口
    
    event: 触发事件数据
    context: 运行时信息
    """
    print(f"Request ID: {context.aws_request_id}")
    print(f"Function: {context.function_name}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda!'
        })
    }
```

### 4.2 触发器配置

```
Lambda触发器类型

API Gateway
├── REST API
└── HTTP API

存储服务
├── S3事件
├── DynamoDB Streams
└── Kinesis Streams

消息服务
├── SNS
├── SQS
└── EventBridge

定时触发
└── EventBridge Scheduler

其他服务
├── CloudWatch Events
├── CodeCommit
└── Alexa Skills Kit
```

### 4.3 Lambda最佳实践

```python
import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    # 1. 连接复用 - 在handler外初始化客户端
    
    # 2. 环境变量存储配置
    config_value = os.environ.get('CONFIG_VALUE')
    
    # 3. 适当的日志级别
    print(f"Processing event: {json.dumps(event)}")
    
    # 4. 错误处理
    try:
        response = table.get_item(
            Key={'id': event['id']}
        )
        return response['Item']
    except Exception as e:
        print(f"Error: {str(e)}")
        raise e

# 5. 冷启动优化 - 使用更小的部署包
# 6. 使用Lambda Layers共享代码
# 7. 合理设置内存和超时
```

### 4.4 Lambda部署

**SAM模板**：
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Runtime: python3.9
    Timeout: 30
    MemorySize: 256

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: src/
      Handler: app.lambda_handler
      Environment:
        Variables:
          TABLE_NAME: !Ref MyTable
      Events:
        ApiEvent:
          Type: HttpApi
          Properties:
            Path: /items
            Method: GET
      Policies:
        - DynamoDBReadPolicy:
            TableName: !Ref MyTable

  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
```

---

## 5. CloudFormation

### 5.1 模板结构

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "CloudFormation template example"

Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - staging
      - prod

Mappings:
  RegionMap:
    us-east-1:
      AMI: ami-0c55b159cbfafe1f0
    us-west-2:
      AMI: ami-0c55b159cbfafe1f1

Conditions:
  IsProd: !Equals [!Ref Environment, prod]

Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !FindInMap [RegionMap, !Ref "AWS::Region", AMI]
      InstanceType: !If [IsProd, t3.medium, t3.micro]

Outputs:
  InstanceId:
    Description: "EC2 Instance ID"
    Value: !Ref MyInstance
```

### 5.2 常用资源类型

```
CloudFormation资源类型

计算
├── AWS::EC2::Instance
├── AWS::Lambda::Function
└── AWS::ECS::Service

存储
├── AWS::S3::Bucket
├── AWS::EFS::FileSystem
└── AWS::EBS::Volume

数据库
├── AWS::RDS::DBInstance
├── AWS::DynamoDB::Table
└── AWS::ElastiCache::CacheCluster

网络
├── AWS::EC2::VPC
├── AWS::EC2::Subnet
├── AWS::EC2::SecurityGroup
├── AWS::ElasticLoadBalancingV2::LoadBalancer
└── AWS::Route53::RecordSet

安全
├── AWS::IAM::Role
├── AWS::IAM::Policy
└── AWS::KMS::Key
```

### 5.3 堆栈操作

```bash
# 创建堆栈
aws cloudformation create-stack \
    --stack-name my-stack \
    --template-body file://template.yaml \
    --parameters ParameterKey=Environment,ParameterValue=prod

# 更新堆栈
aws cloudformation update-stack \
    --stack-name my-stack \
    --template-body file://template.yaml

# 删除堆栈
aws cloudformation delete-stack \
    --stack-name my-stack

# 查看堆栈状态
aws cloudformation describe-stacks \
    --stack-name my-stack

# 查看堆栈事件
aws cloudformation describe-stack-events \
    --stack-name my-stack
```

---

## 6. CloudWatch监控

### 6.1 核心功能

```
CloudWatch服务组件

CloudWatch Metrics
├── 标准指标（AWS服务自动发布）
├── 自定义指标
└── 跨账户、跨区域聚合

CloudWatch Alarms
├── 阈值告警
├── 复合告警
└── 异常检测

CloudWatch Logs
├── 日志收集
├── 日志查询（Logs Insights）
└── 日志订阅

CloudWatch Events
├── 事件规则
├── 事件目标
└── 定时任务

CloudWatch Dashboards
├── 可视化仪表板
└── 跨服务监控
```

### 6.2 自定义指标

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def put_custom_metric():
    cloudwatch.put_metric_data(
        Namespace='MyApplication',
        MetricData=[
            {
                'MetricName': 'RequestCount',
                'Dimensions': [
                    {
                        'Name': 'Service',
                        'Value': 'API'
                    }
                ],
                'Value': 1,
                'Unit': 'Count'
            }
        ]
    )
```

### 6.3 告警配置

```yaml
Resources:
  CPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: HighCPUAlarm
      AlarmDescription: Alert when CPU exceeds 80%
      Namespace: AWS/EC2
      MetricName: CPUUtilization
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref SNSTopic
      Dimensions:
        - Name: InstanceId
          Value: !Ref MyInstance
```

### 6.4 Logs Insights查询

```
# 查询Lambda错误
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20

# 统计HTTP状态码
fields @timestamp, @message
| parse @message "status: *" as status
| stats count() by status
| sort status

# 查询慢请求
fields @timestamp, duration
| filter duration > 1000
| sort @timestamp desc
```

---

## 7. 实操项目

### 项目：部署高可用Web应用

**架构**：
```
用户 → Route53 → ALB → ASG (EC2) → RDS Aurora
                    ↓
                  S3 (静态资源)
                    ↓
                CloudFront
```

**部署步骤**：
1. 创建VPC网络
2. 部署RDS Aurora集群
3. 创建ALB和目标组
4. 配置Auto Scaling
5. 设置CloudWatch告警
6. 配置Route53 DNS

---

## 8. 知识检测

### 选择题

1. 哪种EC2购买选项适合稳定运行的Web服务器？
   - A. On-Demand
   - B. Reserved
   - C. Spot
   - D. Dedicated

2. S3 Glacier Deep Archive的最小存储期是多少天？
   - A. 30天
   - B. 90天
   - C. 180天
   - D. 365天

3. Aurora存储最多可以扩展到多少？
   - A. 16TB
   - B. 64TB
   - C. 128TB
   - D. 256TB

---

## 9. 扩展阅读

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Best Practices](https://aws.amazon.com/architecture/reference-architecture-diagrams/)
- [AWS Documentation](https://docs.aws.amazon.com/)

---

## 学习进度

- [ ] 掌握EC2高级特性
- [ ] 掌握S3高级功能
- [ ] 理解RDS与Aurora
- [ ] 掌握Lambda无服务器
- [ ] 掌握CloudFormation
- [ ] 熟练使用CloudWatch
- [ ] 完成实操项目
