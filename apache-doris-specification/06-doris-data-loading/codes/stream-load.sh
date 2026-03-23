#!/bin/bash

# Stream Load示例脚本

# 配置参数
FE_HOST=${FE_HOST:-127.0.0.1}
FE_HTTP_PORT=${FE_HTTP_PORT:-8030}
DB_NAME=${DB_NAME:-example_db}
TABLE_NAME=${TABLE_NAME:-test_table}
USERNAME=${USERNAME:-root}
PASSWORD=${PASSWORD:-}

# 数据文件
DATA_FILE=${1:-data.csv}

# 列分隔符
COLUMN_SEPARATOR=${COLUMN_SEPARATOR:-","}

# Label前缀
LABEL_PREFIX=${LABEL_PREFIX:-"stream_load_"}

# 生成Label
LABEL="${LABEL_PREFIX}$(date +%Y%m%d_%H%M%S)"

echo "Starting Stream Load..."
echo "Label: $LABEL"
echo "Data File: $DATA_FILE"
echo "Target: $DB_NAME.$TABLE_NAME"

# 执行Stream Load
if [ -z "$PASSWORD" ]; then
    CURL_CMD="curl --location-trusted -u ${USERNAME}"
else
    CURL_CMD="curl --location-trusted -u ${USERNAME}:${PASSWORD}"
fi

$CURL_CMD \
    -T $DATA_FILE \
    -H "column_separator:," \
    -H "columns: user_id, username, email, age" \
    -H "label:$LABEL" \
    -H "max_filter_ratio:0.1" \
    http://${FE_HOST}:${FE_HTTP_PORT}/api/${DB_NAME}/${TABLE_NAME}/_stream_load

echo ""
echo "Stream Load completed"

# 查看导入状态
echo ""
echo "Checking load status..."
$CURL_CMD "http://${FE_HOST}:${FE_HTTP_PORT}/api/${DB_NAME}/get_load_state?label=$LABEL"
