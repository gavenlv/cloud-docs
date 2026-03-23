# Shell是命令解释器
# 流程: 读取命令 → 解析 → 执行 → 返回结果

# Shell类型
echo $SHELL              # 当前shell
cat /etc/shells          # 可用shell列表
# /bin/bash, /bin/sh, /bin/zsh, /bin/fish

# Bash执行流程
cat > debug.sh << 'EOF'
#!/bin/bash
set -x                  # 开启调试
echo "Hello"
set +x                  # 关闭调试
EOF

chmod +x debug.sh
./debug.sh