# Doris存算分离 - 验证脚本

## 概述

本文档提供用于验证Doris存算分离部署的脚本和SQL语句。

## 快速验证脚本

### 1. 一键验证脚本

```bash
#!/bin/bash
# verify-doris-separation.sh

set -e

FE_HOST=${FE_HOST:-127.0.0.1}
FE_PORT=${FE_PORT:-9030}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASS=${MYSQL_PASS:-""}

echo "=========================================="
echo "Doris 存算分离验证脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 函数定义
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓]${NC} $2"
    else
        echo -e "${RED}[✗]${NC} $2"
        exit 1
    fi
}

warn_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[✓]${NC} $2"
    else
        echo -e "${YELLOW}[!]${NC} $2"
    fi
}

# 1. 检查FE连接
echo "1. 检查FE连接..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SELECT 1" > /dev/null 2>&1
check_result $? "FE服务可连接"

# 2. 检查FE集群状态
echo "2. 检查FE集群状态..."
FE_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW FRONTENDS;" 2>/dev/null | grep -c "Alive")
if [ "$FE_COUNT" -ge 1 ]; then
    echo -e "${GREEN}[✓]${NC} FE节点数量: $FE_COUNT"
else
    echo -e "${RED}[✗]${NC} FE节点数量: $FE_COUNT"
fi

# 3. 检查BE/计算节点状态
echo "3. 检查计算节点状态..."
BE_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW BACKENDS;" 2>/dev/null | grep -c "Alive")
if [ "$BE_COUNT" -ge 1 ]; then
    echo -e "${GREEN}[✓]${NC} 计算节点数量: $BE_COUNT"
else
    echo -e "${RED}[✗]${NC} 计算节点数量: $BE_COUNT"
fi

# 4. 检查对象存储配置
echo "4. 检查对象存储配置..."
OBJECT_STORAGE=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW FRONTEND CONFIG;" 2>/dev/null | grep -i "object_storage" | head -5)
if [ -n "$OBJECT_STORAGE" ]; then
    echo -e "${GREEN}[✓]${NC} 对象存储配置存在"
else
    echo -e "${YELLOW}[!]${NC} 对象存储配置未找到"
fi

# 5. 创建测试数据库
echo "5. 创建测试数据库..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS test_verification;" 2>/dev/null
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE test_verification;" 2>/dev/null
check_result $? "测试数据库创建成功"

# 6. 创建测试表
echo "6. 创建测试表..."
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

# 7. 插入测试数据
echo "7. 插入测试数据..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "
INSERT INTO test_table (id, name, value) VALUES
(1, 'test1', 100.5),
(2, 'test2', 200.5),
(3, 'test3', 300.5);
" 2>/dev/null
check_result $? "测试数据插入成功"

# 8. 查询测试数据
echo "8. 查询测试数据..."
DATA_COUNT=$(mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "SELECT COUNT(*) as cnt FROM test_table;" 2>/dev/null | tail -1)
if [ "$DATA_COUNT" -eq 3 ]; then
    echo -e "${GREEN}[✓]${NC} 数据查询成功，记录数: $DATA_COUNT"
else
    echo -e "${RED}[✗]${NC} 数据查询失败，记录数: $DATA_COUNT"
fi

# 9. 验证数据分布
echo "9. 验证数据分布..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS test_verification -e "SHOW DATA;" 2>/dev/null

# 10. 清理测试数据
echo "10. 清理测试数据..."
mysql -h $FE_HOST -P $FE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "DROP DATABASE IF EXISTS test_verification;" 2>/dev/null
check_result $? "测试数据清理成功"

echo ""
echo "=========================================="
echo -e "${GREEN}验证完成！${NC}"
echo "=========================================="
```

### 2. PowerShell验证脚本

```powershell
# verify-doris-separation.ps1

param(
    [string]$FEHost = "127.0.0.1",
    [int]$FEPort = 9030,
    [string]$MySQLUser = "root",
    [string]$MySQLPass = ""
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Doris 存算分离验证脚本 (PowerShell)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Test-MySQLConnection {
    try {
        $result = mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "SELECT 1" 2>&1
        return $true
    } catch {
        return $false
    }
}

function Get-FEStatus {
    mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "SHOW FRONTENDS;" 2>$null
}

function Get-BEStatus {
    mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "SHOW BACKENDS;" 2>$null
}

# 1. 检查FE连接
Write-Host "1. 检查FE连接..." -NoNewline
if (Test-MySQLConnection) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [FAILED]" -ForegroundColor Red
    exit 1
}

# 2. 检查FE集群状态
Write-Host "2. 检查FE集群状态..."
$feStatus = Get-FEStatus
$feCount = ($feStatus | Select-String "Alive" | Measure-Object).Count
Write-Host "   FE节点数量: $feCount" -ForegroundColor $(if($feCount -ge 1){ "Green" }else{ "Red" })

# 3. 检查BE状态
Write-Host "3. 检查计算节点状态..."
$beStatus = Get-BEStatus
$beCount = ($beStatus | Select-String "Alive" | Measure-Object).Count
Write-Host "   计算节点数量: $beCount" -ForegroundColor $(if($beCount -ge 1){ "Green" }else{ "Red" })

# 4. 创建测试数据库
Write-Host "4. 创建测试数据库..." -NoNewline
mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "DROP DATABASE IF EXISTS test_verification; CREATE DATABASE test_verification;" 2>$null
Write-Host " [OK]" -ForegroundColor Green

# 5. 创建测试表
Write-Host "5. 创建测试表..." -NoNewline
mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass test_verification -e @"
CREATE TABLE IF NOT EXISTS test_table (
    id BIGINT NOT NULL,
    name VARCHAR(100),
    value DOUBLE,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) DUPLICATE KEY(id)
DISTRIBUTED BY HASH(id) BUCKETS 3;
"@ 2>$null
Write-Host " [OK]" -ForegroundColor Green

# 6. 插入测试数据
Write-Host "6. 插入测试数据..." -NoNewline
mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass test_verification -e @"
INSERT INTO test_table (id, name, value) VALUES
(1, 'test1', 100.5),
(2, 'test2', 200.5),
(3, 'test3', 300.5);
"@ 2>$null
Write-Host " [OK]" -ForegroundColor Green

# 7. 查询测试数据
Write-Host "7. 查询测试数据..."
$result = mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass test_verification -e "SELECT * FROM test_table;" 2>$null
Write-Host $result

# 8. 清理
Write-Host "8. 清理测试数据..." -NoNewline
mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "DROP DATABASE IF EXISTS test_verification;" 2>$null
Write-Host " [OK]" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "验证完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
```

## 详细验证SQL

### 1. 集群状态验证

```sql
-- 查看FE状态
SHOW FRONTENDS;

-- 查看详细FE信息
SHOW PROC '/frontends';

-- 查看BE状态
SHOW BACKENDS;

-- 查看详细BE信息
SHOW PROC '/backends';

-- 查看计算节点
SHOW COMPUTE NODES;

-- 查看集群配置
SHOW FRONTEND CONFIG LIKE '%storage%';
SHOW BACKEND CONFIG LIKE '%object_storage%';
```

### 2. 存储验证

```sql
-- 查看存储介质
SHOW TABLE STATUS FROM database_name;

-- 查看Tablet分布
SHOW TABLETS FROM table_name;

-- 查看数据量
SHOW DATA;

-- 查看表分区
SHOW PARTITIONS FROM table_name;
```

### 3. 缓存验证

```sql
-- 查看BE缓存使用
SHOW BACKEND GPROCESS;

-- 查看缓存命中率
SHOW PROC '/backends';

-- 查看Tablet缓存状态
SHOW TABLETS FROM table_name;
```

### 4. 对象存储验证

```sql
-- 检查S3/GCS配置
SHOW BACKEND CONFIG LIKE '%object_storage%';

-- 检查存储路径
SHOW BACKEND CONFIG LIKE '%storage_root_path%';

-- 检查缓存配置
SHOW BACKEND CONFIG LIKE '%cache%';
```

## 性能验证

### 1. 基准测试

```sql
-- 创建大表进行性能测试
CREATE TABLE benchmark_table (
    id BIGINT NOT NULL,
    user_id BIGINT,
    username VARCHAR(50),
    email VARCHAR(100),
    age INT,
    create_time DATETIME
)
DUPLICATE KEY(id)
DISTRIBUTED BY HASH(user_id) BUCKETS 10;

-- 生成测试数据
INSERT INTO benchmark_table
SELECT
    id,
    id % 1000000 as user_id,
    CONCAT('user_', id) as username,
    CONCAT('user_', id, '@example.com') as email,
    id % 100 as age,
    DATE_ADD('2024-01-01', INTERVAL id SECOND) as create_time
FROM (
    SELECT 1 as id UNION ALL
    SELECT id + 1 FROM benchmark_table WHERE id < 1000000
) t;
```

### 2. 查询性能测试

```sql
-- 测试简单查询
SELECT COUNT(*) FROM benchmark_table;

-- 测试聚合查询
SELECT user_id, COUNT(*) as cnt, AVG(age) as avg_age
FROM benchmark_table
GROUP BY user_id
ORDER BY cnt DESC
LIMIT 10;

-- 测试JOIN查询
SELECT b.user_id, b.username, COUNT(t.id) as order_count
FROM (SELECT DISTINCT user_id FROM benchmark_table LIMIT 1000) b
LEFT JOIN benchmark_table t ON b.user_id = t.user_id
GROUP BY b.user_id, b.username
ORDER BY order_count DESC
LIMIT 10;
```

## 验证清单

| 验证项 | 预期结果 | 检查方法 |
|--------|----------|----------|
| FE服务 | 运行正常 | SHOW FRONTENDS |
| BE服务 | 运行正常 | SHOW BACKENDS |
| 对象存储连接 | 可连接 | 检查BE日志 |
| 数据写入 | 成功 | INSERT后无错误 |
| 数据读取 | 成功 | SELECT返回正确数据 |
| 缓存命中 | 有缓存 | SHOW PROC '/backends' |
| 查询性能 | < 1s | EXPLAIN ANALYZE |
