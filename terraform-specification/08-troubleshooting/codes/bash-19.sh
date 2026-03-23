# 方案1：检查DNS
# 1. 测试DNS解析
nslookup www.googleapis.com
dig www.googleapis.com

# 2. 刷新DNS缓存
# Linux
sudo systemd-resolve --flush-caches

# macOS
sudo dscacheutil -flushcache

# Windows
ipconfig /flushdns

# 方案2：检查网络连接
# 1. 测试网络连接
ping www.googleapis.com

# 2. 测试API连接
curl https://www.googleapis.com/compute/v1/projects

# 3. 测试代理
curl -x http://proxy.example.com:8080 \
  https://www.googleapis.com/compute/v1/projects

# 方案3：配置代理
# 设置HTTP代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# 在Terraform配置中设置
provider "google" {
  project = "my-project-id"
  region  = "us-central1"

  http_proxy {
    url = "http://proxy.example.com:8080"
  }
}

# 方案4：检查GCP状态
# 1. 检查GCP状态
curl https://status.cloud.google.com/

# 2. 检查API状态
gcloud services list --enabled