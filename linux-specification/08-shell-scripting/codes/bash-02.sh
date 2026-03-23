# 常用set选项
set -e                  # 遇错退出
set -u                  # 使用未定义变量报错
set -n                  # 检查语法不执行
set -v                  # 显示输入行
set -x                  # 显示命令和参数

# 使用shopt设置
shopt -s extglob        # 开启扩展通配符
shopt -u extglob        # 关闭扩展通配符
shopt | head            # 查看所有选项