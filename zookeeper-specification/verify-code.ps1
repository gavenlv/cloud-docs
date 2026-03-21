# verify-code.ps1 - Zookeeper专题代码验证脚本 (Windows)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Zookeeper 代码验证脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Test-Command {
    param($name, $test)
    if ($test) {
        Write-Host "[通过] $name" -ForegroundColor Green
    } else {
        Write-Host "[失败] $name" -ForegroundColor Red
    }
}

# 检查Java环境
Write-Host "[1/6] 检查Java环境..." -ForegroundColor Yellow
try {
    $null = java -version 2>&1
    Test-Command "Java环境检查" $true
} catch {
    Test-Command "Java环境检查" $false
}

# 检查Zookeeper安装
Write-Host "[2/6] 检查Zookeeper安装..." -ForegroundColor Yellow
if ($env:ZOOKEEPER_HOME) {
    Test-Command "Zookeeper安装检查: $env:ZOOKEEPER_HOME" $true
} else {
    Write-Host "[失败] ZOOKEEPER_HOME未设置" -ForegroundColor Red
    Write-Host "请执行: `$env:ZOOKEEPER_HOME='C:\path\to\zookeeper'" -ForegroundColor Yellow
    exit 1
}

# 检查Zookeeper服务状态
Write-Host "[3/6] 检查Zookeeper服务状态..." -ForegroundColor Yellow
try {
    $result = echo "ruok" | nc localhost 2181 2>$null
    if ($result -match "imok") {
        Test-Command "Zookeeper服务运行正常" $true
    } else {
        Test-Command "Zookeeper服务运行正常" $false
    }
} catch {
    Test-Command "Zookeeper服务运行正常" $false
}

# 验证CLI基本操作
Write-Host "[4/6] 验证CLI基本操作..." -ForegroundColor Yellow
$zkCli = "$env:ZOOKEEPER_HOME\bin\zkCli.cmd"

# 创建测试节点
try {
    $null = & $zkCli -cmd "create /verify-test 'test data'" 2>$null
    Test-Command "创建节点" $true
} catch {
    Test-Command "创建节点" $false
}

# 读取测试节点
try {
    $result = & $zkCli -cmd "get /verify-test" 2>$null | Select-Object -First 5
    if ($result -match "test data") {
        Test-Command "读取节点" $true
    } else {
        Test-Command "读取节点" $false
    }
} catch {
    Test-Command "读取节点" $false
}

# 更新测试节点
try {
    $null = & $zkCli -cmd "set /verify-test 'updated'" 2>$null
    Test-Command "更新节点" $true
} catch {
    Test-Command "更新节点" $false
}

# 删除测试节点
try {
    $null = & $zkCli -cmd "delete /verify-test" 2>$null
    Test-Command "删除节点" $true
} catch {
    Test-Command "删除节点" $false
}

# 验证四字命令
Write-Host "[5/6] 验证四字命令..." -ForegroundColor Yellow
$commands = @("ruok", "stat", "conf", "mntr", "wchs")
foreach ($cmd in $commands) {
    try {
        $result = echo $cmd | nc localhost 2181 2>$null | Select-Object -First 1
        if ($result) {
            Test-Command "四字命令: $cmd" $true
        } else {
            Test-Command "四字命令: $cmd" $false
        }
    } catch {
        Test-Command "四字命令: $cmd" $false
    }
}

# 清理测试数据
Write-Host "[6/6] 清理测试数据..." -ForegroundColor Yellow
$cleanupPaths = @("/verify-test", "/config", "/services", "/locks", "/queue", "/names")
foreach ($path in $cleanupPaths) {
    try {
        $null = & $zkCli -cmd "deleteall $path" 2>$null
    } catch {
        # 忽略错误
    }
}
Test-Command "清理完成" $true

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "验证章节代码:" -ForegroundColor White
Write-Host "  01-fundamentals.md - 基础和核心原理" -ForegroundColor Gray
Write-Host "  02-architecture.md - 架构原理" -ForegroundColor Gray
Write-Host "  03-data-model.md - 数据模型" -ForegroundColor Gray
Write-Host "  04-znode.md - ZNode类型和属性" -ForegroundColor Gray
Write-Host "  05-watch.md - Watch机制原理" -ForegroundColor Gray
Write-Host "  06-cli-commands.md - CLI命令详解" -ForegroundColor Gray
Write-Host "  07-api-programming.md - API编程" -ForegroundColor Gray
Write-Host "  08-recipes.md - 典型应用场景" -ForegroundColor Gray
Write-Host "  09-cluster-deployment.md - 集群部署和运维" -ForegroundColor Gray
Write-Host "  10-troubleshooting.md - 常见错误处理" -ForegroundColor Gray
Write-Host ""
Write-Host "详细验证说明请参考 VERIFICATION.md" -ForegroundColor Yellow
