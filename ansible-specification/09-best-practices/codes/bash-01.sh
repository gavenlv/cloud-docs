# 创建项目结构

# 创建目录结构
mkdir -p ansible-project/{inventory/{production,staging,development},group_vars,host_vars,roles/{nginx,mysql,app},playbooks,templates,files,library,filter_plugins}

# 创建README文件
cat > ansible-project/README.md << 'EOF'
# Ansible项目

## 项目结构