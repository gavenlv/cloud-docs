# 网络专题代码验证说明

## 概述

本文档说明如何验证网络专题中的代码示例。

## 验证方式

### 方式一：使用验证脚本（推荐）

每个章节都有独立的验证脚本，位于network-specification目录下：

```bash
# 进入专题目录
cd network-specification

# 给脚本添加执行权限
chmod +x verify-*.sh

# 运行验证脚本
./verify-network.sh
```

### 方式二：手动验证

每个代码示例都可以单独复制到Linux终端执行。

## 验证内容

### 第一章：网络基础和协议栈

- 网络接口配置命令
- 路由表查看
- tcpdump抓包
- traceroute路由追踪

### 第二章：TCP/IP协议详解

- TCP连接状态
- ss命令
- TCP参数查看

### 第三章：路由原理

- 路由表配置
- 策略路由
- NAT配置

### 第四章：DNS原理

- dig/nslookup查询
- DNS缓存

### 第五章：网络安全

- TLS/SSL连接测试
- 端口扫描
- 防火墙规则

### 第六章：防火墙和iptables

- iptables规则
- NAT配置
- firewalld命令

### 第七章：VPN和隧道技术

- WireGuard配置
- GRE隧道配置

### 第八章：网络监控和诊断

- ping/traceroute
- tcpdump抓包
- ss/netstat命令
- iperf3带宽测试

### 第九章：常见错误处理

- 诊断脚本
- 连接监控脚本

## 注意事项

1. 部分命令需要root权限，使用`sudo`执行
2. 防火墙操作需注意规则顺序
3. 建议在测试环境或虚拟机中运行验证
4. VPN配置需要公网服务器

## 预期输出

验证成功的输出示例：

```
=== 验证第一章: 网络基础和协议栈 ===
[PASS] ip addr show
[PASS] ip route show
[PASS] tcpdump -h
...
=== 验证完成 ===
总测试: 15, 通过: 15, 失败: 0
```

## 故障排除

如果验证失败：

1. 检查命令是否存在
2. 检查权限是否足够
3. 查看错误输出信息
4. 确认系统环境（Linux发行版）