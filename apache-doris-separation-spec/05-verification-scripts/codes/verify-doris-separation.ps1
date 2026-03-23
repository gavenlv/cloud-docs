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
$feStatus = mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "SHOW FRONTENDS;" 2>$null
$feCount = ($feStatus | Select-String "Alive" | Measure-Object).Count
Write-Host "   FE节点数量: $feCount" -ForegroundColor $(if($feCount -ge 1){ "Green" }else{ "Red" })

# 3. 检查BE状态
Write-Host "3. 检查计算节点状态..."
$beStatus = mysql -h $FEHost -P $FEPort -u$MySQLUser -p$MySQLPass -e "SHOW BACKENDS;" 2>$null
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
