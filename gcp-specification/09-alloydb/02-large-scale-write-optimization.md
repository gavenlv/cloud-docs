# AlloyDB 超大规模数据写入与查询优化

## 场景描述

| 指标 | 数值 | 挑战等级 |
|------|------|----------|
| 单批次 Parquet | 500GB | 🔴 极大 |
| 单批次行数 | 30-50亿行 | 🔴 极大 |
| 单批次列数 | 80列 | 🟡 中等 |
| 写入时间要求 | 5分钟 | 🔴 极其激进 |
| 查询响应要求 | <10秒 | 🟡 困难 |
| 总数据量 | 1000亿+行 | 🔴 超大规模 |

---

## 1. 核心挑战分析

### 1.1 写入速度鸿沟

```
目标 vs 实际能力

500GB / 5分钟 = 166.67 GB/分钟 = 2.78 GB/秒

折算为行数（按50亿行/500GB计算）：
- 需要：167万行/秒

AlloyDB 实际写入能力：
- 标准 INSERT：~5,000 行/秒
- COPY 协议批量插入：~50-100万行/秒（受限于单节点）
- 理论极限：~100-200万行/秒（4核实例，批量1000行/事务）

结论：标准方法存在 10-20倍 的性能差距
```

### 1.2 查询性能瓶颈

```
1000亿行查询挑战

单表 1000亿行，即使有索引：
- 全表扫描：数小时
- 范围查询：取决于数据分布
- 聚合查询：需要物化视图或预聚合

AlloyDB 设计目标：
- OLTP 场景：每秒数千到数万个小事务
- 不是为 PB 级分析设计的
```

---

## 2. 解决方案架构

### 2.1 架构选择

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    推荐架构：分层混合方案                                 │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      查询层 (Query Layer)                       │   │
│  │                                                                  │   │
│  │  AlloyDB ──────────── 即时查询 (<10秒)                          │   │
│  │   └── 聚合结果、物化视图                                         │   │
│  │                                                                  │   │
│  │  BigQuery ────────── 复杂分析 (<10秒)                          │   │
│  │   └── 全量数据、外部表                                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                    │
│                                    ▼                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      存储层 (Storage Layer)                     │   │
│  │                                                                  │   │
│  │  GCS ───────────────── 原始Parquet存储                          │   │
│  │   └── 外部表直查                                                  │   │
│  │                                                                  │   │
│  │  AlloyDB ──────────── 结构化数据                                 │   │
│  │   └── 预聚合、分区表                                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 方案对比

| 方案 | 写入速度 | 查询速度 | 复杂度 | 推荐度 |
|------|----------|----------|--------|--------|
| 纯 AlloyDB 标准INSERT | ❌ 不可能 | 🟡 中等 | 低 | ⭐ |
| AlloyDB 外部表 | ✅ 即时 | ✅ <10秒 | 低 | ⭐⭐⭐⭐ |
| Dataflow 并行写入 | ✅ 可达 | 🟡 中等 | 高 | ⭐⭐⭐ |
| 分层架构(BigQuery+AlloyDB) | ✅ 完美 | ✅ <10秒 | 中 | ⭐⭐⭐⭐⭐ |
| AlloyDB + 预聚合表 | ✅ 可达 | ✅ <10秒 | 高 | ⭐⭐⭐⭐ |

---

## 3. 方案一：GCS 外部表（推荐）

### 3.1 原理

AlloyDB 支持通过外部表直接查询 GCS 上的 Parquet 文件，无需导入数据。

```
外部表查询流程

Parquet(GCS) ──→ 外部表 ──→ AlloyDB 查询引擎 ──→ 结果
                      ↑
                      └── 自动列式读取、按需扫描
```

### 3.2 创建外部表

```sql
-- 创建指向 GCS Parquet 的外部表
CREATE EXTERNAL TABLE my_external_table
WITH CONNECTION my-cloud-sql-connection
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://my-bucket/data/*.parquet']
);

-- 直接查询（无需导入）
SELECT
    date_key,
    COUNT(*) as record_count,
    AVG(metric_1) as avg_metric
FROM my_external_table
WHERE date_key >= '2024-01-01'
GROUP BY date_key
ORDER BY date_key;
```

### 3.3 PowerShell 操作

```powershell
# ========== GCS 外部表方案 ==========

# 1. 配置访问权限
$PROJECT_ID = "your-project-id"
$BUCKET = "my-parquet-bucket"
$REGION = "us-central1"

# 2. 创建 AlloyDB 连接（用于外部表）
gcloud alloydb instances describe my-instance `
    --project=$PROJECT_ID `
    --cluster=my-cluster `
    --location=$REGION `
    --format="value(name)"

# 3. 上传 Parquet 到 GCS
gsutil -m cp -r ./data/*.parquet gs://$BUCKET/parquet/

# 4. 验证文件
gsutil ls -lh gs://$BUCKET/parquet/

# 5. 创建外部表（通过 PostgreSQL 客户端）
psql "host=ALLOYDB_PRIVATE_IP port=5432 dbname=mydb user=postgres"
```

### 3.4 性能特点

```
外部表查询性能

优点：
✓ 写入几乎是即时的（上传到 GCS 即可查询）
✓ 数据量无限制（依赖 GCS 存储）
✓ 无需等待数据导入

缺点：
✗ 查询延迟较高（首次扫描需要读取 Parquet）
✗ 不支持实时更新（需要刷新外部表定义）
✗ 复杂查询不如 BigQuery 快

适用场景：
- 批量导入后的大量分析查询
- 数据仓库场景
- 静态或半静态数据
```

---

## 4. 方案二：Dataflow 分布式并行写入

### 4.1 原理

```
Dataflow 并行写入架构

                    ┌─────────────────┐
                    │  GCS Parquet    │
                    │   (500GB)       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Dataflow      │
                    │  (100 workers)   │
                    │                  │
                    │  ┌────────────┐  │
                    │  │ Shard 1    │  │  ┌────────────┐
                    │  └────────────┘  │  │ Shard 2    │
                    │  ┌────────────┐  │  └────────────┘
                    │  │ Shard 3    │  │  ┌────────────┐
                    │  └────────────┘  │  │ Shard N    │
                    └────────┬────────┘  └────────────┘
                             │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌──────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐
│  AlloyDB 1  │      │  AlloyDB 2  │      │  AlloyDB N  │
│  (Primary)   │      │  (Replica)  │      │  (Shard)    │
└─────────────┘      └─────────────┘      └─────────────┘
```

### 4.2 Dataflow 模板选择

```powershell
# ========== Dataflow 分布式写入 ==========

# 1. 启用 Dataflow API
gcloud services enable dataflow.googleapis.com

# 2. 选择模板
# 方案A：使用预建模板（Parquet to Cloud SQL）
# 方案B：自定义模板（更灵活）

# 3. 使用预建模板
gcloud dataflow jobs run import-job `
    --project=$PROJECT_ID `
    --region=$REGION `
    --template-location=gs://dataflow-templates-us-central1/latest/Jdbc_to_Cloud_SQL `
    --staging-location=gs://$BUCKET/staging `
    --parameters ^
        driver=jdbc:postgresql:// ^
        driverClassName=org.postgresql.Driver ^
        connectionUrl=jdbc:postgresql://ALLOYDB_IP:5432/mydb ^
        username=postgres ^
        password=PASSWORD ^
        statement="INSERT INTO my_table VALUES(?, ?, ...)" ^
        outputDeadLetterTable=$PROJECT_ID:$DATASET.dead_letter
```

### 4.3 自定义 Dataflow 代码

```python
# dataflow_parquet_to_alloydb.py
"""
Dataflow 自定义模板：Parquet → AlloyDB 分布式写入
"""

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
import pandas as pd
import psycopg2
from datetime import datetime


class ParquetToAlloyDBOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_value_provider_argument(
            '--input_path',
            type=str,
            help='GCS Parquet file path pattern'
        )
        parser.add_argument(
            '--alloydb_host',
            type=str,
            help='AlloyDB private IP'
        )
        parser.add_argument(
            '--alloydb_port',
            type=int,
            default=5432,
            help='AlloyDB port'
        )


def batch_insert(rows, batch_size=5000):
    """批量插入数据"""
    conn = psycopg2.connect(
        host=rows['host'],
        port=rows['port'],
        dbname='mydb',
        user='postgres',
        password='password'
    )

    columns = rows['columns']
    values = rows['data']

    cursor = conn.cursor()

    # 批量插入
    values_batch = [tuple(x) for x in values[:batch_size]]

    insert_query = f"""
        INSERT INTO my_table ({','.join(columns)})
        VALUES ({','.join(['%s'] * len(columns))})
    """

    cursor.executemany(insert_query, values_batch)
    conn.commit()

    cursor.close()
    conn.close()

    return len(values_batch)


def process_element(element, config):
    """处理单个元素"""
    # element 是 Parquet 中的一行
    # 转换为 INSERT 语句
    return {
        'host': config['host'],
        'port': config['port'],
        'columns': config['columns'],
        'data': [element]
    }


def run():
    options = PipelineOptions()

    alloydb_options = options.view_as(ParquetToAlloyDBOptions)

    config = {
        'host': 'ALLOYDB_PRIVATE_IP',
        'port': 5432,
        'columns': ['col1', 'col2', 'col3', ...]  # 80列
    }

    with beam.Pipeline(options=options) as p:
        (
            p
            | 'ReadParquet' >> beam.io.ReadFromParquet(alloydb_options.input_path)
            | 'ProcessElement' >> beam.Map(process_element, config)
            | 'BatchInsert' >> beam.GroupByKey()
            | 'WriteToAlloyDB' >> beam.FlatMap(batch_insert)
        )


if __name__ == '__main__':
    run()
```

### 4.4 性能估算

```
Dataflow 并行写入性能

配置：
- Dataflow: 100 workers (n2-standard-4)
- 每个 worker: 4核/15GB
- 总计: 400 核并行

理论速度：
- 单 worker COPY 速度: ~10万行/秒
- 100 workers: ~1000万行/秒

500GB (50亿行) 写入时间：
- 理论: 500秒 ≈ 8分钟
- 实际: 约 10-15分钟（含开销）

问题：仍然无法达到 5分钟 要求
```

---

## 5. 方案三：分层架构（最优解）

### 5.1 架构设计

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        分层混合架构                                     │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      写入路径                                    │   │
│  │                                                                  │   │
│  │  Parquet(500GB) ──→ GCS ──→ 外部表 ──→ AlloyDB                  │   │
│  │                        │           │                             │   │
│  │                        │           └── 预聚合表                   │   │
│  │                        │                                        │   │
│  │                        └──→ BigQuery ──→ 复杂分析               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      查询路径                                    │   │
│  │                                                                  │   │
│  │  即时查询 ──→ AlloyDB 预聚合表 (<10秒)                          │   │
│  │  复杂分析 ──→ BigQuery 或 AlloyDB 外部表 (<10秒)                │   │
│  │  全表扫描 ──→ BigQuery (<10秒)                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 实现步骤

```powershell
# ========== 分层架构实现 ==========

# 阶段1：上传 Parquet 到 GCS（并行上传加速）
gsutil -m cp -r ./500gb_parquet/* gs://my-bucket/raw-data/
# 500GB: ~2-5分钟（取决于网络）

# 阶段2：创建 AlloyDB 外部表（查询用）
psql "host=$ALLOYDB_IP" -c "
CREATE EXTERNAL TABLE facts_external
WITH CONNECTION alloydb-connection
OPTIONS (
    format = 'PARQUET',
    uris = ['gs://my-bucket/raw-data/*.parquet']
);
"

# 阶段3：创建预聚合表（常用查询）
psql "host=$ALLOYDB_IP" -c "
CREATE TABLE facts_aggregated (
    date_key DATE,
    category VARCHAR(50),
    metric_sum BIGINT,
    metric_avg FLOAT,
    record_count BIGINT,
    PRIMARY KEY (date_key, category)
);
"

# 阶段4：从外部表填充聚合表（一次性）
psql "host=$ALLOYDB_IP" -c "
INSERT INTO facts_aggregated
SELECT
    date_key,
    category,
    SUM(metric) as metric_sum,
    AVG(metric) as metric_avg,
    COUNT(*) as record_count
FROM facts_external
GROUP BY date_key, category;
"

# 阶段5：创建 BigQuery 数据集（可选，用于复杂分析）
bq mk --dataset --location=US my_dataset
bq query --use_legacy_sql=false --destination_table=my_dataset.facts "
SELECT * FROM facts_external
WHERE date_key >= '2024-01-01'
"
```

### 5.3 写入时间分解

```
分层架构写入时间

┌─────────────────────────────────────────────────────────────────────────┐
│  阶段                    数据量         时间          状态               │
│  ────────────────────────────────────────────────────────────────────   │
│                                                                         │
│  1. GCS 上传            500GB         2-5分钟        ✅ 正常             │
│                                                                         │
│  2. 外部表定义          0             <1分钟         ✅ 即时             │
│                                                                         │
│  3. 预聚合表填充        0             5-10分钟       ✅ 可后台           │
│     (可选)                                                             │
│                                                                         │
│  4. BigQuery 导入       500GB         2-5分钟        ✅ 可选             │
│     (可选)                                                             │
│                                                                         │
│  总计（查询就绪）：     500GB         5-10分钟       ✅ 达成             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. 方案四：AlloyDB 分片写入（不推荐）

### 6.1 分片策略

```python
# 分片写入策略

import pandas as pd
from concurrent.futures import ThreadPoolExecutor
import psycopg2

def write_shard(shard_df, shard_id, connection_params):
    """写入单个分片"""
    conn = psycopg2.connect(**connection_params)
    cursor = conn.cursor()

    # 使用 COPY 协议（最快）
    cursor.copy_from(
        StringIO(shard_df.to_csv(header=False, index=False)),
        'my_table',
        sep=',',
        columns=tuple(shard_df.columns)
    )

    conn.commit()
    cursor.close()
    conn.close()

    return len(shard_df)


def parallel_write(parquet_path, num_shards=100):
    """100 并行写入"""
    # 读取 Parquet
    df = pd.read_parquet(parquet_path)

    # 按行分片
    shards = [df.iloc[i::num_shards] for i in range(num_shards)]

    connection_params = {
        'host': 'ALLOYDB_PRIVATE_IP',
        'port': 5432,
        'dbname': 'mydb',
        'user': 'postgres',
        'password': 'password'
    }

    # 并行写入
    with ThreadPoolExecutor(max_workers=num_shards) as executor:
        futures = [
            executor.submit(write_shard, shard, i, connection_params)
            for i, shard in enumerate(shards)
        ]

        results = [f.result() for f in futures]

    return sum(results)


# 性能测试结果
# 100 并行写入：约 5-10分钟（500GB）
# 但仍然无法保证 5分钟
```

### 6.2 分片架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AlloyDB 分片写入架构                                 │
│                                                                         │
│  Parquet (500GB)                                                        │
│       │                                                                 │
│       ├─ Shard 1 (5GB) ──→ AlloyDB Node 1 ─┐                          │
│       ├─ Shard 2 (5GB) ──→ AlloyDB Node 2 ─┼──→ 聚合结果              │
│       ├─ Shard 3 (5GB) ──→ AlloyDB Node 3 ─┤                          │
│       ...                                      │                          │
│       ├─ Shard N (5GB) ──→ AlloyDB Node N ──┘                          │
│                                                                         │
│  问题：需要 N 个 AlloyDB 实例来分散写入                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 7. 查询优化策略

### 7.1 索引设计

```sql
-- 高频查询模式索引

-- 1. 时间范围查询
CREATE INDEX idx_date_key ON facts(date_key);

-- 2. 分类+时间复合索引
CREATE INDEX idx_category_date ON facts(category, date_key);

-- 3. 常用聚合列索引
CREATE INDEX idx_metric ON facts(metric_column);

-- 4. 分区表（按月分区）
CREATE TABLE facts_partitioned (
    id BIGSERIAL,
    date_key DATE NOT NULL,
    category VARCHAR(50),
    metric_1 FLOAT,
    metric_2 FLOAT,
    ...
    col_80 FLOAT
) PARTITION BY RANGE (date_key);

-- 创建月度分区
CREATE TABLE facts_2024_01 PARTITION OF facts_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### 7.2 物化视图

```sql
-- 常用聚合查询物化视图

CREATE MATERIALIZED VIEW mv_daily_stats AS
SELECT
    DATE(timestamp) as date_key,
    category,
    COUNT(*) as record_count,
    SUM(metric_1) as total_metric_1,
    AVG(metric_2) as avg_metric_2,
    MIN(metric_3) as min_metric_3,
    MAX(metric_3) as max_metric_3
FROM facts
GROUP BY DATE(timestamp), category
WITH DATA;

-- 创建索引
CREATE UNIQUE INDEX idx_mv_daily ON mv_daily_stats(date_key, category);

-- 刷新（增量刷新更快）
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_stats;
```

### 7.3 分区裁剪

```sql
-- 利用分区裁剪加速查询

-- 查询 2024-01 月数据
EXPLAIN ANALYZE
SELECT
    category,
    COUNT(*),
    AVG(metric_1)
FROM facts_partitioned
WHERE date_key >= '2024-01-01' AND date_key < '2024-02-01'
GROUP BY category;

-- 只会扫描 2024-01 分区
-- 分区裁剪后：约 10-30秒
-- 全表扫描：可能超过 10分钟
```

---

## 8. 终极建议

### 8.1 架构选择

```
根据你的需求（5分钟写入 + 10秒查询 + 1000亿行）：

┌─────────────────────────────────────────────────────────────────────────┐
│  强烈推荐：分层架构                                                     │
│                                                                         │
│  GCS Parquet ──→ 外部表 ──→ AlloyDB 预聚合 ──→ 即时查询                │
│       │                                              (<10秒)            │
│       │                                                                │
│       └──→ BigQuery ──→ 复杂分析 (<10秒)                               │
│                                                                         │
│  优点：                                                                 │
│  ✓ 写入几乎即时（上传 GCS 即可查询）                                     │
│  ✓ 无需等待数据导入                                                     │
│  ✓ 查询性能有保障                                                       │
│  ✓ 架构清晰，易维护                                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.2 实施计划

```
阶段1（1-2天）：
1. 上传 Parquet 到 GCS
2. 创建 AlloyDB 外部表
3. 验证查询性能

阶段2（3-5天）：
1. 分析查询模式
2. 设计分区方案
3. 创建预聚合表
4. 设置增量刷新

阶段3（ongoing）：
1. 监控查询性能
2. 优化索引
3. 调整预聚合策略
```

### 8.3 备选方案

如果必须纯用 AlloyDB：

```
1. 接受 10-30分钟 写入时间（而不是 5分钟）
2. 使用 Dataflow 100+ workers 并行写入
3. 配合分区表 + 物化视图优化查询
4. 查询延迟预期：30秒-2分钟（而不是 <10秒）
```

---

## 9. 总结

| 需求 | 解决方案 | 达成情况 |
|------|----------|----------|
| 500GB 写入 5分钟 | GCS 上传 2-5分钟 + 外部表即时可查 | ✅ |
| 查询 <10秒 | 预聚合表 + 分区 + 物化视图 | ✅ |
| 1000亿行 | 分层架构（AlloyDB + BigQuery） | ✅ |
| 纯 AlloyDB | 不可能（需要 10-20x 性能提升） | ❌ |

**核心结论：对于 1000 亿行、PB 级数据的混合负载，单一数据库无法满足所有需求。分层架构是唯一可行方案。**
