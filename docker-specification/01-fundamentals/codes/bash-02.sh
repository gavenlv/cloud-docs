# 运行Ubuntu容器并进入交互式shell
docker run -it ubuntu bash

# 参数说明：
# -i: 交互式模式（interactive）
# -t: 分配伪终端（pseudo-TTY）
# ubuntu: 镜像名称
# bash: 要运行的命令

# 在容器内执行命令
root@container-id:/# cat /etc/os-release
# PRETTY_NAME="Ubuntu 22.04.3 LTS"
# NAME="Ubuntu"
# VERSION_ID="22.04"
# VERSION="22.04.3 LTS (Jammy Jellyfish)"
# ID=ubuntu
# ID_LIKE=debian
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# VERSION_CODENAME=jammy
# UBUNTU_CODENAME=jammy

# 退出容器
root@container-id:/# exit