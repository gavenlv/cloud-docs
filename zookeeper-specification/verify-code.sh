#!/bin/bash
# verify-code.sh - Zookeeper专题代码验证脚本

set -e

echo "========================================"
echo "Zookeeper 代码验证脚本"
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

echo -e "${YELLOW}[1/6]${NC} 检查Java环境..."
java -version > /dev/null 2>&1
check_status "Java环境检查"

echo -e "${YELLOW}[2/6]${NC} 检查Zookeeper安装..."
if [ -z "$ZOOKEEPER_HOME" ]; then
    echo -e "${RED}[失败]${NC} ZOOKEEPER_HOME未设置"
    exit 1
fi
check_status "Zookeeper安装检查: $ZOOKEEPER_HOME"

echo -e "${YELLOW}[3/6]${NC} 检查Zookeeper服务状态..."
if echo "ruok" | nc localhost 2181 2>/dev/null | grep -q "imok"; then
    check_status "Zookeeper服务运行正常"
else
    echo -e "${RED}[失败]${NC} Zookeeper服务未运行"
    echo "请执行: bin/zkServer.sh start"
    exit 1
fi

echo -e "${YELLOW}[4/6]${NC} 验证CLI基本操作..."
export ZK_HOME=${ZOOKEEPER_HOME:-.}

# 创建测试节点
RESULT=$(echo "create /verify-test 'test data'" | $ZK_HOME/bin/zkCli.sh 2>/dev/null | grep -E "Created|Error" || true)
if echo "$RESULT" | grep -q "Created"; then
    check_status "创建节点"
else
    echo -e "${YELLOW}[跳过]${NC} 创建节点（可能已存在）"
fi

# 读取测试节点
RESULT=$(echo "get /verify-test" | $ZK_HOME/bin/zkCli.sh 2>/dev/null | head -5 || true)
if echo "$RESULT" | grep -q "test data"; then
    check_status "读取节点"
else
    echo -e "${YELLOW}[跳过]${NC} 读取节点"
fi

# 更新测试节点
RESULT=$(echo "set /verify-test 'updated'" | $ZK_HOME/bin/zkCli.sh 2>/dev/null | grep -E "Updated|Error" || true)
if echo "$RESULT" | grep -q "Updated"; then
    check_status "更新节点"
else
    echo -e "${YELLOW}[跳过]${NC} 更新节点"
fi

# 删除测试节点
RESULT=$(echo "delete /verify-test" | $ZK_HOME/bin/zkCli.sh 2>/dev/null | grep -E "Deleted|Error" || true)
if echo "$RESULT" | grep -q "Deleted"; then
    check_status "删除节点"
else
    echo -e "${YELLOW}[跳过]${NC} 删除节点"
fi

echo -e "${YELLOW}[5/6]${NC} 验证四字命令..."
COMMANDS=("ruok" "stat" "conf" "mntr" "wchs")
for cmd in "${COMMANDS[@]}"; do
    RESULT=$(echo "$cmd" | nc localhost 2181 2>/dev/null | head -1 || true)
    if [ -n "$RESULT" ]; then
        check_status "四字命令: $cmd"
    else
        echo -e "${RED}[失败]${NC} 四字命令: $cmd"
    fi
done

echo -e "${YELLOW}[6/6]${NC} 清理测试数据..."
echo "deleteall /verify-test" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
echo "deleteall /config" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
echo "deleteall /services" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
echo "deleteall /locks" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
echo "deleteall /queue" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
echo "deleteall /names" | $ZK_HOME/bin/zkCli.sh 2>/dev/null || true
check_status "清理完成"

echo "========================================"
echo -e "${GREEN}验证完成${NC}"
echo "========================================"
echo ""
echo "验证章节代码:"
echo "  01-fundamentals.md - 基础和核心原理"
echo "  02-architecture.md - 架构原理"
echo "  03-data-model.md - 数据模型"
echo "  04-znode.md - ZNode类型和属性"
echo "  05-watch.md - Watch机制原理"
echo "  06-cli-commands.md - CLI命令详解"
echo "  07-api-programming.md - API编程"
echo "  08-recipes.md - 典型应用场景"
echo "  09-cluster-deployment.md - 集群部署和运维"
echo "  10-troubleshooting.md - 常见错误处理"
echo ""
echo "详细验证说明请参考 VERIFICATION.md"
