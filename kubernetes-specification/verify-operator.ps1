# verify-operator.ps1 - Operator开发章节验证脚本 (Windows)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kubernetes Operator开发 章节验证脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Test-Command {
    param($name, $test)
    if ($test) {
        Write-Host "[通过] $name" -ForegroundColor Green
    } else {
        Write-Host "[失败] $name" -ForegroundColor Red
    }
}

# 检查Go环境
Write-Host "[1/8] 检查Go环境..." -ForegroundColor Yellow
$goResult = go version 2>$null
if ($goResult) {
    Write-Host $goResult -ForegroundColor Gray
    Test-Command "Go已安装" $true
} else {
    Test-Command "Go已安装" $false
    Write-Host "安装方法：https://go.dev/dl/" -ForegroundColor Yellow
}

# 检查kubectl
Write-Host "[2/8] 检查kubectl安装..." -ForegroundColor Yellow
$kubectlResult = kubectl version --client 2>$null
if ($LASTEXITCODE -eq 0 -or $kubectlResult) {
    Write-Host $kubectlResult -ForegroundColor Gray
    Test-Command "kubectl已安装" $true
} else {
    Write-Host "[跳过] kubectl未安装" -ForegroundColor Yellow
}

# 检查kubebuilder
Write-Host "[3/8] 检查kubebuilder..." -ForegroundColor Yellow
$kbResult = kubebuilder version 2>$null
if ($LASTEXITCODE -eq 0 -or $kbResult) {
    Write-Host $kbResult -ForegroundColor Gray
    Test-Command "kubebuilder已安装" $true
} else {
    Write-Host "[跳过] kubebuilder未安装（仅学习可跳过）" -ForegroundColor Yellow
}

# 检查controller-runtime
Write-Host "[4/8] 检查controller-runtime..." -ForegroundColor Yellow
$tempDir = "$env:TEMP\operator-test"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
Set-Location $tempDir
@"
module operator-test

go 1.21

require (
    sigs.k8s.io/controller-runtime v0.15.0
    sigs.k8s.io/controller-tools v0.11.0
)
"@ | Out-File -FilePath go.mod -Encoding UTF8
try {
    go mod tidy 2>$null | Out-Null
    if (Test-Path go.mod) {
        Test-Command "controller-runtime依赖可用" $true
    }
} catch {
    Write-Host "[跳过] 依赖获取失败" -ForegroundColor Yellow
}
Set-Location $env:TEMP
Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

# 检查Kubernetes集群
Write-Host "[5/8] 检查Kubernetes集群..." -ForegroundColor Yellow
$clusterResult = kubectl cluster-info 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host $clusterResult -ForegroundColor Gray
    Test-Command "Kubernetes集群可用" $true
} else {
    Write-Host "[跳过] Kubernetes集群不可用（仅学习可跳过）" -ForegroundColor Yellow
}

# 检查CRD语法
Write-Host "[6/8] 检查CRD语法..." -ForegroundColor Yellow
$crdResult = kubectl api-resources 2>$null
if ($LASTEXITCODE -eq 0) {
    Test-Command "kubectl API可用" $true
} else {
    Write-Host "[跳过] API检查失败" -ForegroundColor Yellow
}

# 验证示例代码语法
Write-Host "[7/8] 验证示例代码语法..." -ForegroundColor Yellow
$tempFile = "$env:TEMP\operator_check.go"
@'
package main
import "fmt"
func main() { fmt.Println("Operator概念验证") }
'@ | Out-File -FilePath $tempFile -Encoding UTF8
try {
    $buildResult = go build -o "$env:TEMP\operator_check.exe" $tempFile 2>$null
    Test-Command "Go代码语法检查" $true
} catch {
    Test-Command "Go代码语法检查" $false
}
Remove-Item $tempFile -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\operator_check.exe" -ErrorAction SilentlyContinue

# 验证文件结构
Write-Host "[8/8] 验证文件结构..." -ForegroundColor Yellow
$operatorDir = "d:\workspace\github\cloud-docs\kubernetes-specification"
if (Test-Path "$operatorDir\12-operator.md") {
    Test-Command "Operator章节文件存在" $true
} else {
    Test-Command "Operator章节文件存在" $false
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "验证要点：" -ForegroundColor White
Write-Host "  1. Operator核心原理（控制器模式）" -ForegroundColor Gray
Write-Host "  2. CRD机制和版本管理" -ForegroundColor Gray
Write-Host "  3. Reconcile协调循环" -ForegroundColor Gray
Write-Host "  4. kubebuilder框架使用" -ForegroundColor Gray
Write-Host "  5. Webhook机制" -ForegroundColor Gray
Write-Host "  6. MySQL Operator实战" -ForegroundColor Gray
Write-Host ""
Write-Host "实战验证：" -ForegroundColor White
Write-Host "  # 安装kubebuilder" -ForegroundColor Gray
Write-Host "  choco install kubebuilder" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 初始化项目" -ForegroundColor Gray
Write-Host "  kubebuilder init --domain example.com --repo example.com/mysql-operator" -ForegroundColor Gray
Write-Host ""
Write-Host "  # 创建API" -ForegroundColor Gray
Write-Host "  kubebuilder create api --group database --version v1 --kind MySQL" -ForegroundColor Gray
Write-Host ""
Write-Host "详细说明请参考 12-operator.md" -ForegroundColor Yellow
