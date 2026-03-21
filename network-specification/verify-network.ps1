# 网络专题代码验证脚本 (PowerShell)

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
Write-Host "网络专题代码验证" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== 第一章: 网络基础和协议栈 ===" -ForegroundColor Yellow
Test-Command "ip_addr" "ip addr show"
Test-Command "ip_route" "ip route show"
Test-Command "ip_link" "ip link show"
Test-Command "ss" "ss -V 2>&1 | Select-Object -First 1"
Test-Command "tcpdump" "tcpdump --version 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第二章: TCP/IP协议详解 ===" -ForegroundColor Yellow
Test-Command "ss_tan" "ss -tan | Select-Object -First 3"
Test-Command "ss_estab" "ss -tan state established | Select-Object -First 3"
Test-Command "cat_tcp" "Get-Content /proc/sys/net/ipv4/tcp_congestion_control"
Test-Command "netstat" "netstat -h 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第三章: 路由原理 ===" -ForegroundColor Yellow
Test-Command "ip_route_show" "ip route show"
Test-Command "ip_rule" "ip rule show"
Test-Command "ip_route_get" "ip route get 8.8.8.8"
Test-Command "traceroute" "traceroute -h 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第四章: DNS原理 ===" -ForegroundColor Yellow
Test-Command "dig" "dig -v 2>&1 | Select-Object -First 1"
Test-Command "nslookup" "nslookup -version 2>&1 | Select-Object -First 1"
Test-Command "host" "host -V 2>&1 | Select-Object -First 1"
Test-Command "cat_resolv" "Get-Content /etc/resolv.conf | Select-Object -First 3"
Write-Host ""

Write-Host "=== 第五章: 网络安全 ===" -ForegroundColor Yellow
Test-Command "openssl" "openssl version"
Test-Command "nmap" "nmap --version 2>&1 | Select-Object -First 3"
Test-Command "openssl_s_client" "openssl s_client -help 2>&1 | Select-Object -First 1"
Test-Command "ssh" "ssh -V 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第六章: 防火墙和iptables ===" -ForegroundColor Yellow
Test-Command "iptables" "iptables -L -n | Select-Object -First 5"
Test-Command "iptables_nat" "iptables -t nat -L -n | Select-Object -First 5"
Test-Command "firewalld" "firewall-cmd --help 2>&1 | Select-Object -First 1"
Test-Command "conntrack" "conntrack -h 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第七章: VPN和隧道技术 ===" -ForegroundColor Yellow
Test-Command "ip_tunnel" "ip tunnel help 2>&1 | Select-Object -First 2"
Test-Command "wg" "wg --help 2>&1 | Select-Object -First 2"
Test-Command "openvpn" "openvpn --version 2>&1 | Select-Object -First 1"
Test-Command "strongswan" "ipsec --version 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第八章: 网络监控和诊断 ===" -ForegroundColor Yellow
Test-Command "ping" "ping -c 1 -W 1 127.0.0.1"
Test-Command "mtr" "mtr -v 2>&1 | Select-Object -First 1"
Test-Command "iperf3" "iperf3 --version 2>&1 | Select-Object -First 1"
Test-Command "iftop" "iftop -h 2>&1 | Select-Object -First 1"
Test-Command "nethogs" "nethogs -h 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第九章: 常见错误处理 ===" -ForegroundColor Yellow
Test-Command "ip_neigh" "ip neigh show"
Test-Command "arp" "arp -h 2>&1 | Select-Object -First 1"
Test-Command "netstat_r" "netstat -r"
Test-Command "ip_link_set" "ip link help 2>&1 | Select-Object -First 2"
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "验证完成"
Write-Host "总测试: $($PASS + $FAIL), 通过: $PASS, 失败: $FAIL" -ForegroundColor $(if($FAIL -gt 0){'Red'}else{'Green'})
Write-Host "============================================" -ForegroundColor Cyan

if ($FAIL -gt 0) {
    exit 1
}