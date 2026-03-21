#!/bin/bash
# verify-kubectl-config.sh - kubectl配置章节验证脚本

set -e

echo "========================================"
echo "kubectl配置 章节验证脚本"
echo "========================================"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[通过]${NC} $1"
    else
        echo -e "${RED}[失败]${NC} $1"
    fi
}

echo -e "${YELLOW}[1/6]${NC} 检查kubectl安装..."
if kubectl version --client > /dev/null 2>&1; then
    kubectl version --client --short
    check_status "kubectl已安装"
else
    echo -e "${RED}[失败]${NC} kubectl未安装"
    echo "安装方法：brew install kubectl 或参见 https://kubernetes.io/zh/docs/tasks/tools/"
    exit 1
fi

echo -e "${YELLOW}[2/6]${NC} 检查kubeconfig配置..."
if [ -f "$HOME/.kube/config" ] || [ -n "$KUBECONFIG" ]; then
    check_status "kubeconfig存在"
    echo "当前配置路径：${KUBECONFIG:-$HOME/.kube/config}"
else
    echo -e "${YELLOW}[跳过]${NC} kubeconfig不存在（minikube/kind环境会生成）"
fi

echo -e "${YELLOW}[3/6]${NC} 验证kubectl配置命令..."
# 验证kubectl config命令可用
kubectl config get-contexts > /dev/null 2>&1
check_status "kubectl config命令可用"

# 验证当前上下文
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "none")
echo "  当前上下文: ${CURRENT_CTX}"

echo -e "${YELLOW}[4/6]${NC} 验证kubectl语法检查..."
# 验证--dry-run语法
kubectl create deployment test-deploy --image=nginx --dry-run=client > /dev/null 2>&1
check_status "kubectl dry-run语法正常"

echo -e "${YELLOW}[5/6]${NC} 验证kubectl输出格式化..."
# 验证输出格式
kubectl get pods -o yaml --dry-run=client > /dev/null 2>&1
check_status "kubectl输出格式化正常"

echo -e "${YELLOW}[6/6]${NC} 检查kubectl自动补全..."
if source <(kubectl completion bash 2>/dev/null); then
    check_status "kubectl bash自动补全可用"
else
    echo -e "${YELLOW}[跳过]${NC} 自动补全需要手动配置"
fi

echo ""
echo "========================================"
echo -e "${GREEN}验证完成${NC}"
echo "========================================"
echo ""
echo "验证要点："
echo "  1. kubeconfig文件结构和加载顺序"
echo "  2. 多集群配置和上下文切换"
echo "  3. 证书认证和Token认证原理"
echo "  4. kubectl别名和自动补全配置"
echo "  5. 常见配置问题排查"
echo ""
echo "实战验证："
echo "  # 导出当前配置"
echo "  kubectl config view --flatten > backup-kubeconfig.yaml"
echo ""
echo "  # 添加新集群配置"
echo "  kubectl config set-cluster new-cluster --server=https://k8s.example.com:6443 --certificate-authority=ca.crt"
echo ""
echo "  # 创建新上下文"
echo "  kubectl config set-context new-ctx --cluster=new-cluster --user=new-user"
echo ""
echo "详细说明请参考 11-kubectl-config.md"
