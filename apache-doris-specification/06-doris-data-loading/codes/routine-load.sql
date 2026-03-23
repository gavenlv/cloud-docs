-- Routine Load示例 - 从Kafka导入实时数据

-- 创建Kafka导入任务
CREATE ROUTINE LOAD example_db.kafka_load_001
ON target_table
COLUMNS TERMINATED BY ","
(
    user_id,
    username,
    email,
    age,
    create_time
)
FROM KAFKA
(
    "kafka_broker_list" = "broker1:9092,broker2:9092,broker3:9092",
    "kafka_topic" = "user_events",
    "kafka_partitions" = "0,1,2,3,4,5,6,7",
    "kafka_offsets" = "OFFSET_BEGINNING"
)
PROPERTIES
(
    "desired_concurrent_number" = "5",
    "max_filter_ratio" = "0.1",
    "timeout" = "3600",
    "strict_mode" = "true"
);

-- 创建带JSON格式的Kafka导入
CREATE ROUTINE LOAD example_db.kafka_json_load
ON target_table
COLUMNS (user_id, username, email, age, event_time)
FROM KAFKA
(
    "kafka_broker_list" = "broker1:9092,broker2:9092",
    "kafka_topic" = "user_events_json",
    "kafka_partitions" = "0,1,2",
    "kafka_offsets" = "OFFSET_BEGINNING",
    "property.kafka_default_offsets" = "OFFSET_BEGINNING"
)
PROPERTIES
(
    "format" = "json",
    "jsonpaths" = "[\"$.user_id\", \"$.username\", \"$.email\", \"$.age\", \"$.event_time\"]"
);

-- 从特定offset开始消费
CREATE ROUTINE LOAD example_db.kafka_from_offset
ON target_table
COLUMNS TERMINATED BY ","
FROM KAFKA
(
    "kafka_broker_list" = "broker1:9092",
    "kafka_topic" = "user_events",
    "kafka_partitions" = "0,1,2",
    "kafka_offsets" = "1000,1000,1000"
);

-- 管理Routine Load
PAUSE ROUTINE LOAD FOR example_db.kafka_load_001;
RESUME ROUTINE LOAD FOR example_db.kafka_load_001;
STOP ROUTINE LOAD FOR example_db.kafka_load_001;

-- 查看Routine Load状态
SHOW ROUTINE LOAD;
SHOW ROUTINE LOAD FOR example_db.kafka_load_001;
SHOW ROUTINE LOAD TASK FOR example_db.kafka_load_001;

-- 查看消费进度
SHOW ROUTINE LOAD TASK WHERE JobName = 'kafka_load_001';
