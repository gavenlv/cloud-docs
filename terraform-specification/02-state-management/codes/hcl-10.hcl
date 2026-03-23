# environments/prod/main.tf
terraform {
  required_version = ">= 1.0"
}

module "vpc" {
  source = "../../modules/vpc"

  name        = "prod-vpc"
  cidr        = "10.0.0.0/16"
  environment = "prod"
}

module "compute" {
  source = "../../modules/compute"

  vpc_id       = module.vpc.vpc_id
  subnet_id    = module.vpc.subnet_ids[0]
  environment  = "prod"
  instance_count = 3
}