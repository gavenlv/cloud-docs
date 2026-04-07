# PostgreSQL Operator 快速部署脚本 (Windows)

Write-Host "=========================================="
Write-Host "PostgreSQL Operator 快速部署脚本"
Write-Host "=========================================="

Write-Host ""
Write-Host "[1/6] 检查 kubectl..."
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "错误: kubectl 未安装"
    exit 1
}
kubectl version --client

Write-Host ""
Write-Host "[2/6] 检查 Go..."
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Host "错误: Go 未安装"
    exit 1
}
go version

Write-Host ""
Write-Host "[3/6] 下载依赖..."
go mod tidy

Write-Host ""
Write-Host "[4/6] 安装 CRD..."
kubectl apply -f config/crd/bases

Write-Host ""
Write-Host "[5/6] 创建 RBAC..."
kubectl apply -f config/rbac

Write-Host ""
Write-Host "[6/6] 启动 Operator (本地模式)..."
Write-Host ""
Write-Host "=========================================="
Write-Host "Operator 启动中..."
Write-Host "按 Ctrl+C 停止"
Write-Host "=========================================="
Write-Host ""

go run ./main.go
