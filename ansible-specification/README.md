# Ansible专题

## 概述

本专题提供从基础到专家级的Ansible教程，涵盖Ansible的核心概念、Inventory管理、Playbook编写、模块使用、角色开发、变量管理、模板、Jinja2、条件循环、最佳实践和故障排除。

## 目录结构

```
ansible-specification/
├── README.md                              # 本文件
├── 01-fundamentals/                       # Ansible基础和核心原理
│   ├── 01-fundamentals.md
│   └── codes/
│       └── bash-01.sh ~ bash-04.sh
├── 02-inventory/                         # Inventory管理
│   ├── 02-inventory.md
│   └── codes/
│       ├── bash-01.sh ~ bash-04.sh
│       ├── ini-01.ini
│       └── yaml-01.yaml ~ yaml-03.yaml
├── 03-playbook/                          # Playbook编写
│   ├── 03-playbook.md
│   └── codes/
│       ├── bash-01.sh ~ bash-03.sh
│       └── yaml-01.yaml ~ yaml-08.yaml
├── 04-modules/                           # 模块使用
│   ├── 04-modules.md
│   └── codes/
│       ├── bash-01.sh ~ bash-03.sh
│       └── yaml-01.yaml ~ yaml-10.yaml
├── 05-roles/                             # 角色开发
│   ├── 05-roles.md
│   └── codes/
│       ├── bash-01.sh ~ bash-07.sh
│       └── yaml-01.yaml ~ yaml-13.yaml
├── 06-variables/                         # 变量管理
│   ├── 06-variables.md
│   └── codes/
│       ├── bash-01.sh ~ bash-04.sh
│       ├── ini-01.ini
│       └── yaml-01.yaml ~ yaml-18.yaml
├── 07-templates/                         # 模板和Jinja2
│   ├── 07-templates.md
│   └── codes/
│       ├── bash-01.sh ~ bash-02.sh
│       └── yaml-01.yaml
├── 08-conditionals-loops/                 # 条件和循环
│   ├── 08-conditionals-loops.md
│   └── codes/
│       ├── bash-01.sh ~ bash-03.sh
│       └── yaml-01.yaml ~ yaml-13.yaml
├── 09-best-practices/                    # Ansible最佳实践
│   ├── 09-best-practices.md
│   └── codes/
│       ├── bash-01.sh ~ bash-08.sh
│       └── yaml-01.yaml ~ yaml-10.yaml
├── 10-troubleshooting/                   # Ansible常见错误处理
│   ├── 10-troubleshooting.md
│   └── codes/
│       ├── bash-01.sh ~ bash-05.sh
│       └── yaml-01.yaml
├── VERIFICATION.md                        # 代码验证说明
└── VERIFICATION.md                        # 代码验证说明
```

## 快速开始

### 运行第一个Playbook

```bash
cd 03-playbook/codes
ansible-playbook yaml-01.yaml
```

### 测试Ansible连接

```bash
ansible all -m ping
ansible all -m command -a "uptime"
```

### 执行临时命令

```bash
ansible web -m apt -a "name=nginx state=present"
ansible web -m service -a "name=nginx state=started"
```

## 章节运行指南

### 01-fundamentals - Ansible基础

**运行命令：**
```bash
cd 01-fundamentals/codes
bash bash-01.sh
ansible all -m ping
```

### 02-inventory - Inventory管理

**运行命令：**
```bash
cd 02-inventory/codes
ansible all -i yaml-01.yaml -m ping
ansible-inventory -i ini-01.ini --list
```

### 03-playbook - Playbook编写

**运行命令：**
```bash
cd 03-playbook/codes
ansible-playbook yaml-01.yaml
ansible-playbook yaml-02.yaml --check
```

### 04-modules - 模块使用

**运行命令：**
```bash
cd 04-modules/codes
ansible localhost -m debug -a "msg=Hello"
ansible-doc -l | head -20
```

### 05-roles - 角色开发

**运行命令：**
```bash
cd 05-roles/codes
ansible-galaxy init myrole
ansible-playbook yaml-01.yaml
```

### 06-variables - 变量管理

**运行命令：**
```bash
cd 06-variables/codes
ansible-playbook yaml-01.yaml -e "myvar=value"
ansible-playbook yaml-02.yaml -e @vars.yaml
```

### 07-templates - 模板和Jinja2

**运行命令：**
```bash
cd 07-templates/codes
ansible-playbook yaml-01.yaml
```

### 08-conditionals-loops - 条件和循环

**运行命令：**
```bash
cd 08-conditionals-loops/codes
ansible-playbook yaml-01.yaml
```

### 09-best-practices - 最佳实践

**运行命令：**
```bash
cd 09-best-practices/codes
ansible-playbook yaml-01.yaml
```

### 10-troubleshooting - 故障排除

**运行命令：**
```bash
cd 10-troubleshooting/codes
ansible-playbook yaml-01.yaml -v
ansible-playbook yaml-01.yaml -vvv
```

## 代码提取统计

| 章节 | 代码类型 | 数量 |
|------|----------|------|
| 01-fundamentals | bash | 4 |
| 02-inventory | bash, ini, yaml | 8 |
| 03-playbook | bash, yaml | 11 |
| 04-modules | bash, yaml | 13 |
| 05-roles | bash, yaml | 20 |
| 06-variables | bash, ini, yaml | 23 |
| 07-templates | bash, yaml | 3 |
| 08-conditionals-loops | bash, yaml | 16 |
| 09-best-practices | bash, yaml | 18 |
| 10-troubleshooting | bash, yaml | 6 |

## 学习路径

### 初级路径

1. [01-fundamentals](./01-fundamentals/) - 掌握Ansible基础
2. [02-inventory](./02-inventory/) - 掌握Inventory管理
3. [03-playbook](./03-playbook/) - 掌握Playbook编写

### 中级路径

1. [04-modules](./04-modules/) - 掌握模块使用
2. [05-roles](./05-roles/) - 掌握角色开发
3. [06-variables](./06-variables/) - 掌握变量管理

### 高级路径

1. [07-templates](./07-templates/) - 掌握模板和Jinja2
2. [08-conditionals-loops](./08-conditionals-loops/) - 掌握条件和循环
3. [09-best-practices](./09-best-practices/) - 实施最佳实践
4. [10-troubleshooting](./10-troubleshooting/) - 掌握故障排除

## 前置要求

### 必备工具

- Ansible >= 2.10
- Python >= 3.8
- SSH

## 常见问题

### Q: Ansible连接失败？

A: 检查SSH密钥配置和主机连接：
```bash
ansible all -m ping -vvv
ssh -vvv user@host
```

### Q: Playbook执行失败？

A: 使用检查模式：`ansible-playbook playbook.yaml --check`

### Q: 变量未定义？

A: 检查变量优先级和作用域：
```bash
ansible-playbook playbook.yaml -e "variable=value"
```
