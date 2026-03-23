# 1. 查看dev工作空间状态
terraform workspace select dev
terraform state list
# google_compute_network.vpc

# 2. 查看staging工作空间状态
terraform workspace select staging
terraform state list
# google_compute_network.vpc

# 3. 查看prod工作空间状态
terraform workspace select prod
terraform state list
# google_compute_network.vpc

# 4. 查看状态文件位置
terraform output -json | jq '.backend'

# 输出：
# {
#   "type": "local",
#   "path": "./terraform.tfstate.d"
# }

# 5. 查看实际状态文件
ls -la terraform.tfstate.d/
# total 24
# drwxr-xr-x  2 user user 4096 Jan 15 10:30 .
# drwxr-xr-x  5 user user 4096 Jan 15 10:30 ..
# -rw-r--r--  1 user user 1234 Jan 15 10:30 default.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:31 dev.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:32 staging.tfstate
# -rw-r--r--  1 user user 1234 Jan 15 10:33 prod.tfstate