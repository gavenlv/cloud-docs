# 方案1：查看依赖图
# 生成依赖图
terraform graph | dot -Tpng > dependency-graph.png

# 查看文本依赖图
terraform graph

# 方案2：移除不必要的依赖
# 错误示例
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_compute_network" "vpc" {
  name = "my-vpc"

  depends_on = [
    google_compute_subnetwork.subnet  # 错误：循环依赖
  ]
}

# 正确示例
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

# 方案3：拆分模块
# 错误示例：模块间循环依赖
module "vpc" {
  source = "./modules/vpc"
}

module "subnet" {
  source = "./modules/subnet"
  vpc_id  = module.vpc.vpc_id
}

module "vpc" {
  source = "./modules/vpc"
  subnet_id = module.subnet.subnet_id  # 错误：循环依赖
}

# 正确示例：拆分模块
module "network" {
  source = "./modules/network"
}

# 方案4：使用数据源
# 错误示例：循环依赖
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
}

resource "google_compute_network" "vpc" {
  name = "my-vpc"
  subnet_id = google_compute_subnetwork.subnet.id  # 错误：循环依赖
}

# 正确示例：使用数据源
data "google_compute_network" "existing_vpc" {
  name = "existing-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = data.google_compute_network.existing_vpc.id
}