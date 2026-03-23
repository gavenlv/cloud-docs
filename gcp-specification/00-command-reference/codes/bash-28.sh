# 简单查询
bq query "SELECT * FROM my_dataset.my_table LIMIT 10"

# 标准SQL查询
bq query --use_legacy_sql=false "SELECT COUNT(*) FROM my_dataset.my_table"

# 查询带参数
bq query --use_legacy_sql=false --parameter=value "SELECT * FROM my_dataset.my_table WHERE id = @id"

# 查询并格式化输出
bq query --format=prettyjson "SELECT * FROM my_dataset.my_table LIMIT 1"