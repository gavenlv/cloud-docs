# Linux专题

## 概述

本专题提供从基础到专家级的Linux教程，涵盖Linux基础、文件系统、进程管理、网络管理、用户权限、包和服务管理、日志监控、Shell脚本和故障排除。

## 目录结构

```
linux-specification/
├── README.md                              # 本文件
├── 01-linux-fundamentals/                 # Linux基础
│   ├── 01-linux-fundamentals.md
│   └── codes/
│       └── bash-01.sh ~ bash-17.sh
├── 02-file-system/                       # 文件系统
│   ├── 02-file-system.md
│   └── codes/
│       └── bash-01.sh ~ bash-17.sh
├── 03-process-management/                 # 进程管理
│   ├── 03-process-management.md
│   └── codes/
│       └── bash-01.sh ~ bash-20.sh
├── 04-network-management/                 # 网络管理
│   ├── 04-network-management.md
│   └── codes/
│       └── bash-01.sh ~ bash-18.sh
├── 05-user-permission/                   # 用户和权限
│   ├── 05-user-permission.md
│   └── codes/
│       └── bash-01.sh ~ bash-17.sh
├── 06-package-service/                    # 包和服务管理
│   ├── 06-package-service.md
│   └── codes/
│       └── bash-01.sh ~ bash-18.sh
├── 07-logging-monitoring/                 # 日志和监控
│   ├── 07-logging-monitoring.md
│   └── codes/
│       └── bash-01.sh ~ bash-10.sh
├── 08-shell-scripting/                   # Shell脚本
│   ├── 08-shell-scripting.md
│   └── codes/
│       └── bash-01.sh ~ bash-17.sh
├── 09-troubleshooting/                   # 故障排除
│   ├── 09-troubleshooting.md
│   └── codes/
│       └── bash-01.sh ~ bash-14.sh
├── VERIFICATION.md                        # 代码验证说明
├── verify-linux.ps1                       # Windows验证脚本
└── verify-linux.sh                        # Linux/macOS验证脚本
```

## 快速开始

### 查看系统信息

```bash
uname -a
cat /etc/os-release
```

### 文件系统操作

```bash
ls -la /
cd /home
pwd
```

### 进程管理

```bash
ps aux | head -10
top
```

## 章节运行指南

### 01-linux-fundamentals - Linux基础

**运行命令：**
```bash
cd 01-linux-fundamentals/codes
bash bash-01.sh
bash bash-02.sh
```

### 02-file-system - 文件系统

**运行命令：**
```bash
cd 02-file-system/codes
bash bash-01.sh
bash bash-02.sh
```

### 03-process-management - 进程管理

**运行命令：**
```bash
cd 03-process-management/codes
bash bash-01.sh
bash bash-02.sh
```

### 04-network-management - 网络管理

**运行命令：**
```bash
cd 04-network-management/codes
bash bash-01.sh
bash bash-02.sh
```

### 05-user-permission - 用户和权限

**运行命令：**
```bash
cd 05-user-permission/codes
bash bash-01.sh
bash bash-02.sh
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-linux-fundamentals | bash | 17 |
| 02-file-system | bash | 17 |
| 03-process-management | bash | 20 |
| 04-network-management | bash | 18 |
| 05-user-permission | bash | 17 |
| 06-package-service | bash | 18 |
| 07-logging-monitoring | bash | 10 |
| 08-shell-scripting | bash | 17 |
| 09-troubleshooting | bash | 14 |

## 学习路径

### 初级路径

1. [01-linux-fundamentals](./01-linux-fundamentals/) - 掌握Linux基础
2. [02-file-system](./02-file-system/) - 掌握文件系统操作
3. [03-process-management](./03-process-management/) - 掌握进程管理

### 中级路径

1. [04-network-management](./04-network-management/) - 掌握网络配置
2. [05-user-permission](./05-user-permission/) - 掌握用户权限
3. [06-package-service](./06-package-service/) - 掌握包和服务管理

### 高级路径

1. [07-logging-monitoring](./07-logging-monitoring/) - 掌握日志监控
2. [08-shell-scripting](./08-shell-scripting/) - 掌握Shell脚本
3. [09-troubleshooting](./09-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Linux系统或WSL
- Bash shell >= 4.0

## 常见问题

### Q: 权限不足？

A: 使用`sudo`提升权限：
```bash
sudo command
```

### Q: 命令未找到？

A: 检查PATH或使用完整路径：
```bash
echo $PATH
which command
```
