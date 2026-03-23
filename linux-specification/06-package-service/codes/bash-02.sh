# /etc/apt/sources.list 格式
# deb/deb-src 镜像URL 发行版版本 组件

cat /etc/apt/sources.list
# deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
# deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
# deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted

# 源格式说明:
# deb     - 二进制包仓库
# deb-src - 源码包仓库
# 镜像URL - 软件源地址
# 发行版  - jammy (Ubuntu 22.04) 或 focal (Ubuntu 20.04)
# 组件    - main, restricted, universe, multiverse

# 添加PPA (Personal Package Archive)
sudo add-apt-repository ppa:user/ppa-name

# 添加第三方源
sudo bash -c 'echo "deb http://example.com/repo stable main" > /etc/apt/sources.list.d/example.list'

# 签名密钥
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEYID
sudo apt-key fingerprint                          # 查看已添加的密钥