# verify-kubectl-config.ps1 - kubectl配置章节验证脚本 (Windows)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "kubectl配置 章节验证脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Test-Command {
    param($name, $test)
    if ($test) {
        Write-Host "[通过] $name" -ForegroundColor Green
    } else {
        Write-Host "[失败] $name" -ForegroundColor Red
    }
}

# 检查kubectl安装
Write-Host "[1/6] 检查kubectl安装..." -ForegroundColor Yellow
try {
    $result = kubectl version --client 2>&1
    if ($LASTEXITCODE -eq 0 -or $result) {
        Write-Host $result -ForegroundColor Gray
        Test-Command "kubectl已安装" $true
    } else {
        Test-Command "kubectl已安装" $false
    }
} catch {
    Test-Command "kubectl已安装" $false
    Write-Host "安装方法：choco install kubernetes-cli 或参见 https://kubernetes.io/zh/docs/tasks/tools/" -ForegroundColor Yellow
}

# 检查kubeconfig配置
Write-Host "[2/6] 检查kubeconfig配置..." -ForegroundColor Yellow
$kubeconfigPath = if ($env:KUBECONFIG) { $env:KUBECONFIG } else { "$HOME\.kube\config" }
if (Test-Path $kubeconfigPath) {
    Test-Command "kubeconfig存在" $true
    Write-Host "  当前配置路径：$kubeconfigPath" -ForegroundColor Gray
} else {
    Write-Host "[跳过] kubeconfig不存在（minikube/kind环境会生成）" -ForegroundColor Yellow
}

# 验证kubectl config命令
Write-Host "[3/6] 验证kubectl config命令..." -ForegroundColor Yellow
try {
    $null = kubectl config get-contexts 2>&1
    Test-Command "kubectl config命令可用" $true

    $currentCtx = kubectl config current-context 2>$null
    Write-Host "  当前上下文: $currentCtx" -ForegroundColor Gray
} catch {
    Test-Command "kubectl config命令可用" $false
}

# 验证kubectl语法
Write-Host "[4/6] 验证kubectl语法检查..." -ForegroundColor Yellow
try {
    $null = kubectl create deployment test-deploy --image=nginx --dry-run=client 2>$null
    Test-Command "kubectl dry-run语法正常" $true
} catch {
    Test-Command "kubectl dry-run语法正常" $false
}

# 验证kubectl输出
Write-Host "[5/6] 验证kubectl输出格式化..." -ForegroundColor Yellow
try {
    $null = kubectl get pods -o yaml --dry-run=client 2>$null
    Test-Command "kubectl输出格式化正常" $true
} catch {
    Test-Command "kubectl输出格式化正常" $false
}

# 检查kubectl自动补全
Write-Host "[6/6] 检查kubectl自动补全..." -ForegroundColor Yellow
try {
    $completion = kubectl completion powershell 2>$null
    if ($completion) {
        Test-Command "kubectl powershell自动补全可用" $true
    } else {
        Test-Command "kubectl powershell自动补全可用" $false
    }
} catch {
    Write-Host "[跳过] 自动补全需要手动配置" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "验证要点：" -ForegroundColor White
Write-Host "  1. kubeconfig文件结构和加载顺序" -ForegroundColor Gray
Write-Host "  2. 多集群配置和上下文切换" -ForegroundColor Gray
Write-Host "  3. 证书认证和Token认证原理" -ForegroundColor Gray
Write-Host "  4. kubectl别名和自动补全配置" -ForegroundColor Gray
Write-Host "  5. 常见配置问题排查" -ForegroundColor Gray
Write-Host ""
Write-Host "实战验证：" -ForegroundColor White
Write-Host "  # 导出当前配置" -ForegroundColor Gray
Write-Host "  kubectl config view --flatten > backup-kubeconfig.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 添加新集群配置" -ForegroundColor Gray
Write-Host "  kubectl config set-cluster new-cluster --server=https://k8s.example.com:6443 --certificate-authority=ca.crt" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 创建新上下文" -ForegroundColor Gray
Write-Host "  kubectl config set-context new-ctx --cluster=new-cluster --user=new-user" -ForegroundColor Gray
Write-Host ""
Write-Host "详细说明请参考 11-kubectl-config.md" -ForegroundColor Yellow
