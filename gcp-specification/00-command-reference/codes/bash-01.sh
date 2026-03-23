# gcloud基础命令

# 初始化gcloud
gcloud init

# 登录认证
gcloud auth login
gcloud auth activate-service-account --key-file=KEY_FILE.json
gcloud auth list

# 退出登录
gcloud auth revoke

# 设置默认项目
gcloud config set project PROJECT_ID

# 设置默认区域和区域
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# 查看当前配置
gcloud config list
gcloud config get-value project
gcloud config get-value compute/region

# 启用API服务
gcloud services enable SERVICE_NAME.googleapis.com

# 列出所有可用的API
gcloud services list --available

# 更新gcloud组件
gcloud components update

# 安装额外组件
gcloud components install COMPONENT_ID

# 显示帮助
gcloud --help
gcloud compute --help
gcloud compute instances --help