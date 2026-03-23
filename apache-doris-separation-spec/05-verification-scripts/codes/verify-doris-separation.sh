#!/bin/bash

set -e

FE_HOST=${FE_HOST:-127.0.0.1}
FE_PORT=${FE_PORT:-9030}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASS=${MYSQL_PASS:-""}

echo "=========================================="
echo "Doris 存算分离验证脚本"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓]${NC} $2"
    else
        echo -e "${RED}[✗]${NC} $2"
        exit 1
    fi
}

echo "1. 检查FE连接..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SELECT 1" > /dev/null 2>&1
check_result $? "FE服务可连接"

echo "2. 检查FE集群状态..."
FE_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW FRONTENDS;" 2>/dev/null | grep -c "Alive")
echo "   FE节点数量: $FE_COUNT"

echo "3. 检查计算节点状态..."
BE_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW BACKENDS;" 2>/dev/null | grep -c "Alive")
echo "   计算节点数量: $BE_COUNT"

echo "4. 创建测试数据库..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS test_verification;" 2>/dev/null
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE test_verification;" 2>/dev/null
check_result $? "测试数据库创建成功"

echo "5. 创建测试表..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "
CREATE TABLE IF NOT EXISTS test_table (
    id BIGINT NOT NULL,
    name VARCHAR(100),
    value DOUBLE,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 3
PROPERTIES ('storage_medium' = 'SSD');
" 2>/dev/null
check_result $? "测试表创建成功"

echo "6. 插入测试数据..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "
INSERT INTO test_table (id, name, value) VALUES
(1, 'test1', 100.5),
(2, 'test2', 200.5),
(3, 'test3', 300.5);
" 2>/dev/null
check_result $? "测试数据插入成功"

echo "7. 查询测试数据..."
DATA_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "SELECT COUNT(*) as cnt FROM test_table;" 2>/dev/null | tail -1)
if [ "$DATA_COUNT" -eq 3 ]; then
    echo -e "${GREEN}[✓]${NC} 数据查询成功，记录数: $DATA_COUNT"
else
    echo -e "${RED}[✗]${NC} 数据查询失败，记录数: $DATA_COUNT"
fi

echo "8. 清理测试数据..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS test_verification;" 2>/dev/null
check_result $? "测试数据清理成功"

echo ""
echo "=========================================="
echo -e "${GREEN}验证完成！${NC}"
echo "=========================================="
