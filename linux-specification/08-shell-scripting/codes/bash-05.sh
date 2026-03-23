# 默认值
${var:-default}         # var为空时使用default
${var:=default}         # var为空时赋值default

# 字符串操作
${#var}                 # 字符串长度
${var:offset}          # 切片
${var:offset:length}   # 切片指定长度
${var#pattern}          # 最短匹配删除
${var##pattern}         # 最长匹配删除
${var%pattern}          # 从结尾最短匹配删除
${var%%pattern}         # 从结尾最长匹配删除
${var/pattern/string}   # 替换第一个
${var//pattern/string}  # 替换所有