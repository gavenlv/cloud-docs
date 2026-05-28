# Pinot 批量数据摄入

## 概述

本文档介绍 Apache Pinot 的批量数据摄入方式，包括本地文件、HDFS、S3、GCS 等数据源的摄入方法。

---

## 1. 批量摄入架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 批量摄入架构                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │ 数据源   │────>│ 数据处理 │────>│ Segment  │────>│  Pinot   │      │
│  │          │     │          │     │  生成    │     │  Server  │      │
│  └──────────┘     └──────────┘     └──────────┘     └──────────┘      │
│                                                                          │
│  数据源：                                                                │
│  ├── 本地文件（CSV、JSON、Parquet、Avro、ORC）                          │
│  ├── HDFS                                                                │
│  ├── S3 / GCS / Azure Blob                                               │
│  └── 数据库（通过 Spark/Flink）                                          │
│                                                                          │
│  处理方式：                                                              │
│  ├── Standalone（单机处理）                                              │
│  ├── MapReduce（Hadoop）                                                 │
│  ├── Spark（推荐）                                                       │
│  └── Flink                                                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 单机批量摄入

### 2.1 使用 Pinot Admin 工具

```bash
# 1. 准备数据文件（CSV 格式）
cat > events.csv << 'EOF'
user_id,event_type,timestamp,revenue
user1,click,1704067200000,0
user2,purchase,1704067260000,100.50
user3,click,1704067320000,0
EOF

# 2. 创建 Schema
cat > events_schema.json << 'EOF'
{
  "schemaName": "events",
  "dimensionFieldSpecs": [
    {"name": "user_id", "dataType": "STRING"},
    {"name": "event_type", "dataType": "STRING"}
  ],
  "metricFieldSpecs": [
    {"name": "revenue", "dataType": "DOUBLE"}
  ],
  "dateTimeFieldSpecs": [
    {
      "name": "timestamp",
      "dataType": "LONG",
      "format": "1:MILLISECONDS:EPOCH",
      "granularity": "1:HOURS"
    }
  ]
}
EOF

# 3. 创建 Table Config
cat > events_table.json << 'EOF'
{
  "tableName": "events",
  "tableType": "OFFLINE",
  "segmentsConfig": {
    "timeColumnName": "timestamp",
    "replication": "1"
  },
  "tableIndexConfig": {
    "loadMode": "MMAP"
  }
}
EOF

# 4. 生成 Segment
bin/pinot-admin.sh CreateSegment \
  -schemaFile events_schema.json \
  -tableConfigFile events_table.json \
  -dataDir /path/to/data \
  -format CSV \
  -outDir /path/to/output

# 5. 上传 Segment
bin/pinot-admin.sh UploadSegment \
  -controllerUri http://localhost:9000 \
  -segmentDir /path/to/output
```

### 2.2 使用 Ingestion Job

```yaml
# ingestion-job-spec.yaml
executionFrameworkSpec:
  name: 'standalone'
  segmentGenerationJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentGenerationJobRunner'
  segmentTarPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentTarPushJobRunner'
  segmentUriPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentUriPushJobRunner'

jobType: SegmentCreationAndTarPush
inputDirURI: 'file:///path/to/input'
includeFileNamePattern: 'glob:**/*.csv'
outputDirURI: 'file:///path/to/output'
overwriteOutput: true

pinotFSSpecs:
  - scheme: file
    className: org.apache.pinot.spi.filesystem.LocalPinotFS

recordReaderSpec:
  dataFormat: 'csv'
  className: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReader'
  configClassName: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReaderConfig'

tableSpec:
  tableName: 'events'
  schemaURI: 'http://localhost:9000/schemas/events'
  tableConfigURI: 'http://localhost:9000/tables/events'

pinotClusterSpecs:
  - controllerURI: 'http://localhost:9000'
```

```bash
# 执行摄入任务
bin/pinot-admin.sh LaunchDataIngestionJob \
  -jobSpecFile ingestion-job-spec.yaml
```

---

## 3. Spark 批量摄入

### 3.1 Spark 作业配置

```yaml
# spark-ingestion-job-spec.yaml
executionFrameworkSpec:
  name: 'spark'
  segmentGenerationJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.spark.SparkSegmentGenerationJobRunner'
  segmentTarPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.spark.SparkSegmentTarPushJobRunner'
  segmentUriPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.spark.SparkSegmentUriPushJobRunner'

jobType: SegmentCreationAndTarPush
inputDirURI: 's3a://my-bucket/input/'
includeFileNamePattern: 'glob:**/*.parquet'
outputDirURI: 's3a://my-bucket/output/'
overwriteOutput: true

pinotFSSpecs:
  - scheme: s3a
    className: org.apache.pinot.plugin.filesystem.S3PinotFS
    configs:
      region: us-west-2

recordReaderSpec:
  dataFormat: 'parquet'
  className: 'org.apache.pinot.plugin.inputformat.parquet.ParquetRecordReader'

tableSpec:
  tableName: 'events'
  schemaURI: 'http://pinot-controller:9000/schemas/events'
  tableConfigURI: 'http://pinot-controller:9000/tables/events'

pinotClusterSpecs:
  - controllerURI: 'http://pinot-controller:9000'
```

### 3.2 提交 Spark 作业

```bash
# 使用 spark-submit 提交
spark-submit \
  --class org.apache.pinot.plugin.ingestion.batch.spark.SparkSegmentGenerationJobRunner \
  --master yarn \
  --deploy-mode cluster \
  --conf spark.executor.memory=8g \
  --conf spark.executor.cores=4 \
  --conf spark.executor.instances=10 \
  --conf spark.driver.memory=4g \
  --files events_schema.json,events_table.json \
  pinot-batch-ingestion-spark-*.jar \
  -jobSpecFile spark-ingestion-job-spec.yaml
```

---

## 4. 云存储摄入

### 4.1 S3 摄入

```yaml
# s3-ingestion-job-spec.yaml
executionFrameworkSpec:
  name: 'standalone'
  segmentGenerationJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentGenerationJobRunner'
  segmentTarPushJobRunnerClassName: 'org.apache.pinot.plugin.ingestion.batch.standalone.SegmentTarPushJobRunner'

jobType: SegmentCreationAndTarPush
inputDirURI: 's3://my-bucket/input/'
includeFileNamePattern: 'glob:**/*.parquet'
outputDirURI: 's3://my-bucket/output/'
overwriteOutput: true

pinotFSSpecs:
  - scheme: s3
    className: org.apache.pinot.plugin.filesystem.S3PinotFS
    configs:
      region: us-west-2
      accessKey: ${AWS_ACCESS_KEY_ID}
      secretKey: ${AWS_SECRET_ACCESS_KEY}

recordReaderSpec:
  dataFormat: 'parquet'
  className: 'org.apache.pinot.plugin.inputformat.parquet.ParquetRecordReader'

tableSpec:
  tableName: 'events'
  schemaURI: 'http://pinot-controller:9000/schemas/events'
  tableConfigURI: 'http://pinot-controller:9000/tables/events'

pinotClusterSpecs:
  - controllerURI: 'http://pinot-controller:9000'
```

### 4.2 GCS 摄入

```yaml
# gcs-ingestion-job-spec.yaml
pinotFSSpecs:
  - scheme: gs
    className: org.apache.pinot.plugin.filesystem.GcsPinotFS
    configs:
      projectId: my-project
      gcpKey: /path/to/service-account-key.json

inputDirURI: 'gs://my-bucket/input/'
outputDirURI: 'gs://my-bucket/output/'
```

### 4.3 Azure Blob 摄入

```yaml
# azure-ingestion-job-spec.yaml
pinotFSSpecs:
  - scheme: abfs
    className: org.apache.pinot.plugin.filesystem.AzurePinotFS
    configs:
      accountName: mystorageaccount
      accountKey: ${AZURE_STORAGE_KEY}

inputDirURI: 'abfs://container@mystorageaccount.dfs.core.windows.net/input/'
outputDirURI: 'abfs://container@mystorageaccount.dfs.core.windows.net/output/'
```

---

## 5. 数据格式支持

### 5.1 支持的格式

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Pinot 支持的数据格式                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  格式              │  类名                                              │
│  ──────────────────┼────────────────────────────────────────────────────│
│  CSV               │  org.apache.pinot.plugin.inputformat.csv.          │
│                    │    CSVRecordReader                                 │
│  JSON              │  org.apache.pinot.plugin.inputformat.json.         │
│                    │    JSONRecordReader                                │
│  Avro              │  org.apache.pinot.plugin.inputformat.avro.         │
│                    │    AvroRecordReader                                │
│  Parquet           │  org.apache.pinot.plugin.inputformat.parquet.      │
│                    │    ParquetRecordReader                             │
│  ORC               │  org.apache.pinot.plugin.inputformat.orc.          │
│                    │    ORCRecordReader                                 │
│  Thrift            │  org.apache.pinot.plugin.inputformat.thrift.       │
│                    │    ThriftRecordReader                              │
│  Protobuf          │  org.apache.pinot.plugin.inputformat.protobuf.     │
│                    │    ProtoBufRecordReader                            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5.2 CSV 配置示例

```yaml
recordReaderSpec:
  dataFormat: 'csv'
  className: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReader'
  configClassName: 'org.apache.pinot.plugin.inputformat.csv.CSVRecordReaderConfig'
  configs:
    header: 'user_id,event_type,timestamp,revenue'
    delimiter: ','
    quoteCharacter: '"'
    escapeCharacter: '\\'
```

### 5.3 JSON 配置示例

```yaml
recordReaderSpec:
  dataFormat: 'json'
  className: 'org.apache.pinot.plugin.inputformat.json.JSONRecordReader'
  configs:
    dateFormat: 'timestamp'
    jsonPath: '$.data'
```

### 5.4 Parquet 配置示例

```yaml
recordReaderSpec:
  dataFormat: 'parquet'
  className: 'org.apache.pinot.plugin.inputformat.parquet.ParquetRecordReader'
  configs:
    useLogicalTypes: 'true'
```

---

## 6. 数据转换

### 6.1 内置转换函数

```json
{
  "transformConfigs": [
    {
      "columnName": "timestamp",
      "transformFunction": "toEpochSeconds(event_time) * 1000"
    },
    {
      "columnName": "year",
      "transformFunction": "year(timestamp)"
    },
    {
      "columnName": "month",
      "transformFunction": "month(timestamp)"
    },
    {
      "columnName": "day_of_week",
      "transformFunction": "dayOfWeek(timestamp)"
    },
    {
      "columnName": "full_name",
      "transformFunction": "concat(first_name, ' ', last_name)"
    },
    {
      "columnName": "is_premium",
      "transformFunction": "case when revenue > 1000 then 1 else 0 end"
    },
    {
      "columnName": "json_properties",
      "transformFunction": "jsonFormat(properties)"
    }
  ]
}
```

### 6.2 复杂转换示例

```json
{
  "transformConfigs": [
    {
      "columnName": "user_bucket",
      "transformFunction": "mod(hash(user_id), 100)"
    },
    {
      "columnName": "event_hour",
      "transformFunction": "toDateTime(timestamp, 'yyyy-MM-dd HH')"
    },
    {
      "columnName": "device_category",
      "transformFunction": "case when device_type in ('iphone', 'ipad', 'android') then 'mobile' when device_type in ('mac', 'windows', 'linux') then 'desktop' else 'other' end"
    },
    {
      "columnName": "revenue_category",
      "transformFunction": "case when revenue < 50 then 'low' when revenue < 200 then 'medium' else 'high' end"
    }
  ]
}
```

---

## 7. 调度任务

### 7.1 Minion 任务调度

```json
{
  "task": {
    "taskTypeConfigsMap": {
      "SegmentGenerationAndPushTask": {
        "schedule": "0 0 * * * ?",
        "tableMaxNumTasks": "10"
      }
    }
  }
}
```

### 7.2 Airflow 集成

```python
# airflow_pinot_dag.py
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'pinot_batch_ingestion',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False,
)

generate_segment = BashOperator(
    task_id='generate_segment',
    bash_command='''
        /opt/pinot/bin/pinot-admin.sh LaunchDataIngestionJob \
            -jobSpecFile /opt/pinot/jobs/daily-ingestion.yaml
    ''',
    dag=dag,
)
```

---

## 参考链接

- [Pinot Batch Ingestion](https://docs.pinot.apache.org/basics/data-import/batch-ingestion)
- [Pinot Spark Integration](https://docs.pinot.apache.org/basics/data-import/batch-ingestion/spark)
- [Pinot Hadoop Integration](https://docs.pinot.apache.org/basics/data-import/batch-ingestion/hadoop)
