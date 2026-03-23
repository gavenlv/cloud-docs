# 列出表
bq ls my_dataset

# 查看表详情
bq show my_dataset.my_table

# 查看表schema
bq show --schema my_dataset.my_table

# 查看表分区信息
bq show --format=prettyjson my_dataset.my_table | grep -A 10 partitioning

# 查看表大小
bq query --use_legacy_sql=false "SELECT SUM(size_bytes) FROM my_dataset.__TABLES__ WHERE table_id='my_table'"