terraform {
  backend "gcs" {
    bucket      = "my-terraform-state"
    prefix      = "prod"
    credentials = "path/to/service-account.json"
    encryption_key = "projects/my-project/locations/us/keyRings/my-keyring/cryptoKeys/my-key"
  }
}