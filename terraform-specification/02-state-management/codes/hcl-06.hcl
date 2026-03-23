data "google_secret_manager_secret_version" "db_password" {
  secret = "db-password"
}

resource "google_sql_database_instance" "master" {
  name             = "master-db"
  database_version = "POSTGRES_14"

  root_password = data.google_secret_manager_secret_version.db_password.secret_data
}