# GCP费用优化实战指南

## 目录
- [1. GCP计费模型](#1-gcp计费模型)
- [2. 成本监控与告警](#2-成本监控与告警)
- [3. Compute Engine费用优化](#3-compute-engine费用优化)
- [4. Cloud Storage费用优化](#4-cloud-storage费用优化)
- [5. 其他服务费用优化](#5-其他服务费用优化)
- [6. 承诺使用折扣(CUD)](#6-承诺使用折扣cud)
- [7. 成本自动化与治理](#7-成本自动化与治理)
- [8. 实战省钱案例](#8-实战省钱案例)

---

## 1. GCP计费模型

### 1.1 计费基础架构

GCP的计费不是一笔糊涂账，它有清晰的架构。

#### 1.1.1 资源层级与计费关系

```
Organization (组织)
  └── Billing Account (计费账户) - 付款单位
        ├── Project 1 (项目) - 资源容器
        │     ├── VM实例
        │     ├── 存储桶
        │     └── 网络资源
        ├── Project 2 (项目)
        └── Project 3 (项目)
```

**为什么这样设计？**
- **隔离性**：每个项目的费用独立计算
- **灵活性**：一个计费账户可以关联多个项目
- **可追溯性**：精确到项目级别的费用追踪

#### 1.1.2 计费账户类型

| 类型 | 适用场景 | 特点 |
|------|---------|------|
| **个人账户** | 个人开发、小项目 | 信用卡直接支付，简单 |
| **企业账户** | 企业组织 | 发票、PO、集中管理 |
| **免费试用** | 新用户体验 | $300 90天信用额 |

---

### 1.2 核心计费概念

#### 1.2.1 按使用量付费 (Pay-as-you-go)

**核心概念：**
```
费用 = 资源使用量 × 单价
```

**为什么这是革命性的？**
- 传统IT：预付硬件，即使不用也花钱
- GCP：只用多少付多少，浪费减少

**计费粒度示例：**
```powershell
# Compute Engine：每秒计费
# 实际公式：费用 = 实例小时数 × 小时单价
# 例如：运行1小时30分钟 = 1.5小时费用

# Cloud Storage：按字节/月计费
# 例如：100GB存储一个月 = 100 × 单价

# 网络出口：按字节计费
# 例如：传输10GB数据 = 10 × 出口单价
```

#### 1.2.2 区域定价差异

**为什么不同区域价格不同？**
- 基础设施成本差异
- 电力、土地、人力成本
- 供需关系

**示例对比（2024年价格）：**

| 区域 | n1-standard-1 (小时) | 存储 (GB/月) |
|------|---------------------|-------------|
| us-central1 (爱荷华) | $0.0475 | $0.026 |
| europe-west1 (比利时) | $0.0537 | $0.026 |
| asia-southeast1 (新加坡) | $0.0574 | $0.026 |

**省钱提示：** 选择距离最近但更便宜的区域

#### 1.2.3 免费层级 (Free Tier)

**永久免费资源：**
| 服务 | 免费额度 |
|------|---------|
| Compute Engine | 1个e2-micro实例/月 |
| Cloud Storage | 5GB标准存储 |
| Cloud Functions | 200万次调用/月 |
| BigQuery | 1TB查询数据/月 |

**注意：** 免费层级仅限特定区域

---

### 1.3 计费时间与周期

#### 1.3.1 计费时间窗口

```
计费周期：每月1日 - 每月最后一日
账单生成：次月1-3日
付款截止：取决于付款方式
```

#### 1.3.2 实时计费更新

**GCP的计费不是月底才出来：**
```powershell
# 计费数据延迟
实时数据：通常几分钟内
详细报告：几小时内
月度账单：次月初
```

---

## 2. 成本监控与告警

### 2.1 Cloud Billing 控制台

#### 2.1.1 费用概览

**访问路径：**
```
GCP Console → Billing → Cost Explorer
```

**核心功能：**
- 实时费用查看
- 按项目/服务/标签分类
- 费用趋势图表
- 预算对比分析

#### 2.1.2 成本探索器 (Cost Explorer)

**这是最重要的工具，没有之一。**

**基本使用：**
```powershell
# 打开成本探索器
# 1. 进入 Billing → Cost Explorer
# 2. 选择时间范围
# 3. 选择分组维度（Project、Service、SKU等）
# 4. 查看图表和数据
```

**为什么分组维度重要？**

| 分组方式 | 用途 | 例子 |
|---------|------|------|
| **Project** | 看哪个项目花钱多 | "Project X花了60%" |
| **Service** | 看哪个服务花钱多 | "Compute Engine花了80%" |
| **SKU** | 看具体资源类型 | "n1-standard-4是大头" |
| **Label** | 按业务维度分析 | "生产环境占70%" |

**实用技巧：**
```powershell
# 查看月度对比
Time range: Last 3 months
Group by: Month

# 查看服务分布
Time range: Last month
Group by: Service
```

---

### 2.2 预算与告警

#### 2.2.1 为什么需要预算告警？

**场景：**
- 开发人员忘了关测试环境VM
- 月底账单出来：$5000
- 老板：怎么花这么多？

**预算告警的作用：**
```powershell
# 预警 → 干预 → 止损
# 在花超之前就知道！
```

#### 2.2.2 创建预算

**步骤：**
```powershell
# 1. 进入 Billing → Budgets & alerts
# 2. 点击 "CREATE BUDGET"

# 预算配置示例
预算名称：生产环境月度预算
项目：production-project
金额：$10,000/月

# 告警阈值
50% ($5,000) → 提醒团队关注
80% ($8,000) → 升级到技术负责人
100% ($10,000) → 紧急告警，财务介入
```

**完整配置命令（gcloud）：**
```powershell
# 创建预算
gcloud billing budgets create `
  --billing-account=YOUR_BILLING_ACCOUNT_ID `
  --display-name="Production Monthly Budget" `
  --budget-amount=10000 `
  --currency-code=USD `
  --threshold-rule=threshold=0.5,basis=CURRENT_SPEND `
  --threshold-rule=threshold=0.8,basis=CURRENT_SPEND `
  --threshold-rule=threshold=1.0,basis=CURRENT_SPEND `
  --monitoring-notification-channels=projects/YOUR_PROJECT/notificationChannels/YOUR_CHANNEL
```

**告警阈值最佳实践：**
```powershell
# 开发环境
50% → 检查是否有不必要的资源
75% → 团队讨论，暂停非紧急任务
100% → 锁定非生产资源

# 生产环境
70% → 预警，检查是否有异常
90% → 关注，开始节流
100% → 紧急响应，评估是否需要追加
```

---

### 2.3 成本报告与分析

#### 2.3.1 导出账单数据到BigQuery

**为什么要这样做？**
- GCP Console的查询有限制
- 可以用SQL做复杂分析
- 可以结合其他业务数据
- 可以生成自定义报告

**配置步骤：**
```powershell
# 1. 进入 Billing → Billing export
# 2. 启用 "Detailed usage cost" 导出
# 3. 选择BigQuery数据集
# 4. 配置后，数据会每日自动导出
```

**导出后的表结构：**
```
gcp_billing_export
  ├── gcp_billing_export_v1_XXXXXX (详细数据表)
  └── gcp_billing_export_pricing (价格表)
```

#### 2.3.2 实用SQL查询

**查询1：月度费用按项目汇总**
```sql
SELECT
  project.name AS project,
  SUM(cost) AS total_cost,
  SUM(credits.amount) AS total_credits,
  SUM(cost + IFNULL(credits.amount, 0)) AS net_cost
FROM
  `your-project.gcp_billing_export.gcp_billing_export_v1_XXXXXX`
WHERE
  DATE(usage_start_time) BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY
  project
ORDER BY
  total_cost DESC
```

**查询2：费用增长最快的服务**
```sql
WITH monthly_costs AS (
  SELECT
    service.description AS service,
    DATE_TRUNC(DATE(usage_start_time), MONTH) AS month,
    SUM(cost) AS cost
  FROM
    `your-project.gcp_billing_export.gcp_billing_export_v1_XXXXXX`
  WHERE
    DATE(usage_start_time) >= '2023-11-01'
  GROUP BY
    service, month
)
SELECT
  service,
  month,
  cost,
  LAG(cost) OVER (PARTITION BY service ORDER BY month) AS prev_month_cost,
  (cost - LAG(cost) OVER (PARTITION BY service ORDER BY month)) / LAG(cost) OVER (PARTITION BY service ORDER BY month) * 100 AS growth_percent
FROM
  monthly_costs
ORDER BY
  growth_percent DESC
```

**查询3：每日费用趋势**
```sql
SELECT
  DATE(usage_start_time) AS date,
  service.description AS service,
  SUM(cost) AS cost
FROM
  `your-project.gcp_billing_export.gcp_billing_export_v1_XXXXXX`
WHERE
  DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY
  date, service
ORDER BY
  date DESC, cost DESC
```

---

### 2.4 推荐指标与监控

#### 2.4.1 关键成本指标

| 指标 | 计算方式 | 目标 |
|------|---------|------|
| **单位业务成本** | 总成本 / 业务量 | 持续下降 |
| **资源利用率** | 实际使用 / 配置容量 | > 60-70% |
| **浪费率** | 未使用资源成本 / 总成本 | < 20% |
| **预算达成率** | 实际支出 / 预算 | 90-100% |

#### 2.4.2 异常检测

**什么是异常？**
```powershell
# 正常模式
周一到周五：$100/天
周末：$20/天

# 异常
周六突然：$300/天 → 告警！
```

---

## 3. Compute Engine费用优化

### 3.1 虚拟机费用构成

#### 3.1.1 费用公式

```
VM总费用 = vCPU费用 + 内存费用 + 磁盘费用 + 网络费用 + 许可费用
```

**拆分示例：**
```powershell
# n1-standard-4 (4 vCPU, 15GB内存) 运行1个月

vCPU: 4 × $28.48/月 = $113.92
内存: 15 × $3.79/月 = $56.85
磁盘: 100GB SSD × $0.17/月 = $17.00
网络: 50GB出口 × $0.12/GB = $6.00
许可: 如有Windows OS许可额外费用
──────
总计: 约 $193.77/月
```

---

### 3.2 选择合适的机器类型

#### 3.2.1 机器类型对比

| 类型 | 用途 | 成本对比 | 特点 |
|------|------|---------|------|
| **E2** | 通用、开发测试 | 便宜 | 突发性能，成本最优 |
| **N1** | 通用工作负载 | 标准 | 成熟稳定，性价比高 |
| **N2/N2D** | 通用、高性能 | 稍贵 | 新一代处理器，性能更好 |
| **T2A** | ARM架构 | 便宜 | 基于Ampere，特定负载 |
| **C2/C2D** | 计算密集 | 较贵 | 高性能计算 |
| **M2/M3** | 内存密集 | 贵 | 大内存工作负载 |

#### 3.2.2 如何选择？决策树

```
开始
  │
  ├─ 是开发/测试环境？
  │   ├─ 是 → E2 系列（省钱！）
  │   └─ 否 → 继续
  │
  ├─ CPU使用率通常 < 50%？
  │   ├─ 是 → E2 或 N1（可能可降配）
  │   └─ 否 → 继续
  │
  ├─ 工作负载类型？
  │   ├─ 通用 → N2/N2D
  │   ├─ 计算密集 → C2/C2D
  │   ├─ 内存密集 → M2/M3
  │   └─ ARM兼容 → T2A
  │
  └─ 确认配置是否过度
```

#### 3.2.3 真实案例：从N1到E2的节省

**场景：**
- 开发环境VM：10台 n1-standard-2
- 使用时间：工作日 9:00-18:00
- 周末关机

**费用对比：**

| 配置 | 单价 | 月费用（约） |
|------|------|------------|
| n1-standard-2 | $0.0950/小时 | 10台 × ~$41/月 = $410 |
| e2-standard-2 | $0.0670/小时 | 10台 × ~$29/月 = $290 |

**节省：$120/月，约30%！**

---

### 3.3 虚拟机调度：开关机策略

#### 3.3.1 非生产环境：定时开关机

**为什么这是最有效的省钱方法？**

```powershell
# 假设VM一天运行8小时，不是24小时
24小时运行：100% 费用
8小时运行：8/24 = 33% 费用 → 节省 67%！
```

**实现方案1：使用Cloud Scheduler + Cloud Functions**

**架构图：**
```
Cloud Scheduler (定时触发器)
  ↓
Cloud Functions (执行函数)
  ↓
Compute Engine API (启动/停止VM)
```

**Cloud Function代码（Python）：**
```python
import googleapiclient.discovery

def stop_vms(event, context):
    compute = googleapiclient.discovery.build('compute', 'v1')
    project = 'your-project'
    zone = 'us-central1-a'
    
    # 获取带标签的VM
    result = compute.instances().list(
        project=project,
        zone=zone,
        filter='labels.env=dev'
    ).execute()
    
    if 'items' in result:
        for instance in result['items']:
            print(f'Stopping {instance["name"]}')
            compute.instances().stop(
                project=project,
                zone=zone,
                instance=instance['name']
            ).execute()

def start_vms(event, context):
    compute = googleapiclient.discovery.build('compute', 'v1')
    project = 'your-project'
    zone = 'us-central1-a'
    
    result = compute.instances().list(
        project=project,
        zone=zone,
        filter='labels.env=dev'
    ).execute()
    
    if 'items' in result:
        for instance in result['items']:
            print(f'Starting {instance["name"]}')
            compute.instances().start(
                project=project,
                zone=zone,
                instance=instance['name']
            ).execute()
```

**Cloud Scheduler配置：**
```powershell
# 停止VM的触发器（周一到周五 18:00 UTC）
Schedule: "0 18 * * 1-5"
Timezone: UTC（或根据需要调整）
Target: Pub/Sub → Cloud Function

# 启动VM的触发器（周一到周五 09:00 UTC）
Schedule: "0 9 * * 1-5"
Timezone: UTC
Target: Pub/Sub → Cloud Function
```

**实现方案2：使用Instance Schedules（更简单）**

```powershell
# 这是GCP提供的托管解决方案！

# 1. 进入 Compute Engine → VM instances
# 2. 点击 "Instance schedules"
# 3. 创建新的Schedule：
#    - 名称：dev-schedule
#    - 启动时间：周一-周五 09:00
#    - 停止时间：周一-周五 18:00
#    - 时区：根据需要选择

# 4. 将Schedule附加到VM上（通过标签）
# 给VM添加标签：schedule=dev
```

#### 3.3.2 生产环境：自动伸缩

**生产环境不能随便关机，但可以自动伸缩！**

**Managed Instance Groups (MIG) + Autoscaling：**
```powershell
# 根据负载自动增减VM数量
- CPU使用率高 → 增加VM
- CPU使用率低 → 减少VM
```

**配置示例：**
```powershell
# 创建自动伸缩的MIG
gcloud compute instance-groups managed create autoscaling-group `
  --base-instance-name=web-server `
  --template=web-server-template `
  --size=2 `
  --zone=us-central1-a

# 设置自动伸缩策略
gcloud compute instance-groups managed set-autoscaling autoscaling-group `
  --max-num-replicas=10 `
  --min-num-replicas=2 `
  --target-cpu-utilization=0.7 `
  --zone=us-central1-a
```

**省钱原理：**
```powershell
# 传统方式：始终运行10台VM（应对峰值）
# 自动伸缩：
- 夜间：2台VM
- 白天：5台VM
- 峰值：10台VM

# 节省：平均约60%！
```

---

### 3.4 权利调整 (Right Sizing)

#### 3.4.1 什么是权利调整？

**概念：**
```powershell
# 问题：过度配置
- 配置了4 vCPU，实际只用1 vCPU
- 配置了16GB内存，实际只用4GB
- 花了冤枉钱！

# 解决方案：权利调整
- 降低配置，匹配实际需求
- 节省30-70%费用！
```

#### 3.4.2 推荐工具：Cloud Monitoring + Recommendations

**GCP有内置推荐！**

```powershell
# 查看推荐
1. 进入 Compute Engine → VM instances
2. 看 "Recommendations" 列
3. GCP会告诉你："这个VM可以降配"
```

**推荐示例：**
```
Current: n1-standard-4 (4 vCPU, 15GB)
Recommendation: e2-medium (2 vCPU, 4GB)
Estimated savings: $80/月
```

#### 3.4.3 如何分析使用情况

**使用Cloud Monitoring查看指标：**

```powershell
# 关键指标
- CPU使用率
- 内存使用率
- 磁盘I/O
- 网络流量

# 查看过去30天的数据
# 找出峰值和平均值
```

**权利调整决策：**
```
规则1：CPU平均使用率 < 30% → 可以降配
规则2：CPU峰值 < 70% → 可以降配
规则3：内存平均使用率 < 40% → 可以降配
规则4：有足够的监控数据（至少7天）
```

---

### 3.5 抢占式VM (Spot VM)

#### 3.5.1 什么是Spot VM？

**核心概念：**
```powershell
# 普通VM：你一直用，直到你停止
# Spot VM：GCP随时可能收回（提前60秒通知）
# 价格：比普通VM便宜 60-91%！
```

**价格对比示例：**
| VM类型 | 普通价格 | Spot价格 | 折扣 |
|--------|---------|---------|------|
| e2-medium | $0.0335/小时 | $0.0087/小时 | 74% |
| n1-standard-4 | $0.1900/小时 | $0.0399/小时 | 79% |
| n2-standard-8 | $0.3888/小时 | $0.0816/小时 | 79% |

#### 3.5.2 适用场景

**适合用Spot VM：**
- 批处理作业
- 大数据分析（Hadoop、Spark）
- CI/CD流水线
- 渲染农场
- 测试环境
- 无状态服务（配合MIG）

**不适合用Spot VM：**
- 生产数据库
- 不能中断的服务
- 单实例应用

#### 3.5.3 使用示例：带MIG的Spot VM

```powershell
# 创建实例模板，使用Spot VM
gcloud compute instance-templates create spot-template `
  --machine-type=e2-medium `
  --preemptible `
  --image-family=debian-11 `
  --image-project=debian-cloud

# 创建托管实例组
gcloud compute instance-groups managed create spot-mig `
  --base-instance-name=spot-worker `
  --template=spot-template `
  --size=5 `
  --zone=us-central1-a

# 设置自动修复（当Spot VM被收回时自动替换）
gcloud compute instance-groups managed set-autohealing spot-mig `
  --health-check=http-basic-check `
  --initial-delay=300 `
  --zone=us-central1-a
```

---

## 4. Cloud Storage费用优化

### 4.1 存储费用构成

#### 4.1.1 费用公式

```
总费用 = 存储费用 + 操作费用 + 网络费用 + 检索费用（对于冷存储）
```

**详细说明：**
| 费用项 | 说明 |
|--------|------|
| **存储费用** | 按GB/月计算 |
| **操作费用** | Class A（写入）、Class B（读取） |
| **网络费用** | 出口流量收费，入口免费 |
| **检索费用** | Nearline/Coldline/Archive读取额外收费 |

---

### 4.2 存储类别的选择

#### 4.2.1 四种存储类别

| 类别 | 用途 | 价格 (GB/月) | 最小存储时间 | 数据检索费用 |
|------|------|--------------|------------|-----------|
| **Standard** | 频繁访问 | $0.026 | 无 | 无 |
| **Nearline** | 每月访问 < 1次 | $0.010 | 30天 | 有 |
| **Coldline** | 每季度访问 < 1次 | $0.007 | 90天 | 有 |
| **Archive** | 每年访问 < 1次 | $0.0025 | 365天 | 有 |

**为什么有最小存储时间？**
```powershell
# 如果你用Nearline存储数据，但20天后就删除
# 你仍然要付30天的费用！
# 这是一个常见陷阱
```

#### 4.2.2 选择决策树

```
开始
  │
  ├─ 数据会频繁访问吗？（> 1次/月）
  │   ├─ 是 → Standard
  │   └─ 否 → 继续
  │
  ├─ 会存储多久？
  │   ├─ < 30天 → 继续（但要注意最小存储费用）
  │   ├─ 30-90天 → Nearline
  │   ├─ 90-365天 → Coldline
  │   └─ > 365天 → Archive
  │
  ├─ 访问模式？
  │   ├─ 每月访问1次左右 → Nearline
  │   ├─ 每季度访问1次左右 → Coldline
  │   └─ 几乎不访问 → Archive
  │
  └─ 检索时间要求？
      ├─ 立即（毫秒） → Standard/Nearline/Coldline
      └─ 可以等待（小时） → Archive
```

#### 4.2.3 真实案例：日志存储优化

**场景：**
- 应用每天产生10GB日志
- 保留1年
- 访问模式：
  - 最近7天：频繁查询 → Standard
  - 7-30天：偶尔查询 → Nearline
  - 30天-1年：几乎不查 → Coldline/Archive

**费用对比：**

| 方案 | 月存储费用 | 年费用 |
|------|----------|--------|
| 全存Standard | 3650GB × $0.026 = $94.90 | $1,139 |
| 分层存储（优化后） | 约 $16.20 | $194 |

**节省：约 $945/年，83%！**

---

### 4.3 生命周期管理 (Object Lifecycle Management)

#### 4.3.1 什么是生命周期管理？

**核心概念：**
```powershell
# 自动把对象从一个存储类别移到另一个
# 或者自动删除
# 不需要人工操作！
```

**典型生命周期：**
```
创建 → Standard (7天) → Nearline (23天) → Coldline (9个月) → 删除 (1年)
```

#### 4.3.2 配置生命周期规则

**方法1：通过控制台**
```powershell
1. 进入 Cloud Storage → Browser
2. 选择存储桶
3. 点击 "Lifecycle"
4. 点击 "Add rule"
5. 配置条件和动作
```

**方法2：通过JSON配置文件**

创建 `lifecycle.json`:
```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 7}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 30}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
        "condition": {"age": 365}
      },
      {
        "action": {"type": "Delete"},
        "condition": {"age": 730}
      }
    ]
  }
}
```

**应用配置：**
```powershell
gcloud storage buckets update gs://your-bucket `
  --lifecycle-file=lifecycle.json
```

#### 4.3.3 其他有用的规则

**规则1：删除旧版本**
```json
{
  "action": {"type": "Delete"},
  "condition": {
    "numNewerVersions": 5,
    "isLive": false
  }
}
```

**规则2：按前缀处理**
```json
{
  "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
  "condition": {
    "age": 30,
    "matchesPrefix": ["logs/"]
  }
}
```

**规则3：按自定义时间处理**
```json
{
  "action": {"type": "Delete"},
  "condition": {
    "customTimeBefore": "2024-01-01"
  }
}
```

---

### 4.4 减少操作费用

#### 4.4.1 操作费用明细

**Class A操作（写入类）：**
- 存储对象
- 复制对象
- 组合对象
- 设置元数据
- 等

**Class B操作（读取类）：**
- 列出对象
- 获取元数据
- 等

**费用（Standard存储）：**
| 操作 | 价格 |
|------|------|
| Class A | $0.005 / 10,000次 |
| Class B | $0.0004 / 10,000次 |

**注意：** Nearline/Coldline/Archive的操作费用更高！

#### 4.4.2 优化技巧

**技巧1：批量操作**
```powershell
# 不好：逐个上传10,000个小文件
# 好：组合成大文件再上传

# 使用gsutil的组合功能
gsutil compose gs://bucket/part-* gs://bucket/combined
```

**技巧2：减少list操作**
```powershell
# 不好：每分钟list一次桶
# 好：使用Pub/Sub通知新对象

# 配置桶通知
gsutil notification create -t new-object-topic -f json gs://your-bucket
```

**技巧3：缓存常用数据**
```powershell
# 如果频繁读取某些对象
# 考虑用CDN缓存
# 或者用Memorystore缓存
```

---

### 4.5 重复数据删除

#### 4.5.1 问题：重复存储

**场景：**
- 用户上传100个几乎相同的备份文件
- 每个1GB
- 存储了100GB，但99%是重复的

#### 4.5.2 解决方案

**方案1：客户端去重**
```powershell
# 上传前计算hash
# 如果已存在，只存引用
# 不在GCP范围内，应用层处理
```

**方案2：使用版本控制 + 只存储差异**
```powershell
# 但这不是真正的去重
# 版本控制会保留所有版本
# 反而增加存储
```

---

## 5. 其他服务费用优化

### 5.1 BigQuery费用优化

#### 5.1.1 BigQuery费用模型

**两种计费模式：**
| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **按需计费** | 按查询的数据量收费 | 低负载、不可预测 |
| **预留容量** | 按槽位(Slot)预留 | 高负载、稳定 |

**按需计费价格：**
- 查询：$5 / TB 扫描数据
- 存储：$23 / TB / 月（活跃），$10 / TB / 月（长期）

#### 5.1.2 查询优化技巧

**技巧1：只查询需要的列**
```sql
-- 不好：扫描所有列
SELECT * FROM `project.dataset.table`

-- 好：只扫描需要的列
SELECT user_id, timestamp, event_name
FROM `project.dataset.table`
```

**技巧2：使用分区表**
```sql
-- 创建分区表
CREATE TABLE `project.dataset.table`
PARTITION BY DATE(timestamp)
AS
SELECT * FROM source_table

-- 查询时指定分区（减少扫描）
SELECT *
FROM `project.dataset.table`
WHERE DATE(timestamp) BETWEEN '2024-01-01' AND '2024-01-07'
```

**技巧3：使用聚类表**
```sql
-- 创建聚类表
CREATE TABLE `project.dataset.table`
PARTITION BY DATE(timestamp)
CLUSTER BY user_id, event_type
AS
SELECT * FROM source_table

-- 聚类字段过滤时更快、更省
SELECT *
FROM `project.dataset.table`
WHERE user_id = '12345'
  AND event_type = 'purchase'
```

**技巧4：避免重复查询**
```sql
-- 使用物化视图
CREATE MATERIALIZED VIEW `project.dataset.view`
AS
SELECT user_id, COUNT(*) as event_count
FROM `project.dataset.table`
GROUP BY user_id
```

#### 5.1.3 存储优化

**长期存储（Long-term storage）：**
```powershell
# 数据超过90天未修改
# 自动降价！
- 活跃存储：$23/TB/月
- 长期存储：$10/TB/月 → 节省 57%！
```

**分区过期：**
```sql
-- 自动删除旧分区
CREATE TABLE `project.dataset.table`
PARTITION BY DATE(timestamp)
OPTIONS (
  partition_expiration_days = 365
)
AS
SELECT * FROM source_table
```

---

### 5.2 Cloud Functions费用优化

#### 5.2.1 费用模型

| 资源 | 免费额度 | 超出后价格 |
|------|---------|-----------|
| 调用次数 | 200万次/月 | $0.40 / 100万次 |
| 计算时间 | 40万GB-秒/月 | $0.0000025 / GB-秒 |

**GB-秒计算：**
```
GB-秒 = 内存(GB) × 执行时间(秒)
```

#### 5.2.2 优化技巧

**技巧1：优化内存配置**
```powershell
# 假设函数需要256MB，实际配置1024MB
# 浪费了75%费用！

# 找到最小够用的内存配置
# 测试不同配置
```

**技巧2：减少执行时间**
```python
# 优化代码
# 避免不必要的操作
# 使用连接池
# 等
```

**技巧3：避免重复调用**
```powershell
# 使用缓存（Memorystore）
# 批量处理
# 等
```

---

### 5.3 网络费用优化

#### 5.3.1 网络费用说明

**主要费用：**
```
- 互联网出口：贵
- 区域间出口：较贵
- 同一区域内：免费
- 互联网入口：免费
```

**价格示例（2024年）：**
| 流量类型 | 价格 |
|---------|------|
| 同一区域内 | 免费 |
| 区域间 | $0.01-0.02/GB |
| 互联网出口（北美） | $0.12/GB起 |
| 互联网出口（亚洲） | $0.15-0.20/GB起 |

#### 5.3.2 优化策略

**策略1：区域本地化**
```powershell
# 不好
VM: us-central1
Database: europe-west1
→ 跨区域流量，花钱！

# 好
VM: us-central1
Database: us-central1
→ 同区域流量，免费！
```

**策略2：使用CDN**
```powershell
# 对于静态内容
# 使用Cloud CDN
# 减少源站流量
# 用户体验更好
```

**策略3：数据压缩**
```powershell
# 发送前压缩数据
# 减少传输量
# 例如：gzip
```

**策略4：避免不必要的出口**
```powershell
# 不好：导出数据到本地分析
# 好：在GCP内分析（BigQuery、Dataflow等）
```

---

## 6. 承诺使用折扣(CUD)

### 6.1 什么是CUD？

#### 6.1.1 核心概念

```powershell
# 普通：按需付费，随时使用
# CUD：承诺使用1或3年，获得折扣
# 折扣：Compute Engine高达57%
```

#### 6.1.2 适用场景

**适合用CUD：**
- 稳定的工作负载
- 长期运行的VM
- 可预测的资源需求

**不适合用CUD：**
- 短期项目
- 波动很大的工作负载
- 不确定的需求

---

### 6.2 CUD类型

#### 6.2.1 资源型CUD (Resource-based CUD)

**针对特定资源：**
```powershell
- 特定机器类型
- 特定区域
- 1年或3年承诺

# 折扣
1年：30% 折扣
3年：57% 折扣
```

**示例：**
```powershell
# n1-standard-4 在 us-central1
按需价格：$0.19/小时
3年CUD价格：$0.0817/小时 → 节省 57%！
```

#### 6.2.2 灵活CUD (Flexible CUD)

**更灵活：**
```powershell
- 不需要指定机器类型
- 在同一区域内通用
- 适合混合工作负载

# 折扣
1年：16% 折扣
3年：37% 折扣
```

---

### 6.3 如何购买CUD

#### 6.3.1 分析使用量

**第一步：了解你的使用情况**
```powershell
# 查看Cloud Billing报告
- 过去30天的VM使用
- 哪些实例一直运行
- 哪些是稳定的工作负载
```

#### 6.3.2 购买步骤

**通过控制台：**
```powershell
1. 进入 Billing → Commitments
2. 点击 "PURCHASE COMMITMENT"
3. 选择类型：Resource-based 或 Flexible
4. 选择区域
5. 选择期限：1年或3年
6. 选择数量
7. 确认购买
```

**通过gcloud：**
```powershell
# 购买资源型CUD
gcloud compute commitments create my-commitment `
  --plan=36-month `
  --resources=vcpu=4,memory=15 `
  --machine-type=n1-standard-4 `
  --region=us-central1

# 购买灵活CUD
gcloud compute commitments create my-flex-cud `
  --plan=36-month `
  --flexible-resource=vCPU:4 `
  --region=us-central1
```

---

## 7. 成本自动化与治理

### 7.1 资源标签策略

#### 7.1.1 为什么需要标签？

**场景：**
```powershell
# 问题：花了$10,000，不知道是谁花的
# 项目：项目X vs 项目Y？
# 环境：生产 vs 开发？
# 团队：团队A vs 团队B？
# 成本中心：CC101 vs CC102？

# 解决方案：标签！
```

#### 7.1.2 推荐标签方案

| 标签键 | 用途 | 示例值 |
|--------|------|--------|
| **env** | 环境 | dev, staging, prod |
| **team** | 团队 | team-a, team-b |
| **project** | 业务项目 | project-x, e-commerce |
| **cost-center** | 成本中心 | CC101, CC102 |
| **service** | 服务名 | api, web, worker |
| **schedule** | 调度标签 | dev-schedule, 24x7 |

#### 7.1.3 强制标签策略

**使用组织策略：**
```powershell
# 限制创建资源时必须有某些标签
# 不打标签就不能创建！
```

---

### 7.2 资源清理策略

#### 7.2.1 识别未使用资源

**检查清单：**
- [ ] 停止超过7天的VM
- [ ] 未附加的磁盘
- [ ] 未使用的静态IP
- [ ] 空的存储桶
- [ ] 旧的快照

#### 7.2.2 自动化清理脚本

**示例：清理旧VM（Python + Cloud Function）**
```python
from google.cloud import compute_v1
from datetime import datetime, timedelta

def cleanup_unused_vms(event, context):
    project = 'your-project'
    zone = 'us-central1-a'
    max_age_days = 30
    
    client = compute_v1.InstancesClient()
    
    for instance in client.list(project=project, zone=zone):
        # 检查标签
        if instance.labels.get('env') == 'prod':
            continue  # 跳过生产环境
            
        # 检查停止时间
        if instance.status == 'TERMINATED':
            # 需要获取最后停止时间（简化示例）
            # 实际实现需要检查操作日志
            print(f'考虑删除停止的VM: {instance.name}')
```

---

### 7.3 配额管理

#### 7.3.1 为什么配额很重要？

**两个作用：**
1. **控制成本**：防止意外创建大量资源
2. **防止滥用**：限制最大使用量

#### 7.3.2 设置合理的配额

**开发环境：**
```powershell
VM CPU配额：8（而不是默认的24）
GPU配额：0（除非确实需要）
```

**生产环境：**
```powershell
根据实际需求设置
但也要有上限，防止失控
```

---

## 8. 实战省钱案例

### 8.1 案例1：开发环境优化

**现状：**
- 20台开发VM，n1-standard-2
- 24小时运行
- 月费用：约 $800

**优化措施：**
1. 切换到E2机器类型
2. 定时开关机（工作日9:00-18:00）
3. 权利调整（某些降配到e2-small）

**结果：**
- 月费用：约 $180
- 节省：$620/月 (77.5%)

---

### 8.2 案例2：存储分层

**现状：**
- 5TB日志数据，全部Standard存储
- 月存储费用：5TB × $26/TB = $130

**优化措施：**
1. 配置生命周期管理
2. 7天后 → Nearline
3. 30天后 → Coldline
4. 1年后 → Archive

**结果：**
- 月存储费用：约 $25
- 节省：$105/月 (80.8%)

---

### 8.3 案例3：使用CUD

**现状：**
- 稳定工作负载：10台 n1-standard-4
- 按需付费：10 × $0.19 × 730 = $1,387/月

**优化措施：**
- 购买3年资源型CUD

**结果：**
- CUD费用：10 × $0.0817 × 730 = $596/月
- 节省：$791/月 (57%)

---

## 总结：省钱检查清单

- [ ] 给所有资源打标签（env, team, cost-center）
- [ ] 非生产环境设置定时开关机
- [ ] 查看权利调整推荐并实施
- [ ] 为Cloud Storage配置生命周期管理
- [ ] 设置预算和告警
- [ ] 导出账单到BigQuery做详细分析
- [ ] 稳定工作负载考虑CUD
- [ ] 定期清理未使用资源
- [ ] 网络流量尽量在同一区域内
- [ ] 使用Spot VM处理可中断工作负载

**记住：成本优化不是一次性工作，是持续改进的过程！**
