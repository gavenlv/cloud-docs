# 使用Vault provider
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

provider "vault" {
  address = "https://vault.example.com:8200"
  token   = var.vault_token
}

data "vault_generic_secret" "db_password" {
  path = "secret/data/db"
}

resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"

  root_password = data.vault_generic_secret.db_password.data["password"]
}