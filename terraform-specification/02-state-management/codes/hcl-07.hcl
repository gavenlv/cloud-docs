terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # 启用S3加密
    kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/abcd1234"
  }
}