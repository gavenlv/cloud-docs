# 使用docker stats监控容器
docker stats

# 输出：
# CONTAINER ID   NAME                CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O   PIDS
# abc123def456   web-server          0.50%      128MiB / 512MiB   25.00%    1.2kB / 0B   0B / 0B   5

# 使用docker inspect查看容器详细信息
docker inspect web-server

# 输出：
# [
#     {
#         "Id": "abc123def4567890123456789012345678901234567890123456789012345678",
#         "Created": "2024-01-15T10:30:00.000000000Z",
#         "Path": "/docker-entrypoint.sh",
#         "Args": [
#             "nginx",
#             "-g",
#             "daemon off;"
#         ],
#         "State": {
#             "Status": "running",
#             "Running": true,
#             "Paused": false,
#             "Restarting": false,
#             "OOMKilled": false,
#             "Dead": false,
#             "Pid": 12345,
#             "ExitCode": 0,
#             "Error": "",
#             "StartedAt": "2024-01-15T10:30:00.000000000Z",
#             "FinishedAt": "0001-01-01T00:00:00Z"
#         },
#         "Image": "sha256:abc123def4567890123456789012345678901234567890123456789012345678",
#         "ResolvConfPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/resolv.conf",
#         "HostnamePath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/hostname",
#         "HostsPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/hosts",
#         "LogPath": "/var/lib/docker/containers/abc123def4567890123456789012345678901234567890123456789012345678/abc123def4567890123456789012345678901234567890123456789012345678-json.log",
#         "Name": "/web-server",
#         "RestartCount": 0,
#         "Driver": "overlay2",
#         "Platform": "linux",
#         "MountLabel": "",
#         "ProcessLabel": "",
#         "AppArmorProfile": "",
#         "ExecIDs": null,
#         "HostConfig": {
#             "Binds": null,
#             "ContainerIDFile": "",
#             "LogConfig": {
#                 "Type": "json-file",
#                 "Config": {}
#             },
#             "NetworkMode": "default",
#             "PortBindings": {
#                 "80/tcp": [
#                     {
#                         "HostIp": "",
#                         "HostPort": "80"
#                     }
#                 ]
#             },
#             "RestartPolicy": {
#                 "Name": "no",
#                 "MaximumRetryCount": 0
#             },
#             "AutoRemove": false,
#             "VolumeDriver": "",
#             "VolumesFrom": null,
#             "CapAdd": null,
#             "CapDrop": null,
#             "CgroupnsMode": "host",
#             "Dns": [],
#             "DnsOptions": [],
#             "DnsSearch": [],
#             "ExtraHosts": null,
#             "GroupAdd": null,
#             "IpcMode": "private",
#             "Cgroup": "",
#             "Links": null,
#             "OomScoreAdj": 0,
#             "PidMode": "",
#             "Privileged": false,
#             "PublishAllPorts": false,
#             "ReadonlyRootfs": false,
#             "SecurityOpt": null,
#             "UTSMode": "",
#             "UsernsMode": "",
#             "ShmSize": 67108864,
#             "Runtime": "runc",
#             "ConsoleSize": [
#                 0,
#                 0
#             ],
#             "Isolation": "",
#             "CpuShares": 0,
#             "Memory": 0,
#             "NanoCpus": 0,
#             "CgroupParent": "",
#             "BlkioWeight": 0,
#             "BlkioWeightDevice": [],
#             "BlkioDeviceReadBps": null,
#             "BlkioDeviceWriteBps": null,
#             "BlkioDeviceReadIOps": null,
#             "BlkioDeviceWriteIOps": null,
#             "CpuPeriod": 0,
#             "CpuQuota": 0,
#             "CpuRealtimePeriod": 0,
#             "CpuRealtimeRuntime": 0,
#             "CpusetCpus": "",
#             "CpusetMems": "",
#             "Devices": [],
#             "DeviceCgroupRules": null,
#             "DeviceRequests": null,
#             "KernelMemory": 0,
#             "KernelMemoryTCP": 0,
#             "MemoryReservation": 0,
#             "MemorySwap": 0,
#             "MemorySwappiness": null,
#             "OomKillDisable": false,
#             "PidsLimit": null,
#             "Ulimits": null,
#             "CpuCount": 0,
#             "CpuPercent": 0,
#             "IOMaximumIOps": 0,
#             "IOMaximumBandwidth": 0,
#             "MaskedPaths": [
#                 "/proc/asound",
#                 "/proc/acpi",
#                 "/proc/kcore",
#                 "/proc/keys",
#                 "/proc/latency_stats",
#                 "/proc/timer_list",
#                 "/proc/timer_stats",
#                 "/proc/sched_debug",
#                 "/proc/scsi",
#                 "/sys/firmware"
#             ],
#             "ReadonlyPaths": [
#                 "/proc/bus",
#                 "/proc/fs",
#                 "/proc/irq",
#                 "/proc/sys",
#                 "/proc/sysrq-trigger"
#             ]
#         },
#         "GraphDriver": {
#             "Data": {
#                 "LowerDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678-init/diff:/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/diff",
#                 "MergedDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/merged",
#                 "UpperDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/diff",
#                 "WorkDir": "/var/lib/docker/overlay2/abc123def4567890123456789012345678901234567890123456789012345678/work"
#             },
#             "Name": "overlay2"
#         },
#         "Mounts": [],
#         "Config": {
#             "Hostname": "abc123def4567890",
#             "Domainname": "",
#             "User": "",
#             "AttachStdin": false,
#             "AttachStdout": true,
#             "AttachStderr": true,
#             "ExposedPorts": {
#                 "80/tcp": {}
#             },
#             "Tty": false,
#             "OpenStdin": false,
#             "StdinOnce": false,
#             "Env": [
#                 "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
#                 "NGINX_VERSION=1.24.0",
#                 "NJS_VERSION=0.7.12",
#                 "PKG_RELEASE=1~bullseye"
#             ],
#             "Cmd": [
#                 "nginx",
#                 "-g",
#                 "daemon off;"
#             ],
#             "Image": "nginx:latest",
#             "Volumes": null,
#             "WorkingDir": "",
#             "Entrypoint": [
#                 "/docker-entrypoint.sh"
#             ],
#             "OnBuild": null,
#             "Labels": {
#                 "maintainer": "NGINX Docker Maintainers <docker-maint@nginx.com>"
#             },
#             "StopSignal": "SIGQUIT"
#         },
#         "NetworkSettings": {
#             "Bridge": "",
#             "SandboxID": "abc123def4567890123456789012345678901234567890123456789012345678",
#             "HairpinMode": false,
#             "LinkLocalIPv6Address": "",
#             "LinkLocalIPv6PrefixLen": 0,
#             "Ports": {
#                 "80/tcp": [
#                     {
#                         "HostIp": "0.0.0.0",
#                         "HostPort": "80"
#                     }
#                 ]
#             },
#             "SandboxKey": "/var/run/docker/netns/abc123def4567890123456789012345678901234567890123456789012345678",
#             "SecondaryIPAddresses": null,
#             "SecondaryIPv6Addresses": null,
#             "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#             "Gateway": "172.17.0.1",
#             "GlobalIPv6Address": "",
#             "GlobalIPv6PrefixLen": 0,
#             "IPAddress": "172.17.0.2",
#             "IPPrefixLen": 16,
#             "IPv6Gateway": "",
#             "GlobalIPv6Address": "",
#             "GlobalIPv6PrefixLen": 0,
#             "IPAddress": "172.17.0.2",
#             "IPPrefixLen": 16,
#             "IPv6Gateway": "",
#             "MacAddress": "02:42:ac:11:00:02",
#             "Networks": {
#                 "bridge": {
#                     "IPAMConfig": null,
#                     "Links": null,
#                     "Aliases": null,
#                     "NetworkID": "abc123def4567890123456789012345678901234567890123456789012345678",
#                     "EndpointID": "abc123def4567890123456789012345678901234567890123456789012345678",
#                     "Gateway": "172.17.0.1",
#                     "IPAddress": "172.17.0.2",
#                     "IPPrefixLen": 16,
#                     "IPv6Gateway": "",
#                     "GlobalIPv6Address": "",
#                     "GlobalIPv6PrefixLen": 0,
#                     "MacAddress": "02:42:ac:11:00:02",
#                     "DriverOpts": null
#                 }
#             }
#         }
#     }
# ]

# 使用Prometheus监控容器
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

# 使用Grafana可视化监控数据
docker run -d \
  --name grafana \
  -p 3000:3000 \
  grafana/grafana