# Linux专题代码验证脚本 (PowerShell)

$PASS = 0
$FAIL = 0

function Test-Command {
    param(
        [string]$Name,
        [string]$Cmd
    )

    Write-Host -NoNewline "[$Name] ... "
    try {
        $null = Invoke-Expression $Cmd 2>$null
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "PASS" -ForegroundColor Green
            $script:PASS++
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            $script:FAIL++
        }
    } catch {
        Write-Host "FAIL" -ForegroundColor Red
        $script:FAIL++
    }
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Linux专题代码验证" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== 第一章: Linux基础和核心原理 ===" -ForegroundColor Yellow
Test-Command "ps aux" "ps aux --sort=-%cpu | Select-Object -First 6"
Test-Command "meminfo" "Get-Content /proc/meminfo | Select-Object -First 10"
Test-Command "uptime" "uptime"
Test-Command "uname" "uname -a"
Test-Command "kernel_version" "Get-Content /proc/version"
Write-Host ""

Write-Host "=== 第二章: 文件系统管理 ===" -ForegroundColor Yellow
Test-Command "lsblk" "lsblk"
Test-Command "df" "df -h"
Test-Command "du" "du -sh /tmp"
Test-Command "stat" "stat /etc/passwd"
Test-Command "inode" "ls -li /etc/passwd | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第三章: 进程和任务管理 ===" -ForegroundColor Yellow
Test-Command "ps" "ps -ef | Select-Object -First 5"
Test-Command "pstree" "pstree -p | Select-Object -First 5"
Test-Command "pgrep" "pgrep -a bash | Select-Object -First 1"
Test-Command "process_state" 'ps aux | ForEach-Object { $_ -match "^(\S+\s+){7}([RSDZTW])" } | Select-Object -First 1'
Test-Command "signal" "kill -l | Select-Object -First 5"
Write-Host ""

Write-Host "=== 第四章: 网络管理 ===" -ForegroundColor Yellow
Test-Command "ip_link" "ip link show"
Test-Command "ip_addr" "ip addr show"
Test-Command "ip_route" "ip route show"
Test-Command "ss" "ss -tuln | Select-Object -First 5"
Test-Command "ping" "ping -c 1 -W 1 127.0.0.1"
Write-Host ""

Write-Host "=== 第五章: 用户和权限管理 ===" -ForegroundColor Yellow
Test-Command "whoami" "whoami"
Test-Command "id" "id"
Test-Command "passwd_content" "Get-Content /etc/passwd | Select-Object -First 3"
Test-Command "group_content" "Get-Content /etc/group | Select-Object -First 3"
Test-Command "sudo_version" "sudo -V 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第六章: 软件和服务管理 ===" -ForegroundColor Yellow
Test-Command "systemctl" "systemctl list-units --type=service --no-pager | Select-Object -First 5"
Test-Command "dpkg" "dpkg -l | Select-Object -First 5"
Test-Command "journalctl" "journalctl --since '1 hour ago' -n 3 --no-pager 2>&1 | Select-Object -First 3"
Test-Command "systemd_version" "systemctl --version | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第七章: 日志和监控 ===" -ForegroundColor Yellow
Test-Command "dmesg" "dmesg | Select-Object -Last 3"
Test-Command "last" "last | Select-Object -First 3"
Test-Command "logrotate" "logrotate --version 2>&1 | Select-Object -First 1"
Test-Command "rsyslogd" "rsyslogd -v 2>&1 | Select-Object -First 1"
Test-Command "vmstat" "vmstat 1 1"
Write-Host ""

Write-Host "=== 第八章: Shell脚本编程 ===" -ForegroundColor Yellow
Test-Command "bash_version" "bash --version | Select-Object -First 1"
Test-Command "shell_variables" 'echo $SHELL'
Test-Command "test" "test 1 -eq 1 && echo 'test works'"
Test-Command "shell_conditionals" '[ 1 -eq 1 ] && echo ''conditional works'''
Write-Host ""

Write-Host "=== 第九章: 常见错误处理 ===" -ForegroundColor Yellow
Test-Command "strace" "strace -V 2>&1 | Select-Object -First 1"
Test-Command "lsof" "lsof -h 2>&1 | Select-Object -First 1"
Test-Command "tcpdump" "tcpdump --version 2>&1 | Select-Object -First 1"
Test-Command "journalctl_errors" "journalctl -p err -n 3 --no-pager 2>&1 | Select-Object -First 3"
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "验证完成"
Write-Host "总测试: $($PASS + $FAIL), 通过: $PASS, 失败: $FAIL" -ForegroundColor $(if($FAIL -gt 0){'Red'}else{'Green'})
Write-Host "============================================" -ForegroundColor Cyan

if ($FAIL -gt 0) {
    exit 1
}