# -------------------------------------------------- #
# HydroServer GCP Cloud SQL Database                 #
# -------------------------------------------------- #

resource "google_sql_database_instance" "hydroserver_db_instance" {
  name                = "hydroserver-${var.instance}"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true
  settings {
    tier = "db-f1-micro"
    availability_type = "REGIONAL"
    ip_configuration {
      ipv4_enabled        = true
      ssl_mode            = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    }
    password_validation_policy {
      enable_password_policy = true
      min_length             = 12
      complexity             = "COMPLEXITY_DEFAULT"
    }
    database_flags {
      name  = "max_connections"
      value = "100"
    }
    database_flags {
      name  = "log_statement"
      value = "all"
    }
    database_flags {
      name  = "log_duration"
      value = "on"
    }
    database_flags {
      name  = "log_line_prefix"
      value = "%m [%p] %l %u %d %r %a %t %v %c "
    }
    user_labels = {
      "${var.label_key}" = local.label_value
    }
  }
}

resource "google_sql_database" "hydroserver_db" {
  name     = "hydroserver"
  instance = google_sql_database_instance.hydroserver_db_instance.name
}

resource "random_password" "hydroserver_db_user_password" {
  length           = 15
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "-_~."
}

resource "random_string" "hydroserver_db_user_password_prefix" {
  length           = 1
  upper            = true
  lower            = true
  numeric          = false
  special          = false
}

resource "google_sql_user" "hydroserver_db_user" {
  name     = "hsdbadmin"
  instance = google_sql_database_instance.hydroserver_db_instance.name
  password = "${random_string.hydroserver_db_user_password_prefix.result}${random_password.hydroserver_db_user_password.result}"
}

# -------------------------------------------------- #
# HydroServer GCP Cloud SQL Database Connection      #
# -------------------------------------------------- #

resource "google_secret_manager_secret" "hydroserver_database_url" {
  secret_id = "hydroserver-database-url-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_database_url_version" {
  secret      = google_secret_manager_secret.hydroserver_database_url.id
  secret_data = "postgresql://${google_sql_user.hydroserver_db_user.name}:${google_sql_user.hydroserver_db_user.password}@/${google_sql_database.hydroserver_db.name}?host=/cloudsql/${google_sql_database_instance.hydroserver_db_instance.connection_name}"
}

resource "random_password" "hydroserver_api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "google_secret_manager_secret" "hydroserver_api_secret_key" {
  secret_id = "hydroserver-api-secret-key-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_api_secret_key_version" {
  secret      = google_secret_manager_secret.hydroserver_api_secret_key.id
  secret_data = random_password.hydroserver_api_secret_key.result
}
