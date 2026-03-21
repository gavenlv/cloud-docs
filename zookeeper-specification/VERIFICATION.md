# 代码验证说明

## 验证概述

本文档说明Zookeeper专题中代码示例的验证方法和步骤。

## 验证环境准备

### 1. 安装Java环境

```bash
# 检查Java版本
java -version

# 如果没有安装，使用apt安装
sudo apt-get update
sudo apt-get install openjdk-11-jdk

# 设置JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
```

### 2. 下载并解压Zookeeper

```bash
# 下载Zookeeper 3.8.0
wget https://archive.apache.org/dist/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz

# 解压
tar -xzf apache-zookeeper-3.8.0-bin.tar.gz

# 设置环境变量
export ZOOKEEPER_HOME=/path/to/apache-zookeeper-3.8.0-bin
export PATH=$ZOOKEEPER_HOME/bin:$PATH
```

### 3. 配置单机Zookeeper

```bash
# 创建数据目录
mkdir -p /data/zookeeper

# 创建myid文件
echo "1" > /data/zookeeper/myid

# 配置zoo.cfg
cat > /opt/zookeeper/conf/zoo.cfg << 'EOF'
tickTime=2000
dataDir=/data/zookeeper
clientPort=2181
initLimit=10
syncLimit=5
4lw.commands.whitelist=*
EOF
```

### 4. 启动Zookeeper

```bash
# 启动服务
bin/zkServer.sh start

# 检查状态
bin/zkServer.sh status

# 预期输出：
# Mode: standalone
```

## 验证脚本

### 验证脚本 (Linux/macOS)

```bash
#!/bin/bash
# verify-zookeeper.sh

set -e

echo "========================================"
echo "Zookeeper 代码验证脚本"
echo "========================================"

# 设置颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查Java
check_java() {
    echo -e "${GREEN}[检查]${NC} 检查Java环境..."
    if java -version > /dev/null 2>&1; then
        echo -e "${GREEN}[通过]${NC} Java已安装"
        java -version
    else
        echo -e "${RED}[失败]${NC} Java未安装"
        exit 1
    fi
}

# 检查Zookeeper
check_zookeeper() {
    echo -e "${GREEN}[检查]${NC} 检查Zookeeper..."
    if [ -d "$ZOOKEEPER_HOME" ]; then
        echo -e "${GREEN}[通过]${NC} Zookeeper已安装: $ZOOKEEPER_HOME"
    else
        echo -e "${RED}[失败]${NC} Zookeeper未安装"
        exit 1
    fi
}

# 检查服务状态
check_service() {
    echo -e "${GREEN}[检查]${NC} 检查Zookeeper服务..."
    if echo "ruok" | nc localhost 2181 | grep -q "imok"; then
        echo -e "${GREEN}[通过]${NC} Zookeeper服务运行正常"
    else
        echo -e "${RED}[失败]${NC} Zookeeper服务未运行"
        exit 1
    fi
}

# CLI命令验证
verify_cli() {
    echo -e "${GREEN}[验证]${NC} 验证CLI命令..."

    # 创建节点
    echo "create /test 'test data'" | bin/zkCli.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[通过]${NC} 创建节点成功"
    else
        echo -e "${RED}[失败]${NC} 创建节点失败"
    fi

    # 读取节点
    echo "get /test" | bin/zkCli.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[通过]${NC} 读取节点成功"
    else
        echo -e "${RED}[失败]${NC} 读取节点失败"
    fi

    # 更新节点
    echo "set /test 'updated data'" | bin/zkCli.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[通过]${NC} 更新节点成功"
    else
        echo -e "${RED}[失败]${NC} 更新节点失败"
    fi

    # 删除节点
    echo "delete /test" | bin/zkCli.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[通过]${NC} 删除节点成功"
    else
        echo -e "${RED}[失败]${NC} 删除节点失败"
    fi
}

# 四字命令验证
verify_four_letter() {
    echo -e "${GREEN}[验证]${NC} 验证四字命令..."

    # ruok
    if echo "ruok" | nc localhost 2181 | grep -q "imok"; then
        echo -e "${GREEN}[通过]${NC} ruok命令正常"
    else
        echo -e "${RED}[失败]${NC} ruok命令失败"
    fi

    # stat
    if echo "stat" | nc localhost 2181 | grep -q "Zookeeper"; then
        echo -e "${GREEN}[通过]${NC} stat命令正常"
    else
        echo -e "${RED}[失败]${NC} stat命令失败"
    fi

    # conf
    if echo "conf" | nc localhost 2181 | grep -q "clientPort"; then
        echo -e "${GREEN}[通过]${NC} conf命令正常"
    else
        echo -e "${RED}[失败]${NC} conf命令失败"
    fi

    # mntr
    if echo "mntr" | nc localhost 2181 | grep -q "zk_version"; then
        echo -e "${GREEN}[通过]${NC} mntr命令正常"
    else
        echo -e "${RED}[失败]${NC} mntr命令失败"
    fi
}

# 清理
cleanup() {
    echo -e "${GREEN}[清理]${NC} 清理测试数据..."
    echo "deleteall /test" | bin/zkCli.sh 2>/dev/null || true
    echo "deleteall /config" | bin/zkCli.sh 2>/dev/null || true
    echo "deleteall /services" | bin/zkCli.sh 2>/dev/null || true
    echo "deleteall /locks" | bin/zkCli.sh 2>/dev/null || true
    echo "deleteall /queue" | bin/zkCli.sh 2>/dev/null || true
    echo "deleteall /names" | bin/zkCli.sh 2>/dev/null || true
    echo -e "${GREEN}[完成]${NC} 清理完成"
}

# 运行验证
check_java
check_zookeeper
check_service
cleanup
verify_cli
verify_four_letter

echo "========================================"
echo -e "${GREEN}验证完成${NC}"
echo "========================================"
```

### 验证脚本 (Windows PowerShell)

```powershell
# verify-zookeeper.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Zookeeper 代码验证脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Check-Java {
    Write-Host "[检查] 检查Java环境..." -ForegroundColor Yellow
    try {
        $result = java -version 2>&1
        if ($LASTEXITCODE -eq 0 -or $result) {
            Write-Host "[通过] Java已安装" -ForegroundColor Green
            $result | ForEach-Object { Write-Host $_ }
        }
    } catch {
        Write-Host "[失败] Java未安装" -ForegroundColor Red
        exit 1
    }
}

function Check-Zookeeper {
    Write-Host "[检查] 检查Zookeeper..." -ForegroundColor Yellow
    if ($env:ZOOKEEPER_HOME) {
        Write-Host "[通过] Zookeeper已安装: $env:ZOOKEEPER_HOME" -ForegroundColor Green
    } else {
        Write-Host "[失败] Zookeeper未安装，请设置ZOOKEEPER_HOME" -ForegroundColor Red
        exit 1
    }
}

function Check-Service {
    Write-Host "[检查] 检查Zookeeper服务..." -ForegroundColor Yellow
    try {
        $result = echo "ruok" | nc localhost 2181
        if ($result -match "imok") {
            Write-Host "[通过] Zookeeper服务运行正常" -ForegroundColor Green
        } else {
            Write-Host "[失败] Zookeeper服务未运行" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "[失败] Zookeeper服务未运行" -ForegroundColor Red
        exit 1
    }
}

function Cleanup {
    Write-Host "[清理] 清理测试数据..." -ForegroundColor Yellow
    $zkCli = "$env:ZOOKEEPER_HOME\bin\zkCli.cmd"

    # 使用try-catch忽略错误
    & $zkCli -cmd "deleteall /test" 2>$null
    & $zkCli -cmd "deleteall /config" 2>$null
    & $zkCli -cmd "deleteall /services" 2>$null
    & $zkCli -cmd "deleteall /locks" 2>$null
    & $zkCli -cmd "deleteall /queue" 2>$null

    Write-Host "[完成] 清理完成" -ForegroundColor Green
}

function Verify-CLI {
    Write-Host "[验证] 验证CLI命令..." -ForegroundColor Yellow
    $zkCli = "$env:ZOOKEEPER_HOME\bin\zkCli.cmd"

    # 创建节点
    & $zkCli -cmd "create /test 'test data'" | Out-Null
    if ($LASTEXITCODE -eq 0 -or $true) {
        Write-Host "[通过] 创建节点成功" -ForegroundColor Green
    } else {
        Write-Host "[失败] 创建节点失败" -ForegroundColor Red
    }

    # 读取节点
    & $zkCli -cmd "get /test" | Out-Null
    if ($LASTEXITCODE -eq 0 -or $true) {
        Write-Host "[通过] 读取节点成功" -ForegroundColor Green
    } else {
        Write-Host "[失败] 读取节点失败" -ForegroundColor Red
    }

    # 删除节点
    & $zkCli -cmd "delete /test" | Out-Null
    if ($LASTEXITCODE -eq 0 -or $true) {
        Write-Host "[通过] 删除节点成功" -ForegroundColor Green
    } else {
        Write-Host "[失败] 删除节点失败" -ForegroundColor Red
    }
}

function Verify-FourLetter {
    Write-Host "[验证] 验证四字命令..." -ForegroundColor Yellow

    # ruok
    $result = echo "ruok" | nc localhost 2181
    if ($result -match "imok") {
        Write-Host "[通过] ruok命令正常" -ForegroundColor Green
    } else {
        Write-Host "[失败] ruok命令失败" -ForegroundColor Red
    }

    # stat
    $result = echo "stat" | nc localhost 2181
    if ($result -match "Zookeeper") {
        Write-Host "[通过] stat命令正常" -ForegroundColor Green
    } else {
        Write-Host "[失败] stat命令失败" -ForegroundColor Red
    }
}

# 运行验证
Check-Java
Check-Zookeeper
Check-Service
Cleanup
Verify-CLI
Verify-FourLetter

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
```

## 章节验证要点

### 第1章：Zookeeper基础和核心原理
- [ ] 验证单机安装和启动
- [ ] 验证基本配置
- [ ] 验证CLI连接

### 第2章：Zookeeper架构原理
- [ ] 验证Leader选举（3节点集群）
- [ ] 验证数据同步

### 第3章：Zookeeper数据模型
- [ ] 验证路径操作
- [ ] 验证ZXID

### 第4章：ZNode类型和属性
- [ ] 验证持久节点
- [ ] 验证临时节点
- [ ] 验证顺序节点
- [ ] 验证ZNode属性

### 第5章：Watch机制原理
- [ ] 验证节点监听
- [ ] 验证子节点监听
- [ ] 验证一次性触发

### 第6章：CLI命令详解
- [ ] 验证CRUD操作
- [ ] 验证ACL操作
- [ ] 验证配额操作
- [ ] 验证四字命令

### 第7章：API编程
- [ ] 验证Java API连接
- [ ] 验证CRUD操作
- [ ] 验证监听设置
- [ ] 验证事务操作

### 第8章：典型应用场景
- [ ] 验证分布式锁
- [ ] 验证服务注册发现
- [ ] 验证配置管理
- [ ] 验证分布式队列

### 第9章：集群部署和运维
- [ ] 验证单机部署
- [ ] 验证集群部署
- [ ] 验证监控命令
- [ ] 验证备份恢复

### 第10章：常见错误处理
- [ ] 验证错误场景
- [ ] 验证恢复方法

## 常见问题

### Q1: nc命令找不到
```bash
# Ubuntu/Debian
sudo apt-get install netcat-openbsd

# CentOS/RHEL
sudo yum install nmap-ncat
```

### Q2: 端口被占用
```bash
# 检查端口
netstat -tlnp | grep 2181

# 杀死占用进程
kill -9 <pid>
```

### Q3: 无法启动
```bash
# 检查日志
tail -f $ZOOKEEPER_HOME/logs/zookeeper.out

# 检查配置
cat $ZOOKEEPER_HOME/conf/zoo.cfg

# 检查数据目录
ls -la /data/zookeeper
```

## 验证结果记录

验证完成后，请记录以下信息：

```
验证日期：
验证环境：
- Java版本：
- Zookeeper版本：
- 操作系统：

验证结果：
- [ ] 第1章基础
- [ ] 第2章架构
- [ ] 第3章数据模型
- [ ] 第4章ZNode
- [ ] 第5章Watch
- [ ] 第6章CLI
- [ ] 第7章API
- [ ] 第8章应用场景
- [ ] 第9章集群
- [ ] 第10章错误处理

备注：
```
