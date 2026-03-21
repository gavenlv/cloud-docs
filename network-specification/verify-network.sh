#!/bin/bash
# 网络专题代码验证脚本

set -e

echo "============================================"
echo "网络专题代码验证"
echo "============================================"
echo ""

PASS=0
FAIL=0

test_command() {
    local name="$1"
    local cmd="$2"

    echo -n "[$name] ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS"
        ((PASS++))
    else
        echo "FAIL"
        ((FAIL++))
    fi
}

test_output() {
    local name="$1"
    local cmd="$2"
    local expected="$3"

    echo -n "[$name] ... "
    output=$(eval "$cmd" 2>&1)
    if echo "$output" | grep -q "$expected"; then
        echo "PASS"
        ((PASS++))
    else
        echo "FAIL (expected: $expected)"
        ((FAIL++))
    fi
}

echo "=== 第一章: 网络基础和协议栈 ==="
test_command "ip_addr" "ip addr show"
test_command "ip_route" "ip route show"
test_command "ip_link" "ip link show"
test_command "ss" "ss -V 2>&1 | head -1"
test_command "tcpdump" "tcpdump --version 2>&1 | head -1"
echo ""

echo "=== 第二章: TCP/IP协议详解 ==="
test_command "ss_tan" "ss -tan | head -3"
test_command "ss_estab" "ss -tan state established | head -3"
test_command "cat_tcp" "cat /proc/sys/net/ipv4/tcp_congestion_control"
test_command "netstat" "netstat -h 2>&1 | head -1"
echo ""

echo "=== 第三章: 路由原理 ==="
test_command "ip_route_show" "ip route show"
test_command "ip_rule" "ip rule show"
test_command "ip_route_get" "ip route get 8.8.8.8"
test_command "traceroute" "traceroute -h 2>&1 | head -1"
echo ""

echo "=== 第四章: DNS原理 ==="
test_command "dig" "dig -v 2>&1 | head -1"
test_command "nslookup" "nslookup -version 2>&1 | head -1"
test_command "host" "host -V 2>&1 | head -1"
test_command "cat_resolv" "cat /etc/resolv.conf | head -3"
echo ""

echo "=== 第五章: 网络安全 ==="
test_command "openssl" "openssl version"
test_command "nmap" "nmap --version 2>&1 | head -3"
test_command "openssl_s_client" "openssl s_client -help 2>&1 | head -1"
test_command "ssh" "ssh -V 2>&1 | head -1"
echo ""

echo "=== 第六章: 防火墙和iptables ==="
test_command "iptables" "iptables -L -n | head -5"
test_command "iptables_nat" "iptables -t nat -L -n | head -5"
test_command "firewalld" "firewall-cmd --help 2>&1 | head -1"
test_command "conntrack" "conntrack -h 2>&1 | head -1"
echo ""

echo "=== 第七章: VPN和隧道技术 ==="
test_command "ip_tunnel" "ip tunnel help 2>&1 | head -2"
test_command "wg" "wg --help 2>&1 | head -2"
test_command "openvpn" "openvpn --version 2>&1 | head -1"
test_command "strongswan" "ipsec --version 2>&1 | head -1"
echo ""

echo "=== 第八章: 网络监控和诊断 ==="
test_command "ping" "ping -c 1 -W 1 127.0.0.1"
test_command "mtr" "mtr -v 2>&1 | head -1"
test_command "iperf3" "iperf3 --version 2>&1 | head -1"
test_command "iftop" "iftop -h 2>&1 | head -1"
test_command "nethogs" "nethogs -h 2>&1 | head -1"
echo ""

echo "=== 第九章: 常见错误处理 ==="
test_command "ip_neigh" "ip neigh show"
test_command "arp" "arp -h 2>&1 | head -1"
test_command "netstat_r" "netstat -r"
test_command "ip_link_set" "ip link help 2>&1 | head -2"
echo ""

echo "============================================"
echo "验证完成"
echo "总测试: $((PASS + FAIL)), 通过: $PASS, 失败: $FAIL"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi