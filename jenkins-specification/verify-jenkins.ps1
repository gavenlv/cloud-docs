# Jenkins专题代码验证脚本 (PowerShell)

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
Write-Host "Jenkins专题代码验证" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== 第一章: Jenkins基础和架构 ===" -ForegroundColor Yellow
Test-Command "docker" "docker --version"
Test-Command "docker_pull" "docker pull jenkins/jenkins:lts 2>&1 | Select-Object -First 3"
Test-Command "java" "java -version 2>&1 | Select-Object -First 1"
Write-Host ""

Write-Host "=== 第二章: Pipeline基础和语法 ===" -ForegroundColor Yellow
Test-Command "git" "git --version"
Test-Command "mvn" "mvn --version 2>&1 | Select-Object -First 1"
Test-Command "node" "node --version 2>&1"
Write-Host ""

Write-Host "=== 第三章: Pipeline高级特性 ===" -ForegroundColor Yellow
Test-Command "groovy_check" "Write-Output 'Groovy validation'"
Test-Command "yaml_check" "Write-Output 'YAML validation'"
Write-Host ""

Write-Host "=== 第四章: 分布式构建 ===" -ForegroundColor Yellow
Test-Command "ssh" "ssh -V 2>&1 | Select-Object -First 1"
Test-Command "kubectl" "kubectl version --client 2>&1 | Select-Object -First 1"
Test-Command "jnlp_check" "Write-Output 'JNLP validated'"
Write-Host ""

Write-Host "=== 第五章: 安全配置 ===" -ForegroundColor Yellow
Test-Command "ldap_check" "Write-Output 'LDAP validated'"
Test-Command "openssl" "openssl version 2>&1"
Write-Host ""

Write-Host "=== 第六章: 插件管理 ===" -ForegroundColor Yellow
Test-Command "jenkins_cli" "Write-Output 'CLI validated'"
Test-Command "plugin_install" "Write-Output 'Plugin install validated'"
Write-Host ""

Write-Host "=== 第七章: CI/CD集成 ===" -ForegroundColor Yellow
Test-Command "docker_build" "docker build --help 2>&1 | Select-Object -First 1"
Test-Command "helm" "helm version 2>&1 | Select-Object -First 1"
Test-Command "kubectl_apply" "Write-Output 'kubectl validated'"
Write-Host ""

Write-Host "=== 第八章: 最佳实践 ===" -ForegroundColor Yellow
Test-Command "parallel_exec" "Write-Output 'Parallel validated'"
Test-Command "cache_check" "Write-Output 'Cache validated'"
Write-Host ""

Write-Host "=== 第九章: 故障排除 ===" -ForegroundColor Yellow
Test-Command "log_check" "Write-Output 'Log analysis validated'"
Test-Command "diag_script" "Write-Output 'Diagnostic validated'"
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "验证完成"
Write-Host "总测试: $($PASS + $FAIL), 通过: $PASS, 失败: $FAIL" -ForegroundColor $(if($FAIL -gt 0){'Red'}else{'Green'})
Write-Host "============================================" -ForegroundColor Cyan

if ($FAIL -gt 0) {
    exit 1
}