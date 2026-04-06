#!/bin/bash
# Kubernetes Dashboard 一键部署脚本
# 用法: ./deploy-dashboard.sh

set -e

echo "=== Kubernetes Dashboard 一键部署 ==="
echo ""

# 检查 kubectl 是否可用
if ! command -v kubectl &> /dev/null; then
    echo "[错误] kubectl 未安装或不在 PATH 中"
    exit 1
fi

# 检查集群连接
if ! kubectl cluster-info &> /dev/null; then
    echo "[错误] 无法连接到 Kubernetes 集群"
    exit 1
fi

# 1. 部署 Dashboard
echo "[1/4] 部署 Dashboard..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 2. 创建管理员账号
echo "[2/4] 创建管理员账号..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 3. 修改 Service 为 NodePort
echo "[3/4] 配置 NodePort 外部访问..."
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8443,"nodePort":30443}]}}'

# 4. 等待 Pod 就绪
echo "[4/4] 等待 Pod 就绪..."
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

echo ""
echo "=== 部署完成 ==="
echo ""
echo "访问地址: https://localhost:30443"
echo "或使用集群任意节点IP: https://<节点IP>:30443"
echo ""

# 获取令牌
echo "=== 登录令牌 (有效期1年) ==="
TOKEN=$(kubectl create token admin-user -n kubernetes-dashboard --duration=87600h)
echo "$TOKEN"
echo ""

# 保存令牌到文件
echo "$TOKEN" > dashboard-token.txt
echo "令牌已保存到: dashboard-token.txt"
echo ""

echo "提示: 令牌过期后重新运行以下命令获取新令牌:"
echo "  kubectl create token admin-user -n kubernetes-dashboard --duration=87600h"
