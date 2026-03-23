# 安装
rpm -ivh package.rpm            # 安装
rpm -ivh --nodeps package.rpm   # 不检查依赖
rpm -ivh --force package.rpm    # 强制安装

# 升级
rpm -Uvh package.rpm            # 升级(如果没有则安装)
rpm -Fvh package.rpm            # 升级(如果没有则不安装)

# 删除
rpm -e package                  # 删除
rpm -e --nodeps package        # 不检查依赖删除

# 查询
rpm -qa                         # 所有已安装包
rpm -qf /path/to/file          # 文件属于哪个包
rpm -qi package                 # 包信息
rpm -ql package                 # 包的文件列表
rpm -q --requires package       # 包依赖
rpm -q --whatrequires package   # 哪些包依赖此包

# 验证
rpm -V package                  # 验证包文件
rpm -Va                        # 验证所有包
rpm --import RPM-GPG-KEY       # 导入签名密钥