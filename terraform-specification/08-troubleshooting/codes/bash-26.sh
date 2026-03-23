# 生成依赖图
terraform graph > graph.dot

# 转换为PNG
dot -Tpng graph.dot -o graph.png

# 查看依赖图
# 使用Graphviz查看graph.png

# 查看文本依赖图
terraform graph