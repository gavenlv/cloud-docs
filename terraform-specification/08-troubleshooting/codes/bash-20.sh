# 1. 使用可靠的DNS
# 配置公共DNS
# 或使用企业DNS

# 2. 配置代理
# 在企业环境中配置代理
# 或使用VPN

# 3. 监控网络
# 设置网络监控
# 及时发现网络问题

# 4. 使用重试机制
# 在Terraform配置中设置重试
provider "google" {
  project = "my-project-id"
  region  = "us-central1"

  request_timeout = "60s"
  request_retry = {
    max_retries = 5
    retry_delay  = "5s"
  }
}