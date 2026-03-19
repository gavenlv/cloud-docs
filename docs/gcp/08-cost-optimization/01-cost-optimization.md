# GCP费用优化：深度解析与实战

## 本章概述

云成本优化不是"省钱的技巧集合"，而是一套**系统化的管理方法论**。很多团队在GCP上花了冤枉钱，不是因为不懂技巧，而是因为缺乏对计费模型的深度理解、缺乏监控和治理机制、缺乏持续优化的流程。

本章不是"10个省钱小妙招"的肤浅集合。我们会从**计费原理**出发，深入到每个服务的成本构成，然后讲解**监控、分析、优化**的系统方法，最后通过**真实案例**展示如何落地。

学完本章后，你将能够：
- 准确计算任意GCP资源的成本
- 建立完善的成本监控和告警体系
- 识别并消除各种浪费
- 为稳定工作负载设计成本优化方案
- 建立成本治理的长效机制

---

## 1. GCP计费模型深度解析

理解计费模型是成本优化的基础。很多"省钱技巧"只有在理解原理后才能真正发挥作用。

### 1.1 费用的本质：资源使用量 × 单价

GCP的费用公式看似简单：

```
总费用 = Σ(资源使用量 × 单价)
```

但这里面有几个关键点需要深入理解：

```
关键点1：单价不是固定的
├── 区域差异：us-central1 比 asia-east1 便宜
├── 时间差异：某些服务有阶梯定价
├── 承诺差异：CUD可获得高达57%折扣
└── 促销差异：特定服务可能有临时优惠

关键点2：使用量的计量方式不同
├── Compute Engine：按秒计费，最小计费单元是分钟
├── Cloud Storage：按"GB-月"计费
├── BigQuery：按扫描的数据量计费（TB）
├── Cloud Functions：按"GB-秒"计费
└── 网络出口：按实际传输字节数计费

关键点3：有些费用是联动的
├── 创建VM → 自动产生Compute费用
├── VM运行 → 持续产生Compute费用
├── VM存储 → 同时产生PD费用
├── VM网络 → 可能产生网络费用
└── 结论：优化要考虑联动效应
```

### 1.2 Compute Engine计费详解

#### 1.2.1 计费公式拆解

一个VM的费用不是单一的，它由多个组件构成：

```
VM总费用 = vCPU费用 + 内存费用 + 持久磁盘费用 + 网络费用 + 许可费用（如有）
```

让我用具体的n1-standard-4来演示计算过程：

```
配置：n1-standard-4
├── 4个vCPU
└── 15GB内存

单价（us-central1，2024年）：
├── vCPU：$0.033174/小时
├── 内存：$0.004428/GB-小时

计算示例：运行1个月（730小时）

vCPU费用：
  4 × $0.033174 × 730 = $96.87

内存费用：
  15GB × $0.004428 × 730 = $48.49

持久磁盘（100GB SSD）：
  100GB × $0.17/GB-月 = $17.00

月度总计：
  $96.87 + $48.49 + $17.00 = $162.36/月

年度总计（不打折）：
  $162.36 × 12 = $1,948.32/年
```

#### 1.2.2 为什么不同区域价格不同？

这是理解区域选择的基础：

```
区域价格差异的原因：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. 电力成本                                                     │
│     - 数据中心密集的地区电力更便宜                                 │
│     - 气候寒冷的地区冷却成本更低                                  │
│     - 爱荷华（us-central1）有丰富的玉米乙醇能源，便宜            │
│                                                                  │
│  2. 土地和建筑成本                                               │
│     - 农村地区土地便宜                                           │
│     - 爱荷华地广人稀，成本低                                      │
│                                                                  │
│  3. 网络基础设施                                                 │
│     - 主要网络节点附近成本更低                                   │
│     - 新建设施成本更高                                          │
│                                                                  │
│  4. 供需关系                                                     │
│     - 热门区域竞争激烈，价格更透明                               │
│     - 新区域可能有优惠吸引用户                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 1.2.3 预付费 vs 按需 vs CUD

这是理解成本优化的核心概念：

```
三种计费模式对比：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. On-Demand（按需付费）                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  特点：随时使用，随时取消，按秒计费                        │   │
│  │  优点：灵活性最高，无最低消费                            │   │
│  │  缺点：无折扣，正常价格                                    │   │
│  │  适用：不可预测的负载、实验环境、短期项目                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  2. Spot VM（抢占式）                                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  特点：GCP闲置容量，便宜60-91%                            │   │
│  │  优点：价格极低                                           │   │
│  │  缺点：GCP可随时收回（60秒预警）                          │   │
│  │  适用：批处理、CI/CD、可中断的工作负载                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  3. Committed Use Discount（承诺使用折扣/CUD）                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  特点：承诺1年或3年使用，获得折扣                          │   │
│  │  折扣：1年约30%，3年约57%                                 │   │
│  │  优点：稳定工作负载大幅节省                                │   │
│  │  缺点：必须承诺使用，锁定资源                              │   │
│  │  适用：稳定的生产工作负载                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 1.2.4 CUD计算示例：到底能省多少？

这是最重要的成本优化手段之一，必须完全理解：

```
CUD折扣计算示例：

场景：生产环境有20台 n1-standard-4，常年运行

按需价格计算：
├── 单台机器/小时：$0.033174 × 4 + $0.004428 × 15 = $0.1327 + $0.0664 = $0.1991
├── 单台机器/月（730小时）：$0.1991 × 730 = $145.34
├── 20台机器/月：$145.34 × 20 = $2,906.80
└── 20台机器/年：$2,906.80 × 12 = $34,881.60

3年CUD价格（57%折扣）：
├── 折扣后单台/小时：$0.1991 × (1 - 0.57) = $0.0856
├── 单台机器/月：$0.0856 × 730 = $62.49
├── 20台机器/月：$62.49 × 20 = $1,249.80
└── 20台机器/年：$1,249.80 × 12 = $14,997.60

3年总计对比：
├── 按需：$34,881.60 × 3 = $104,644.80
├── CUD：$14,997.60 × 3 = $44,992.80
└── 节省：$59,652.00（57%）

结论：如果工作负载稳定运行3年，CUD是必须的！
```

### 1.3 Cloud Storage计费详解

Storage的计费比Compute复杂，因为它有多个计费维度。

#### 1.3.1 四维计费模型

```
Cloud Storage费用 = 存储费用 + 操作费用 + 网络费用 + 检索费用
```

让我逐个解析：

```
维度1：存储费用（按月计费）

存储类别与价格（us-central1）：
┌──────────────────────────────────────────────────────────────────┐
│  Standard    │  $0.020/GB-月  │ 频繁访问                          │
│  Nearline    │  $0.010/GB-月  │ 每月访问<1次，30天最小保留        │
│  Coldline    │  $0.004/GB-月  │ 每季度访问<1次，90天最小保留      │
│  Archive     │  $0.0012/GB-月 │ 每年访问<1次，365天最小保留       │
└──────────────────────────────────────────────────────────────────┘

维度2：操作费用（按次计费）

Class A操作（写入类）：
- CreateBucket
- UploadObject
- ComposeObject
- CopyObject
- ListBuckets
- ListObjects

Class B操作（读取类）：
- GetObject
- GetObjectMetadata

价格示例（Standard）：
├── Class A：$5.00 / 10,000次操作
└── Class B：$0.40 / 10,000次操作

维度3：网络费用

出口流量（从GCP到互联网）：
├── 北美：$0.12/GB（0-10TB后阶梯降价）
├── 欧洲：$0.12/GB
├── 亚洲：$0.15-0.20/GB
└── 中国：可能更贵（按区域）

重要：同一区域内传输免费！

维度4：检索费用（仅适用于冷存储）

- Nearline检索：$0.02/GB
- Coldline检索：$0.05/GB
- Archive检索：$0.50/GB

结论：把数据移到Coldline前要三思！
```

#### 1.3.2 存储费用真实计算

```
场景：5TB数据，分布在多个存储类别

当前配置（全部Standard）：
├── 存储费用：5TB × 1024GB/TB × $0.020 = $102.40/月
├── 操作费用假设：每天1000次Class B = 30,000次/月
│   └── Class B：30,000 × $0.40/10,000 = $1.20/月
└── 总计：$103.60/月

优化配置（生命周期分层）：
├── 2TB Standard（活跃数据）
│   └── 2TB × 1024 × $0.020 = $40.96/月
├── 2TB Nearline（30天后）
│   └── 2TB × 1024 × $0.010 = $20.48/月
├── 1TB Coldline（90天后）
│   └── 1TB × 1024 × $0.004 = $4.10/月
├── 操作费用增加（假设分层操作产生更多Class A）
│   └── +$5.00/月
└── 总计：$70.54/月

节省：$33.06/月 = 32%
```

### 1.4 BigQuery计费详解

BigQuery有两种计费模式，理解它们的区别至关重要。

#### 1.4.1 按查询计费 vs 预留容量

```
BigQuery两种计费模式：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  模式1：按需计费（On-demand）                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  价格：$5.00 per TB 扫描的数据量                          │   │
│  │                                                           │   │
│  │  计费原理：                                                │   │
│  │  - 只计算查询扫描的数据量，不包括缓存结果                   │   │
│  │  - SELECT * 扫描全表 → 贵                                 │   │
│  │  - SELECT只查需要的列 → 便宜                               │   │
│  │  - WHERE过滤后 → 更便宜                                   │   │
│  │                                                           │   │
│  │  示例：                                                    │   │
│  │  查询"SELECT * FROM table" 扫描了10GB                     │   │
│  │  费用 = 0.01TB × $5.00 = $0.05                          │   │
│  │                                                           │   │
│  │  适用：不可预测的负载、间歇性查询                         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  模式2：预留容量（Flat-rate）                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  价格：按Slot计费                                          │   │
│  │  - 100 Slot：$2,000/月                                    │   │
│  │  - 500 Slot：$10,000/月                                   │   │
│  │                                                           │   │
│  │  计费原理：                                                │   │
│  │  - 购买固定的查询容量（Slot）                             │   │
│  │  - 无论查询多少数据都不额外收费                           │   │
│  │  - 适合高强度、持续性的查询工作负载                        │   │
│  │                                                           │   │
│  │  适用：数据仓库、BI报表、持续分析                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 1.4.2 两种模式的分界点计算

理解什么时候该切换到预留容量：

```
决策逻辑：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  问题：我的查询负载应该用按需还是预留容量？                       │
│                                                                  │
│  关键指标：月度查询量（TB扫描）                                  │
│                                                                  │
│  计算分界点：                                                    │
│  100 Slot月费 = $2,000                                          │
│  按需价格 = $5.00/TB                                            │
│  分界点 = $2,000 / $5.00 = 400 TB/月                            │
│                                                                  │
│  结论：                                                          │
│  ├── 月扫描量 < 400TB → 按需更划算                              │
│  └── 月扫描量 > 400TB → 预留容量更划算                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 1.5 网络计费详解

网络费用经常被忽视，但它可能是账单的重要组成部分。

#### 1.5.1 网络费用的几个关键点

```
GCP网络计费要点：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  入口（Ingress）：免费                                           │
│  ├── 数据传入GCP                                                │
│  └── 例：本地服务器上传文件到Cloud Storage                       │
│                                                                  │
│  出口（Egress）：收费                                           │
│  ├── 数据传出GCP                                                │
│  └── 例：从GCP VM下载文件到本地                                  │
│                                                                  │
│  同一区域内传输：免费                                            │
│  ├── us-central1的VM访问us-central1的Cloud Storage              │
│  └── 同一区域内任何通信                                          │
│                                                                  │
│  区域间传输（Same Region不同区域）：收费                        │
│  ├── us-central1 → us-east1                                     │
│  └── 价格：$0.01-0.02/GB                                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. 成本监控与告警体系

不理解当前的支出情况，优化无从谈起。很多公司月底看账单才发现超支，但为时已晚。

### 2.1 建立监控体系的原则

```
成本监控的核心原则：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  1. 实时性：知道什么时候花了多少钱                               │
│     - GCP计费数据通常有几小时延迟                                 │
│     - 但趋势可以实时观察                                         │
│                                                                  │
│  2. 可追溯性：知道钱花在哪里                                     │
│     - 按项目/服务/资源标签分类                                   │
│     - 支持下钻分析                                               │
│                                                                  │
│  3. 可控性：超支能及时发现                                       │
│     - 设置预算和告警                                             │
│     - 多级通知机制                                               │
│                                                                  │
│  4. 可解释性：知道为什么花了这么多                               │
│     - 对比历史数据                                               │
│     - 分析变化原因                                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 GCP成本管理工具全景

```
GCP成本管理工具：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  工具1：Billing Dashboard（Console）                             │
│  ├── 位置：Console → Billing                                    │
│  ├── 功能：账单总览、趋势图、TOP项目                             │
│  └── 适合：快速了解整体情况                                      │
│                                                                  │
│  工具2：Cost Explorer（Console）                                 │
│  ├── 位置：Billing → Cost Explorer                              │
│  ├── 功能：灵活查询、多维度分组、趋势分析                        │
│  └── 适合：深入分析成本构成                                      │
│                                                                  │
│  工具3：Budgets & Alerts                                         │
│  ├── 位置：Billing → Budgets & alerts                           │
│  ├── 功能：设置预算阈值、超阈值告警                              │
│  └── 适合：主动发现异常支出                                      │
│                                                                  │
│  工具4：BigQuery Billing Export                                  │
│  ├── 位置：Billing → Billing Export                             │
│  ├── 功能：导出详细账单到BigQuery                               │
│  └── 适合：自定义分析、SQL查询                                   │
│                                                                  │
│  工具5：Cloud Monitoring + Alerting                              │
│  ├── 位置：Monitoring → Dashboards/Alerts                       │
│  ├── 功能：自定义监控图表、告警                                  │
│  └── 适合：与性能监控结合                                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.3 预算与告警配置

预算是成本控制的第一道防线。

#### 2.3.1 为什么需要多级告警？

```
多级告警机制：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  单级告警的问题：                                                │
│  - 只有100%告警                                                 │
│  - 收到告警时已经超支或接近超支                                   │
│  - 没有时间采取行动                                              │
│                                                                  │
│  多级告警的好处：                                                │
│  - 50%告警：提醒关注                                            │
│  - 80%告警：需要采取行动                                        │
│  - 100%告警：紧急处理                                           │
│                                                                  │
│  示例场景：$10,000月度预算                                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░  50%     │     │
│  │  ↑ 50%告警：$5,000，开始关注                              │     │
│  │  ██████████████████████████████████░░░░░░░░░  80%     │     │
│  │                                     ↑ 80%告警：$8,000  │     │
│  │  ████████████████████████████████████████░░  100%    │     │
│  └─────────────────────────────────────────────────────────┘     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.3.2 预算配置实战

```powershell
# 准备工作：获取Billing Account ID
gcloud beta billing accounts list

# 假设 Billing Account ID 是：XXXXX-XXXXX-XXXXX

# 方法：通过Console创建
# Console路径：Billing → Budgets & alerts → CREATE BUDGET

# 预算配置示例：
# - 名称：Production Monthly Budget
# - 关联项目：production-*
# - 总预算：$50,000/月
# - 告警阈值：50%, 80%, 100%

# 创建通知渠道（Pub/Sub + Email/Slack）
gcloud pubsub topics create budget-alerts

# gcloud beta预算创建
gcloud beta billing budgets create `
  --billing-account=XXXXX-XXXXX-XXXXX `
  --display-name="Production Budget" `
  --budget-amount=50000 `
  --currency-code=USD `
  --threshold-rule=threshold=0.5,basis=CURRENT_SPEND `
  --threshold-rule=threshold=0.8,basis=CURRENT_SPEND `
  --threshold-rule=threshold=1.0,basis=CURRENT_SPEND `
  --notification-channels=projects/my-project/notificationChannels/123456789
```

#### 2.3.3 告警阈值设计最佳实践

```
不同环境的告警阈值建议：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  开发/测试环境：                                                  │
│  ├── 50%：提醒检查是否有异常                                     │
│  ├── 75%：暂停非必要资源创建                                    │
│  └── 100%：立即停止非生产资源                                   │
│                                                                  │
│  生产环境：                                                       │
│  ├── 50%：技术负责人关注                                        │
│  ├── 70%：开始评估是否需要扩容                                  │
│  ├── 90%：紧急响应，可能需要追加预算                            │
│  └── 100%：财务和管理层介入                                     │
│                                                                  │
│  绝对值告警（补充百分比告警）：                                   │
│  - 单个项目日支出超过 $1,000 立即告警                           │
│  - 单个服务日支出超过 $500 立即告警                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.4 BigQuery账单导出与分析

这是深度成本分析的必备技能。

#### 2.4.1 为什么要导出到BigQuery？

```
Console的Cost Explorer vs BigQuery查询：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  Cost Explorer优点：                                             │
│  ├── 可视化直观                                                 │
│  ├── 预设报表丰富                                               │
│  └── 适合快速查看                                               │
│                                                                  │
│  BigQuery查询优点：                                             │
│  ├── SQL灵活查询，支持复杂分析                                   │
│  ├── 可以JOIN其他业务数据                                       │
│  ├── 可以自定义报表和可视化                                      │
│  ├── 可以做预测分析                                             │
│  └── 支持大规模历史数据                                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 2.4.2 配置账单导出

```powershell
# 步骤1：创建BigQuery数据集
gcloud bigquery datasets create billing_export --location=US

# 步骤2：启用详细账单导出
# Console：Billing → Billing Export → Detailed Usage
# 选择项目和你创建的数据集

# 导出后的表结构：
# 项目.Billing_export.gcp_billing_export_v1_XXXXXXXX
# 包含字段：
# - project.id
# - project.name
# - service.description
# - sku.description
# - usage_start_time
# - usage_end_time
# - cost
# - currency
# - credits[]
# - labels[]
# - location.location
```

#### 2.4.3 深度分析SQL示例

**示例1：按项目和服务的月度费用分析**

```sql
-- 月度费用汇总
SELECT
  DATE_TRUNC(DATE(usage_start_time), MONTH) AS billing_month,
  project.name AS project_name,
  service.description AS service,
  ROUND(SUM(cost), 2) AS total_cost,
  ROUND(SUM(credits.amount), 2) AS total_credits,
  ROUND(SUM(cost + IFNULL(credits.amount, 0)), 2) AS net_cost
FROM
  `project-id.billing_export.gcp_billing_export_v1_XXXXXXXX`
WHERE
  DATE(usage_start_time) BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY
  billing_month, project_name, service
ORDER BY
  billing_month DESC, net_cost DESC
```

**示例2：找出费用增长最快的服务**

```sql
-- 月度环比分析
WITH monthly_costs AS (
  SELECT
    DATE_TRUNC(DATE(usage_start_time), MONTH) AS month,
    service.description AS service,
    SUM(cost) AS cost
  FROM
    `project-id.billing_export.gcp_billing_export_v1_XXXXXXXX`
  WHERE
    DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
  GROUP BY
    month, service
)
SELECT
  service,
  LAG(month) OVER (PARTITION BY service ORDER BY month) AS prev_month,
  LAG(cost) OVER (PARTITION BY service ORDER BY month) AS prev_cost,
  month AS current_month,
  cost AS current_cost,
  ROUND((cost - LAG(cost) OVER (PARTITION BY service ORDER BY month)) / LAG(cost) OVER (PARTITION BY service ORDER BY month) * 100, 2) AS growth_percent
FROM
  monthly_costs
QUALIFY
  growth_percent > 20
ORDER BY
  growth_percent DESC
```

**示例3：日粒度费用趋势（用于检测异常）**

```sql
-- 最近30天每日费用
SELECT
  DATE(usage_start_time) AS date,
  ROUND(SUM(cost), 2) AS daily_cost
FROM
  `project-id.billing_export.gcp_billing_export_v1_XXXXXXXX`
WHERE
  DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY
  date
ORDER BY
  date DESC
```

---

## 3. Compute Engine成本优化

Compute Engine通常是GCP账单的最大组成部分。

### 3.1 机器类型选择策略

#### 3.1.1 机器类型家族对比

```
GCP机器类型家族：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  E2 系列（经济型）                                                │
│  ├── 特点：价格最优，突发性能                                     │
│  ├── 适用：Web服务器、开发测试、内存不敏感场景                    │
│  ├── vCPU/内存比：灵活，可1:1到1:8                              │
│  └── 优势：价格比N1低15-30%                                     │
│                                                                  │
│  N1 系列（标准型）                                                │
│  ├── 特点：成熟稳定，通用工作负载                                 │
│  ├── 适用：大多数生产工作负载                                    │
│  └── 优势：成熟的预定义优化                                     │
│                                                                  │
│  N2 系列（新一代）                                                │
│  ├── 特点：新一代处理器，性能更好                                │
│  └── 优势：比N1性能提升约20%，价格差不多                          │
│                                                                  │
│  C2 系列（计算优化）                                             │
│  ├── 特点：高主频CPU，计算密集型                                 │
│  ├── 适用：HPC、游戏服务器、批处理                              │
│  └── 优势：最高主频4.0GHz+                                      │
│                                                                  │
│  M2/M3 系列（内存优化）                                          │
│  ├── 特点：大内存                                               │
│  ├── 适用：内存数据库、数据仓库                                  │
│  └── 优势：内存可达6TB+                                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.1.2 选择决策树

```
机器类型选择流程：

开始
  │
  ├─ 计算密集型？（HPC、批处理、游戏服务器）
  │   └─ C2系列
  │
  ├─ 内存密集型？（SAP、SQL Server、Redis）
  │   └─ M2/M3系列
  │
  └─ 通用工作负载？
      ├─ 预算敏感？→ E2系列
      └─ 需要稳定性能？→ N1或N2系列
```

### 3.2 定时开关机策略

这是非生产环境最重要的省钱手段。

#### 3.2.1 什么时候应该关机？

```
适合定时关机的场景：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  开发/测试环境                                                   │
│  ├── 工作时间（9:00-18:00）运行                                 │
│  ├── 周末完全关闭                                               │
│  └── 节省潜力：约75%（只运行工作日8小时）                       │
│                                                                  │
│  CI/CD构建环境                                                   │
│  ├── 只在有构建任务时运行                                       │
│  └── 节省潜力：取决于构建频率，可能50-80%                       │
│                                                                  │
│  不适合定时关机的场景：                                          │
│  ├── 生产环境（24/7必须）                                       │
│  └── 需要保持热备的服务                                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.2.2 Instance Schedule实战

```powershell
# Instance Schedule使用步骤：

# 步骤1：创建Schedule
# Console: Compute Engine → Instance schedules
# 点击 "CREATE SCHEDULE"

# 配置示例：
# - Name: dev-env-schedule
# - Time zone: Asia/Shanghai
# - Start time: 09:00 (工作日)
# - Stop time: 18:00 (工作日)
# - Recurrence: Monday - Friday

# 步骤2：将Schedule应用到VM（通过标签）
# 给VM添加标签：schedule=dev-env-schedule

# 步骤3：验证
gcloud compute instances list --filter="labels.schedule=dev-env-schedule"
```

#### 3.2.3 Cloud Scheduler + Functions实战（高级）

```python
# Cloud Function：智能开关机
import functions_framework
from google.cloud import compute_v1
from datetime import datetime
import pytz

@functions_framework.cloud_event
def manage_dev_vms(cloud_event):
    """根据规则管理开发环境VM"""
    compute_client = compute_v1.InstancesClient()
    project = "my-project"
    zone = "us-central1-a"

    tz = pytz.timezone('Asia/Shanghai')
    now = datetime.now(tz)
    hour = now.hour
    day = now.weekday()

    should_run = (0 <= day <= 4) and (9 <= hour < 18)

    filter_expr = 'labels.env=dev'
    instances = compute_client.list(project=project, zone=zone, filter=filter_expr)

    for instance in instances.items:
        current_status = instance.status

        if should_run and current_status != 'RUNNING':
            compute_client.start(project=project, zone=zone, instance=instance.name)
        elif not should_run and current_status == 'RUNNING':
            compute_client.stop(project=project, zone=zone, instance=instance.name)
```

```powershell
# 部署Cloud Function
gcloud functions deploy manage-dev-vms `
    --runtime=python310 `
    --trigger-http `
    --region=us-central1

# 创建Cloud Scheduler作业
gcloud scheduler jobs create http hourly-vm-check `
    --schedule="0 * * * *" `
    --uri="https://us-central1-my-project.cloudfunctions.net/manage-dev-vms" `
    --location=us-central1
```

### 3.3 权利调整（Right Sizing）

#### 3.3.1 什么是权利调整？

```
权利调整的定义：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  过度配置（Over-provisioned）                                   │
│  配置了4 vCPU，但平均只用了1 vCPU → 浪费75%                     │
│                                                                  │
│  正确配置（Right-sized）                                         │
│  配置匹配实际使用，平均利用率在60-80%                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.3.2 GCP的权利调整推荐

```
查看权利调整推荐：
Console路径：Compute Engine → Recommendations

推荐类型：
├── Right-size instances（降低配置）
├── Delete unused disks（删除未使用磁盘）
└── Delete unused addresses（删除未使用IP）

推荐依据：
├── CPU使用率历史（7-30天）
├── 内存使用率历史
└── 磁盘I/O历史
```

#### 3.3.3 权利调整决策流程

```
权利调整决策流程：

收集数据（至少7天，最好30天）
│
├─ CPU使用率
│   ├─ 平均值 < 30%？→ 可以降配
│   ├─ 平均值 30-60%？→ 可能可以降配
│   └─ 平均值 > 80%？→ 考虑升级
│
├─ 内存使用率
│   └─ 同样逻辑
│
└─ 预测新配置
    ├─ 选择目标机器类型
    ├─ 计算成本节省
    └─ 确保新配置满足峰值需求
```

### 3.4 抢占式VM（Spot VM）深度解析

#### 3.4.1 Spot VM的工作原理

```
Spot VM vs On-Demand VM：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  On-Demand VM：                                                 │
│  ├── GCP保证可用性                                              │
│  └── 价格：100%                                                 │
│                                                                  │
│  Spot VM：                                                       │
│  ├── GCP不保证可用性（利用闲置容量）                             │
│  ├── GCP可随时收回（通常提前60秒通知）                            │
│  └── 价格：比On-Demand便宜60-91%                                │
│                                                                  │
│  回收机制：                                                      │
│  正常运行时 → GCP需要容量 → 发送抢占信号 → 60秒优雅关闭 → 终止 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.4.2 Spot VM适用场景

```
适合Spot VM的场景：
✓ 批处理作业（可以分片处理，有checkpoint机制）
✓ CI/CD流水线（构建任务通常30分钟以内）
✓ 数据分析/ETL（可以分批处理，有断点续传）
✓ 机器学习训练（有checkpoint保存）
✓ 渲染农场（渲染任务是独立的）

不适合Spot VM的场景：
✗ 数据库主节点
✗ API服务器（需要持续响应）
✗ 实时交易系统
```

#### 3.4.3 Spot VM + MIG实现高可用批处理

```
架构设计：
┌──────────────────────────────────────────────────────────────────┐
│                    Cloud Load Balancer                           │
│                            │                                      │
│           ┌─────────────────────────────────┐                   │
│           │  Managed Instance Group (MIG)    │                   │
│           │  ┌─────┐ ┌─────┐ ┌─────┐      │                   │
│           │  │Spot │ │Spot │ │Spot │      │                   │
│           │  │ VM  │ │ VM  │ │ VM  │      │                   │
│           │  └─────┘ └─────┘ └─────┘      │                   │
│           └─────────────────────────────────┘                   │
│                            │                                      │
│                            ▼                                      │
│                  Cloud Pub/Sub (任务队列)                        │
│                                                                  │
│  关键点：                                                        │
│  1. Pub/Sub保证任务不丢失                                        │
│  2. Spot VM被回收时，任务回到队列                               │
│  3. MIG自动扩缩容                                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 3.4.4 Spot VM实践配置

```powershell
# 创建Spot VM实例模板
gcloud compute instance-templates create spot-batch-template `
    --machine-type=e2-medium `
    --image-family=debian-11 `
    --image-project=debian-cloud `
    --provisioning-model=SPOT `
    --instance-termination-action=DELETE `
    --spot-preemptible-timeout=60s `
    --region=us-central1

# 参数说明：
# --provisioning-model=SPOT：创建为Spot VM
# --instance-termination-action=DELETE：抢占时自动删除
# --spot-preemptible-timeout=60s：60秒优雅关闭时间

# 创建MIG
gcloud compute instance-groups managed create spot-batch-mig `
    --base-instance-name=spot-worker `
    --template=spot-batch-template `
    --size=5 `
    --region=us-central1

# 配置自动伸缩
gcloud compute instance-groups managed set-autoscaling spot-batch-mig `
    --region=us-central1 `
    --min-num-replicas=2 `
    --max-num-replicas=20 `
    --target-cpu-utilization=0.7
```

---

## 4. Cloud Storage成本优化

### 4.1 存储类别选择深度分析

#### 4.1.1 四种存储类别的详细对比

```
存储类别核心参数对比：
┌──────────────────────────────────────────────────────────────────┐
│  Standard    │  $0.020/GB-月  │ 无最小保留  │ 无检索费 │ 活跃数据│
│  Nearline   │  $0.010/GB-月  │ 30天最小    │ $0.01/GB │ 每月<1次│
│  Coldline   │  $0.004/GB-月  │ 90天最小    │ $0.05/GB │ 每季<1次│
│  Archive    │  $0.0012/GB-月 │ 365天最小   │ $0.50/GB │ 每年<1次│
└──────────────────────────────────────────────────────────────────┘
```

#### 4.1.2 最小存储时间的陷阱

```
最小存储时间陷阱：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  场景：存储日志文件，30天后删除                                  │
│  ├── 预期：用Nearline（便宜）                                   │
│  └── 陷阱：Nearline最小30天，30天后删除仍需付30天费用           │
│                                                                  │
│  正确做法：                                                      │
│  ├── 30天内会删除 → Standard（无最小存储时间）                   │
│  └── 会存满30天 → Nearline                                       │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 4.1.3 存储类别选择决策树

```
存储类别选择流程：

数据访问频率？
│
├─ 每天访问多次 → Standard
│
├─ 每月访问几次
│   ├─ 保留<30天？→ Standard
│   └─ 保留≥30天？→ Nearline
│
├─ 每季度访问一次
│   ├─ 保留<90天？→ Nearline
│   └─ 保留≥90天？→ Coldline
│
└─ 每年访问一次 → Archive
```

### 4.2 生命周期管理实战

#### 4.2.1 生命周期管理原理

```
手动管理 vs 自动管理：

手动管理：
今天创建 → 30天后手动改存储类别 → 90天后手动改 → 365天后手动删
问题：人工操作繁琐，容易遗漏

自动管理：
设置规则，GCP自动执行
Rule: age=30 → Nearline
Rule: age=90 → Coldline
Rule: age=365 → Delete
```

#### 4.2.2 生命周期规则配置

```json
// lifecycle-rules.json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 30, "matchesPrefix": ["logs/"]}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90, "matchesPrefix": ["logs/"]}
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

```powershell
# 应用生命周期规则
gcloud storage buckets update gs://my-bucket `
    --lifecycle-file=lifecycle-rules.json
```

#### 4.2.3 真实案例：日志存储成本优化

```
场景：电商平台日志存储优化

原始数据：
├── 每日生成：50GB日志
├── 当前保留：90天
├── 存储类别：全部Standard
└── 当前月费用：50GB × 90 × $0.020 = $90/月

优化方案：
├── 0-7天：Standard（频繁访问）
├── 8-30天：Nearline（偶尔查看）
├── 31-90天：Coldline（审计需要）
└── 90天后：删除

优化后月费用：约$30/月
节省：$60/月（67%）
```

---

## 5. 其他服务成本优化

### 5.1 BigQuery优化

#### 5.1.1 查询成本优化技巧

```
查询成本优化核心原则：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  原则1：只查询需要的列                                           │
│  SELECT user_id, timestamp FROM table  # 好                      │
│  SELECT * FROM table  # 不好，扫描所有列                          │
│                                                                  │
│  原则2：使用WHERE过滤                                           │
│  SELECT * FROM table WHERE date = '2024-01-01'  # 好            │
│  SELECT * FROM table  # 不好，先扫描全表再过滤                   │
│                                                                  │
│  原则3：使用分区表                                              │
│  分区表只扫描目标分区，大幅减少扫描量                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 5.1.2 分区表与聚类表

```
分区 vs 聚类：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  分区表：按时间/整数列分割成多个物理分区                          │
│  - 查询时可以跳过不相关的分区                                    │
│  - 适合：按时间范围查询                                         │
│                                                                  │
│  聚类表：按指定列排序存储                                        │
│  - 相同值的行物理上靠近存储                                      │
│  - 适合：经常按某些列过滤/分组                                   │
│                                                                  │
│  可以同时使用：                                                  │
│  CREATE TABLE table                                             │
│  PARTITION BY DATE(timestamp)                                   │
│  CLUSTER BY user_id, event_type                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 5.2 Cloud Functions优化

#### 5.2.1 费用模型解析

```
Cloud Functions计费：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  免费额度（每月）：                                              │
│  ├── 调用次数：200万次                                          │
│  ├── 计算时间：40万GB-秒                                        │
│  └── 出口流量：5GB                                             │
│                                                                  │
│  超出后价格：                                                    │
│  ├── 调用次数：$0.40/100万次                                    │
│  └── 计算时间：$0.0000025/GB-秒                                 │
│                                                                  │
│  GB-秒计算：GB-秒 = 内存配置(GB) × 执行时间(秒)                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 5.2.2 优化策略

```
Cloud Functions成本优化：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  策略1：选择合适的内存配置                                       │
│  满足最低需求的内存配置，过高的内存 = 过高的费用                  │
│                                                                  │
│  策略2：减少执行时间                                            │
│  - 避免不必要的依赖加载                                         │
│  - 使用连接池复用数据库连接                                      │
│  - 减少冷启动时间                                               │
│                                                                  │
│  策略3：减少调用次数                                            │
│  - 批量处理请求                                                 │
│  - 缓存常用结果                                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 5.3 网络成本优化

#### 5.3.1 区域选择的艺术

```
网络成本与区域选择：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  原则1：数据消费者和数据源同区域                                  │
│  # 好：VM和Cloud SQL都在us-central1 → 同区域，免费               │
│  # 不好：VM在us-central1，Cloud SQL在europe-west1 → 跨区域收费   │
│                                                                  │
│  原则2：用户最近的区域                                           │
│  如果用户主要在中国 → 使用asia-east1 (台湾) 或 asia-northeast1  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

#### 5.3.2 使用CDN减少出口流量

```
Cloud CDN工作原理：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  没有CDN：                                                       │
│  用户 → GCP VM/Storage → 用户（每次都走GCP出口）                 │
│  10000请求 × 1MB = 10GB出口 → 费用：$1.20                       │
│                                                                  │
│  使用CDN：                                                       │
│  第一次：用户 → CDN Edge → 源站 → CDN缓存                        │
│  后续：用户 → CDN Edge → 用户（缓存命中）                        │
│  80%缓存命中率：2000请求 × 1MB = 2GB → 费用：$0.24             │
│  节省：80%！                                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. 承诺使用折扣(CUD)深度解析

### 6.1 CUD的类型详解

```
两种CUD对比：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  资源型CUD（Resource-based CUD）                                  │
│  ├── 针对特定资源配置                                            │
│  ├── 指定机器类型和区域                                          │
│  ├── 折扣：1年约30%，3年约57%                                   │
│  └── 适用：稳定、单一的工作负载                                  │
│                                                                  │
│  灵活CUD（Flexible CUD）                                          │
│  ├── 购买vCPU小时数而不是特定机器                                │
│  ├── 可以在区域内任意机器类型使用                                │
│  ├── 折扣：1年约16%，3年约37%                                   │
│  └── 适用：工作负载多样                                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 6.2 CUD购买决策流程

```
CUD购买决策：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  问题1：工作负载是否稳定？                                       │
│  ├─ 稳定（全年运行）→ 继续                                       │
│  └─ 不稳定 → 不适合CUD                                          │
│                                                                  │
│  问题2：选择资源型还是灵活型？                                    │
│  ├─ 工作负载固定 → 资源型（更高折扣）                           │
│  └─ 工作负载多样 → 灵活型                                       │
│                                                                  │
│  问题3：承诺1年还是3年？                                         │
│  └─ 建议：先买1年，观察后再买3年                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 6.3 CUD实战购买流程

```powershell
# 步骤1：分析当前使用量
gcloud compute instances list --format="table(name,machineype,zone)"

# 步骤2：购买资源型CUD
gcloud compute commitments create production-cud `
    --region=us-central1 `
    --plan=36-month `
    --resources=vcpu=40,memory=150GiB `
    --machine-type=n1-standard-4

# 步骤3：验证CUD已生效
gcloud compute commitments list

# 步骤4：创建使用CUD的VM
gcloud compute instances create prod-server-1 `
    --machine-type=n1-standard-4 `
    --zone=us-central1-a `
    --commitment=projects/my-project/regions/us-central1/commitments/production-cud
```

### 6.4 CUD常见陷阱

```
CUD使用中的常见问题：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  陷阱1：买了不用也收钱                                           │
│  CUD是承诺，无论是否使用都会计费                                 │
│  买了40 vCPU但只用20 vCPU → 浪费一半                             │
│                                                                  │
│  陷阱2：买了不匹配的机器类型                                     │
│  买了N1的CUD但后来需要T2A ARM机器 → 无法使用                     │
│                                                                  │
│  陷阱3：区域不匹配                                               │
│  买了us-central1的CUD但在europe-west1创建VM → 无法使用           │
│                                                                  │
│  最佳实践：                                                      │
│  1. 先观察2-4周实际使用量                                        │
│  2. CUD数量应等于或略低于平均使用量                              │
│  3. 从1年开始，熟悉后再买3年                                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 7. 成本自动化与治理

### 7.1 资源标签策略

标签是成本分摊和追踪的基础。

```
推荐标签方案：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  env（环境）          │ dev, staging, prod                      │
│  team（团队）        │ team-a, team-b                           │
│  project（业务项目）  │ e-commerce, crm                          │
│  cost-center（成本中心）│ CC101, CC102                          │
│  service（服务名）   │ api, web, worker                         │
│  schedule（调度）    │ 24x7, business-hours                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 7.2 自动化清理策略

```
未使用资源清理检查清单：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ☑ 停止超过7天的VM（开发/测试环境）                              │
│  ☑ 删除未附加的持久磁盘                                         │
│  ☑ 释放未使用的静态IP                                           │
│  ☑ 删除空的存储桶                                               │
│  ☑ 清理超过90天的旧快照                                         │
│  ☑ 删除未使用的实例模板                                         │
│  ☑ 清理旧的快照                                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 7.3 配额管理

```
配额管理的重要性：
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  两个作用：                                                      │
│  1. 控制成本：防止意外创建大量资源                                │
│  2. 防止滥用：限制最大使用量                                     │
│                                                                  │
│  建议配额设置：                                                  │
│  ├── 开发环境：CPU配额8（而不是默认24）                         │
│  ├── GPU配额：0（除非确实需要）                                  │
│  └── 生产环境：根据实际需求设置，有上限                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. 实战省钱案例

### 案例1：开发环境优化（节省77%）

```
现状：
- 20台开发VM，n1-standard-2
- 24小时运行
- 月费用：$800

优化措施：
1. 切换到E2机器类型（节省20%）
2. 定时开关机（工作日9:00-18:00）（节省75%）
3. 权利调整（某些降配到e2-small）

结果：
- 月费用：$180
- 节省：$620/月 (77.5%)
```

### 案例2：存储分层优化（节省81%）

```
现状：
- 5TB日志数据，全部Standard存储
- 月存储费用：$130

优化措施：
1. 配置生命周期管理
2. 7天后 → Nearline
3. 30天后 → Coldline
4. 1年后 → Archive

结果：
- 月存储费用：$25
- 节省：$105/月 (80.8%)
```

### 案例3：使用CUD（节省57%）

```
现状：
- 10台n1-standard-4稳定运行
- 按需付费：$1,387/月

优化措施：
- 购买3年资源型CUD

结果：
- CUD费用：$596/月
- 节省：$791/月 (57%)
```

---

## 总结：成本优化检查清单

```
日常监控：
☐ 每日查看成本趋势
☐ 检查预算告警
☐ 识别异常支出

Compute Engine：
☐ 非生产环境定时开关机
☐ 查看权利调整推荐
☐ 稳定工作负载使用CUD
☐ 可中断负载使用Spot VM

Cloud Storage：
☐ 配置生命周期管理
☐ 选择合适的存储类别
☐ 清理未使用的数据

BigQuery：
☐ 优化查询只扫描需要的列
☐ 使用分区表
☐ 考虑预留容量模式

网络：
☐ 资源在同一区域
☐ 使用CDN减少出口
☐ 清理未使用的静态IP

治理：
☐ 所有资源打标签
☐ 设置项目配额
☐ 定期清理未使用资源
```

**记住：成本优化不是一次性工作，是持续改进的过程！每月review一次成本，持续优化。**
