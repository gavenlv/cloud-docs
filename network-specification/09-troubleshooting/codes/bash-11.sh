#!/bin/bash
# 网络诊断脚本

echo "=== 网络诊断报告 ==="
echo "时间: $(date)"
echo ""

echo "--- IP配置 ---"
ip addr show
echo ""

echo "--- 路由表 ---"
ip route show
echo ""

echo "--- DNS配置 ---"
cat /etc/resolv.conf
echo ""

echo "--- 网络连接 ---"
ss -tuln | head -20
echo ""

echo "--- 网关连通性 ---"
ping -c 3 8.8.8.8 2>&1 | tail -2
echo ""

echo "--- DNS解析 ---"
nslookup google.com 2>&1 | tail -5