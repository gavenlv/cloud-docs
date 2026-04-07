#!/bin/bash
set -e

echo "=========================================="
echo "PostgreSQL Operator 快速部署脚本"
echo "=========================================="

echo ""
echo "[1/6] 检查 kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "错误: kubectl 未安装"
    exit 1
fi
echo "kubectl 版本: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

echo ""
echo "[2/6] 检查 Go..."
if ! command -v go &> /dev/null; then
    echo "错误: Go 未安装"
    exit 1
fi
echo "Go 版本: $(go version)"

echo ""
echo "[3/6] 下载依赖..."
go mod tidy || true

echo ""
echo "[4/6] 安装 CRD..."
kubectl apply -f config/crd/bases

echo ""
echo "[5/6] 创建 RBAC..."
kubectl apply -f config/rbac

echo ""
echo "[6/6] 启动 Operator (本地模式)..."
echo ""
echo "=========================================="
echo "Operator 启动中..."
echo "按 Ctrl+C 停止"
echo "=========================================="
echo ""

go run ./main.go
