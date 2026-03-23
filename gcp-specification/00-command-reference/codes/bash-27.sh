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