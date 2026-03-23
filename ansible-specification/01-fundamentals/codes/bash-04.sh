# 运行第一个命令

# 收集Facts
ansible all -m setup

# 预期输出：
# localhost | SUCCESS => {
#     "ansible_facts": {
#         "ansible_all_ipv4_addresses": [
#             "192.168.1.10"
#         ],
#         "ansible_all_ipv6_addresses": [
#             "fe80::1"
#         ],
#         "ansible_apparmor": {
#             "status": "enabled"
#         },
#         "ansible_architecture": "x86_64",
#         "ansible_bios_date": "01/01/2011",
#         "ansible_bios_version": "1.0",
#         "ansible_cmdline": {
#             "BOOT_IMAGE": "/boot/vmlinuz-5.15.0-91-generic",
#             "quiet": true,
#             "ro": true,
#             "root": "UUID=12345678-1234-1234-1234-123456789012"
#         },
#         "ansible_date_time": {
#             "date": "2024-01-15",
#             "day": "15",
#             "epoch": "1705296000",
#             "hour": "10",
#             "iso8601_basic": "20240115T100000Z",
#             "iso8601_basic_short": "20240115T100000",
#             "iso8601_micro": "2024-01-15T10:00:00.000000Z",
#             "minute": "00",
#             "month": "01",
#             "second": "00",
#             "time": "10:00:00",
#             "weekday": "Monday",
#             "weekday_number": "1",
#             "weekday_short": "Mon",
#             "year": "2024"
#         },
#         "ansible_default_ipv4": {
#             "address": "192.168.1.10",
#             "alias": "eth0",
#             "broadcast": "192.168.1.255",
#             "device": "eth0",
#             "gateway": "192.168.1.1",
#             "interface": "eth0",
#             "macaddress": "00:11:22:33:44:55",
#             "mtu": 1500,
#             "netmask": "255.255.255.0",
#             "network": "192.168.1.0",
#             "type": "ether"
#         },
#         "ansible_distribution": "Ubuntu",
#         "ansible_distribution_file_parsed": true,
#         "ansible_distribution_file_path": "/etc/os-release",
#         "ansible_distribution_file_variety": "Ubuntu",
#         "ansible_distribution_major_version": "22",
#         "ansible_distribution_release": "jammy",
#         "ansible_distribution_version": "22.04",
#         "ansible_dns": {
#             "nameservers": [
#                 "127.0.0.53"
#             ],
#             "search": [
#                 "localdomain"
#             ]
#         },
#         "ansible_domain": "",
#         "ansible_effective_group_id": 1000,
#         "ansible_effective_user_id": 1000,
#         "ansible_env": {
#             "HOME": "/home/user",
#             "LANG": "en_US.UTF-8",
#             "LC_ALL": "en_US.UTF-8",
#             "LOGNAME": "user",
#             "PATH": "/usr/local/bin:/usr/bin:/bin",
#             "PWD": "/home/user",
#             "SHELL": "/bin/bash",
#             "USER": "user"
#         },
#         "ansible_fips": false,
#         "ansible_fqdn": "localhost",
#         "ansible_hostname": "localhost",
#         "ansible_hostnqn": "",
#         "ansible_kernel": "5.15.0-91-generic",
#         "ansible_local": {},
#         "ansible_lsb": {
#             "codename": "jammy",
#             "description": "Ubuntu 22.04.3 LTS",
#             "id": "Ubuntu",
#             "major_release": "22",
#             "release": "22.04"
#         },
#         "ansible_machine": "x86_64",
#         "ansible_machine_id": "1234567890abcdef1234567890abcdef",
#         "ansible_memtotal_mb": 8192,
#         "ansible_memory_mb": {
#             "nocache": {
#                 "free": 4096,
#                 "real": {
#                     "free": 4096,
#                     "total": 8192,
#                     "used": 4096
#                 },
#                 "swap": {
#                     "cached": 0,
#                     "free": 2048,
#                     "total": 2048,
#                     "used": 0
#                 }
#             },
#             "real": {
#                 "free": 2048,
#                 "total": 8192,
#                 "used": 6144
#             },
#             "swap": {
#                 "cached": 0,
#                 "free": 2048,
#                 "total": 2048,
#                 "used": 0
#             }
#         },
#         "ansible_nodename": "localhost",
#         "ansible_os_family": "Debian",
#         "ansible_pkg_mgr": "apt",
#         "ansible_processor": [
#             "0",
#             "1",
#             "2",
#             "3"
#         ],
#         "ansible_processor_cores": 4,
#         "ansible_processor_count": 1,
#         "ansible_processor_threads_per_core": 1,
#         "ansible_processor_vcpus": 4,
#         "ansible_product_name": "VMware Virtual Platform",
#         "ansible_product_serial": "VMware-56 4d 12 34 56 78 90 ab cd",
#         "ansible_product_uuid": "564d1234-5678-90ab-cdef-1234567890ab",
#         "ansible_product_version": "None",
#         "ansible_python": {
#             "executable": "/usr/bin/python3",
#             "has_sslcontext": true,
#             "type": "cpython",
#             "version": {
#                 "major": 3,
#                 "micro": 12,
#                 "minor": 10,
#                 "releaselevel": "final",
#                 "serial": 0
#             },
#             "version_info": [
#                 3,
#                 10,
#                 12,
#                 "final",
#                 0
#             ]
#         },
#         "ansible_python_version": "3.10.12",
#         "ansible_real_group_id": 1000,
#         "ansible_real_user_id": 1000,
#         "ansible_selinux": {
#             "status": "Missing SELinux library"
#         },
#         "ansible_selinux_python_present": false,
#         "ansible_service_mgr": "systemd",
#         "ansible_ssh_host_key_dsa_public": "AAAAB3NzaC1kc3MAAACBAJ5/...",
#         "ansible_ssh_host_key_ecdsa_public": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENj...",
#         "ansible_ssh_host_key_ed25519_public": "AAAAC3NzaC1lZDI1NTE5AAAAIM4v...",
#         "ansible_ssh_host_key_rsa_public": "AAAAB3NzaC1yc2EAAAADAQABAAABAQC5/...",
#         "ansible_system": "Linux",
#         "ansible_system_vendor": "VMware, Inc.",
#         "ansible_uptime_seconds": 86400,
#         "ansible_user_dir": "/home/user",
#         "ansible_user_gecos": "User",
#         "ansible_user_gid": 1000,
#         "ansible_user_id": "user",
#         "ansible_user_shell": "/bin/bash",
#         "ansible_user_uid": 1000,
#         "ansible_userspace_architecture": "x86_64",
#         "ansible_userspace_bits": "64",
#         "ansible_virtualization_role": "guest",
#         "ansible_virtualization_type": "VMware",
#         "discovered_interpreter_python": "/usr/bin/python3"
#     },
#     "changed": false
# }

# 执行命令
ansible all -m command -a "echo 'Hello, World!'"

# 预期输出：
# localhost | CHANGED | rc=0 >>
# Hello, World!