# Kubernetes Dashboard 一键部署脚本
# 用法: .\deploy-dashboard.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Kubernetes Dashboard 一键部署 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 kubectl 是否可用
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] kubectl 未安装或不在 PATH 中" -ForegroundColor Red
    exit 1
}

# 检查集群连接
try {
    kubectl cluster-info 2>&1 | Out-Null
} catch {
    Write-Host "[错误] 无法连接到 Kubernetes 集群" -ForegroundColor Red
    exit 1
}

# 1. 部署 Dashboard
Write-Host "[1/4] 部署 Dashboard..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 2. 创建管理员账号
Write-Host "[2/4] 创建管理员账号..." -ForegroundColor Yellow
$adminYaml = @"
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
"@

$adminYaml | kubectl apply -f -

# 3. 修改 Service 为 NodePort (永久外部访问)
Write-Host "[3/4] 配置 NodePort 外部访问..." -ForegroundColor Yellow
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec":{"type":"NodePort","ports":[{"port":443,"targetPort":8443,"nodePort":30443}]}}'

# 4. 等待 Pod 就绪
Write-Host "[4/4] 等待 Pod 就绪..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s 2>&1 | Out-Null

# 获取访问信息
Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "访问地址: https://localhost:30443" -ForegroundColor Cyan
Write-Host "或使用集群任意节点IP: https://<节点IP>:30443" -ForegroundColor Cyan
Write-Host ""

# 获取令牌
Write-Host "=== 登录令牌 (有效期1年) ===" -ForegroundColor Cyan
$token = kubectl create token admin-user -n kubernetes-dashboard --duration=87600h
Write-Host $token
Write-Host ""

# 保存令牌到文件
$tokenFile = "dashboard-token.txt"
$token | Out-File -FilePath $tokenFile -Encoding UTF8
Write-Host "令牌已保存到: $tokenFile" -ForegroundColor Green
Write-Host ""

Write-Host "提示: 令牌过期后重新运行以下命令获取新令牌:" -ForegroundColor Yellow
Write-Host "  kubectl create token admin-user -n kubernetes-dashboard --duration=87600h" -ForegroundColor White
