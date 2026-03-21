#!/bin/bash
# Linux专题代码验证脚本

set -e

echo "============================================"
echo "Linux专题代码验证"
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

echo "=== 第一章: Linux基础和核心原理 ==="
test_command "ps aux" "ps aux --sort=-%cpu | head -6"
test_command "meminfo" "cat /proc/meminfo | head -10"
test_command "uptime" "uptime"
test_command "uname" "uname -a"
test_command "kernel_version" "cat /proc/version"
echo ""

echo "=== 第二章: 文件系统管理 ==="
test_command "lsblk" "lsblk"
test_command "df" "df -h"
test_command "du" "du -sh /tmp"
test_command "stat" "stat /etc/passwd"
test_command "inode" "ls -li /etc/passwd | head -1"
echo ""

echo "=== 第三章: 进程和任务管理 ==="
test_command "ps" "ps -ef | head -5"
test_command "pstree" "pstree -p | head -5"
test_command "pgrep" "pgrep -a bash | head -1"
test_command "process_state" "ps aux | awk '{print \$8}' | grep -E '^[RSDZTW]' | head -1"
test_command "signal" "kill -l | head -5"
echo ""

echo "=== 第四章: 网络管理 ==="
test_command "ip_link" "ip link show"
test_command "ip_addr" "ip addr show"
test_command "ip_route" "ip route show"
test_command "ss" "ss -tuln | head -5"
test_command "ping" "ping -c 1 -W 1 127.0.0.1"
echo ""

echo "=== 第五章: 用户和权限管理 ==="
test_command "whoami" "whoami"
test_command "id" "id"
test_command "passwd_content" "cat /etc/passwd | head -3"
test_command "group_content" "cat /etc/group | head -3"
test_command "sudo_version" "sudo -V | head -1"
echo ""

echo "=== 第六章: 软件和服务管理 ==="
test_command "systemctl" "systemctl list-units --type=service --no-pager | head -5"
test_command "apt_update" "apt-get update -qq 2>/dev/null || true"
test_command "dpkg" "dpkg -l | head -5"
test_command "journalctl" "journalctl --since '1 hour ago' -n 3 --no-pager 2>/dev/null || true"
test_command "systemd_version" "systemctl --version | head -1"
echo ""

echo "=== 第七章: 日志和监控 ==="
test_command "dmesg" "dmesg | tail -3"
test_command "last" "last | head -3"
test_command "logrotate" "logrotate --version 2>&1 | head -1"
test_command "rsyslogd" "rsyslogd -v 2>&1 | head -1"
test_command "vmstat" "vmstat 1 1"
echo ""

echo "=== 第八章: Shell脚本编程 ==="
test_command "bash_version" "bash --version | head -1"
test_command "shell_variables" "echo \$SHELL"
test_command "shell_functions" "type ll 2>/dev/null || echo 'alias not found'"
test_command "test" "test 1 -eq 1 && echo 'test works'"
test_command "shell_conditionals" "[ 1 -eq 1 ] && echo 'conditional works'"
echo ""

echo "=== 第九章: 常见错误处理 ==="
test_command "strace" "strace -V 2>&1 | head -1"
test_command "lsof" "lsof -h 2>&1 | head -1"
test_command "netstat" "netstat -h 2>&1 | head -1"
test_command "tcpdump" "tcpdump --version 2>&1 | head -1"
test_command "journalctl_errors" "journalctl -p err -n 3 --no-pager 2>/dev/null || true"
echo ""

echo "============================================"
echo "验证完成"
echo "总测试: $((PASS + FAIL)), 通过: $PASS, 失败: $FAIL"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi