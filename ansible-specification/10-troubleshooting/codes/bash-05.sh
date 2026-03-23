# 创建处理执行错误的Playbook

# 创建Playbook文件
cat > playbook-execution-errors.yml << 'EOF'
---
- name: 处理执行错误的Playbook示例
  hosts: webservers
  become: true
  tasks:
    - name: 安装Nginx（忽略错误）
      apt:
        name: nginx
        state: present
        update_cache: yes
      ignore_errors: yes
      register: nginx_install
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
    
    - name: 安装Nginx（带错误处理）
      apt:
        name: nginx
        state: present
        update_cache: yes
      register: nginx_install
      failed_when: nginx_install.rc != 0 and 'nginx' not in nginx_install.stdout
    
    - name: 显示安装结果
      debug:
        msg: "Nginx安装结果: {{ nginx_install }}"
    
    - name: 配置Nginx（带验证）
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: 'nginx -t -c %s'
        backup: yes
      register: nginx_config
      failed_when: nginx_config.rc != 0
    
    - name: 显示配置结果
      debug:
        msg: "Nginx配置结果: {{ nginx_config }}"
    
    - name: 启动Nginx服务（带等待）
      service:
        name: nginx
        state: started
        enabled: yes
      register: nginx_service
      until: nginx_service.status.ActiveState == "active"
      retries: 3
      delay: 5
    
    - name: 显示服务结果
      debug:
        msg: "Nginx服务结果: {{ nginx_service }}"
EOF

# 运行Playbook
ansible-playbook playbook-execution-errors.yml

# 预期输出：
# PLAY [处理执行错误的Playbook示例] **********************************
# TASK [Gathering Facts] ***************************************************
# ok: [localhost]
# TASK [安装Nginx（忽略错误）] *******************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\"]}"
# }
# TASK [安装Nginx（带错误处理）] *****************************************
# changed: [localhost]
# TASK [显示安装结果] *************************************************
# ok: [localhost] => {
#     "msg": "Nginx安装结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"Reading package lists...\\nBuilding dependency tree...\\nReading state information...\\nThe following NEW packages will be installed:\\n  nginx\\n0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\", \"stdout_lines\": [\"Reading package lists...\", \"Building dependency tree...\", \"Reading state information...\", \"The following NEW packages will be installed:\", \"  nginx\", \"0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.\"]}"
# }
# TASK [配置Nginx（带验证）] *********************************************
# changed: [localhost]
# TASK [显示配置结果) *************************************************
# ok: [localhost] => {
#     "msg": "Nginx配置结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\\nnginx: configuration file /etc/nginx/nginx.conf test is successful\\n\", \"stdout_lines\": [\"nginx: the configuration file /etc/nginx/nginx.conf syntax is ok\", \"nginx: configuration file /etc/nginx/nginx.conf test is successful\"]}"
# }
# TASK [启动Nginx服务（带等待）] *****************************************
# changed: [localhost]
# TASK [显示服务结果) *************************************************
# ok: [localhost] => {
#     "msg": "Nginx服务结果: {\"changed\": true, \"failed\": false, \"rc\": 0, \"stderr\": \"\", \"stderr_lines\": [], \"stdout\": \"\", \"stdout_lines\": [], \"status\": {\"ActiveEnterTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ActiveEnterTimestampMonotonic\": \"123456789\", \"ActiveState\": \"active\", \"After\": \"network.target system.slice\", \"AllowIsolate\": \"no\", \"AssertResult\": \"yes\", \"AssertTimestamp\": \"2024-01-15 10:00:00 UTC\", \"AssertTimestampMonotonic\": \"123456789\", \"Before\": \"shutdown.target\", \"BlockIOAccounting\": \"no\", \"BlockIOWeight\": \"[not set]\", \"CPUAccounting\": \"yes\", \"CPUQuotaPerSecUSec\": \"infinity\", \"CPUWeight\": \"[not set]\", \"CapabilityBoundingSet\": \"CAP_CHOWN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_FOWNER CAP_FSETID CAP_KILL CAP_MKNOD CAP_NET_BIND_SERVICE CAP_NET_RAW CAP_SETGID CAP_SETFCAP CAP_SETPCAP CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_NICE CAP_SYS_PTRACE CAP_SYS_RAWIO CAP_SYS_TIME CAP_SYS_TTY_CONFIG CAP_WAKE_ALARM\", \"CollectMode\": \"inactive\", \"ConditionResult\": \"yes\", \"ConditionTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ConditionTimestampMonotonic\": \"123456789\", \"Conflicts\": \"shutdown.target\", \"ControlGroup\": \"/system.slice/nginx.service\", \"ControlPID\": \"12345\", \"DefaultDependencies\": \"yes\", \"Delegate\": \"no\", \"Description\": \"A high performance web server and a reverse proxy server\", \"DevicePolicy\": \"auto\", \"Documentation\": \"man:nginx(8)\", \"Dynamic\": \"no\", \"ExecMainCode\": \"0\", \"ExecMainExitTimestampMonotonic\": \"0\", \"ExecMainPID\": \"12345\", \"ExecMainStartTimestamp\": \"2024-01-15 10:00:00 UTC\", \"ExecMainStartTimestampMonotonic\": \"123456789\", \"ExecMainStatus\": \"0\", \"ExecReload\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s reload ; ... }\", \"ExecReloadEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s reload ; ... }\", \"ExecStart\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -g daemon on; master_process on; ; ... }\", \"ExecStartEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -g daemon on; master_process on; ; ... }\", \"ExecStartPost\": \"{ path=/bin/kill ; argv[]=/bin/kill -s HUP $MAINPID ; ... }\", \"ExecStartPostEx\": \"{ path=/bin/kill ; argv[]=/bin/kill -s HUP $MAINPID ; ... }\", \"ExecStop\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s quit ; ... }\", \"ExecStopEx\": \"{ path=/usr/sbin/nginx ; argv[]=/usr/sbin/nginx -s quit ; ... }\", \"ExitCode\": \"0\", \"ExitCodeStatus\": \"0\", \"ExitStatus\": \"0\", \"FailureAction\": \"none\", \"FileDescriptorStoreMax\": \"0\", \"FragmentPath\": \"/etc/systemd/system/nginx.service\", \"GuessMainPID\": \"yes\", \"IOSchedulingClass\": \"[not set]\", \"IOSchedulingPriority\": \"0\", \"Id\": \"nginx.service\", \"IgnoreOnIsolate\": \"no\", \"IgnoreOnSnapshot\": \"no\", \"IgnoreSIGPIPE\": \"yes\", \"InactiveEnterTimestampMonotonic\": \"0\", \"InactiveExitTimestampMonotonic\": \"0\", \"InvocationID\": \"1234567890abcdef\", \"JobRunningTimeoutUSec\": \"infinity\", \"JobTimeoutAction\": \"none\", \"JobTimeoutUSec\": \"infinity\", \"KillMode\": \"control-group\", \"KillSignal\": \"SIGTERM\", \"LimitCPU\": \"infinity\", \"LimitCPUQuotaPerSecUSec\": \"infinity\", \"LimitData\": \"infinity\", \"LimitFSIZE\": \"infinity\", \"LimitLOCKS\": \"infinity\", \"LimitMEMLOCK\": \"infinity\", \"LimitMSGQUEUE\": \"819200\", \"LimitNICE\": \"0\", \"LimitNOFILE\": \"524288\", \"LimitNPROC\": \"123456\", \"LimitRSS\": \"infinity\", \"LimitRTPRIO\": \"infinity\", \"LimitRTTIME\": \"infinity\", \"LimitSIGPENDING\": \"123456\", \"LimitSTACK\": \"infinity\", \"LoadState\": \"loaded\", \"MainPID\": \"12345\", \"MemoryAccounting\": \"yes\", \"MemoryCurrent\": \"12345678\", \"MemoryDenyWrite\": \"no\", \"MemoryLimit\": \"infinity\", \"MemoryLow\": \"0\", \"MemoryMax\": \"infinity\", \"MemorySwapMax\": \"infinity\", \"MountFlags\": \"0\", \"NFileDescriptorStore\": \"0\", \"NRestarts\": \"0\", \"Names\": \"nginx.service\", \"NeedDaemonReload\": \"no\", \"Nice\": \"0\", \"NoNewPrivileges\": \"no\", \"NonBlocking\": \"no\", \"NotifyAccess\": \"main\", \"OOMPolicy\": \"stop\", \"OOMScoreAdjust\": \"0\", \"OnFailure\": \"no\", \"OnFailureJobMode\": \"no\", \"OnSuccess\": \"no\", \"OnSuccessJobMode\": \"no\", \"Perpetual\": \"no\", \"PIDFile\": \"/run/nginx.pid\", \"PermissionsStartOnly\": \"no\", \"PrivateDevices\": \"no\", \"PrivateMounts\": \"no\", \"PrivateNetwork\": \"no\", \"PrivateTmp\": \"no\", \"ProtectControlGroups\": \"no\", \"ProtectHome\": \"no\", \"ProtectKernelModules\": \"no\", \"ProtectKernelTunables\": \"no\", \"ProtectSystem\": \"no\", \"ProtectSystemStrict\": \"no\", \"RefuseManualStart\": \"no\", \"RefuseManualStop\": \"no\", \"RemainAfterExit\": \"no\", \"RemoveIPC\": \"no\", \"Requires\": \"network.target\", \"RequiresMountsFor\": \"\", \"Restart\": \"no\", \"RestartForceExitStatus\": \"0\", \"RestartMode\": \"no\", \"RestartUSec\": \"100ms\", \"RestrictAddressFamilies\": \"none\", \"RestrictNamespaces\": \"no\", \"RestrictRealtime\": \"no\", \"RestrictSUIDSGID\": \"no\", \"Result\": \"success\", \"RootDirectoryStartOnly\": \"no\", \"RuntimeDirectoryMode\": \"0755\", \"RuntimeDirectoryPreserve\": \"no\", \"SameProcessGroup\": \"no\", \"SecureBits\": \"0\", \"SendSIGHUP\": \"no\", \"SendSIGKILL\": \"no\", \"Slice\": \"system.slice\", \"StandardError\": \"inherit\", \"StandardInput\": \"null\", \"StandardOutput\": \"journal\", \"StartLimitAction\": \"none\", \"StartLimitBurst\": \"5\", \"StartLimitIntervalUSec\": \"10s\", \"StateChangeTimestamp\": \"2024-01-15 10:00:00 UTC\", \"StateChangeTimestampMonotonic\": \"123456789\", \"StatusErrno\": \"0\", \"StatusText\": \"\", \"StopWhenUnneeded\": \"no\", \"SubState\": \"running\", \"SuccessAction\": \"none\", \"SyslogFacility\": \"daemon\", \"SyslogIdentifier\": \"nginx\", \"SyslogLevelPrefix\": \"6\", \"SystemCallErrorNumber\": \"0\", \"TTYPath\": \"/dev/pts/0\", \"TasksAccounting\": \"yes\", \"TasksCurrent\": \"1\", \"TasksMax\": \"4915\", \"TimeoutStartUSec\": \"1min 30s\", \"TimeoutStopUSec\": \"1min 30s\", \"TimerSlackNSec\": \"50000\", \"Transient\": \"no\", \"Type\": \"notify\", \"UID\": \"0\", \"UMask\": \"0022\", \"UnitFilePreset\": \"disabled\", \"UnitFileState\": \"enabled\", \"UtmpIdentifier\": \"nginx\", \"UtmpMode\": \"user\", \"WantedBy\": \"multi-user.target\", \"Wants\": \"network.target\", \"WatchdogTimestampMonotonic\": \"0\", \"WatchdogUSec\": \"0\"}}"
# }
# PLAY RECAP **************************************************************
# localhost: ok=7    changed=3    unreachable=0    failed=0