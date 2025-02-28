# ---------------------------------
# Cloud SQL PostgreSQL Database
# ---------------------------------

resource "google_sql_database_instance" "db_instance" {
  count = var.database_url == "" ? 1 : 0

  name                = "hydroserver-${var.instance}"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true

  settings {
    tier = "db-f1-micro"
    availability_type = "REGIONAL"
    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
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

  lifecycle {
    ignore_changes = [
      settings[0].tier,
      settings[0].database_flags
    ]
  }
}

resource "google_sql_database" "db" {
  count    = var.database_url == "" ? 1 : 0
  name     = "hydroserver"
  instance = google_sql_database_instance.db_instance[0].name
}

resource "random_password" "db_user_password" {
  count            = var.database_url == "" ? 1 : 0
  length           = 15
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "-_~*"
}

resource "random_string" "db_user_password_prefix" {
  count            = var.database_url == "" ? 1 : 0
  length           = 1
  upper            = true
  lower            = true
  numeric          = false
  special          = false
}

resource "google_sql_user" "db_user" {
  count    = var.database_url == "" ? 1 : 0
  name     = "hsdbadmin"
  instance = google_sql_database_instance.db_instance[0].name
  password = "${random_string.db_user_password_prefix[0].result}${random_password.db_user_password[0].result}"
}


# ---------------------------------
# Google Secret Manager
# ---------------------------------

resource "google_secret_manager_secret" "database_url" {
  secret_id = "hydroserver-${var.instance}-api-database-url"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    "${var.label_key}" = local.label_value
  }
}

resource "google_secret_manager_secret_version" "database_url_version" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = var.database_url != "" ? var.database_url : "postgresql://${google_sql_user.db_user[0].name}:${google_sql_user.db_user[0].password}@/${google_sql_database.db[0].name}?host=/cloudsql/${google_sql_database_instance.db_instance[0].connection_name}"

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "random_password" "api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "google_secret_manager_secret" "api_secret_key" {
  secret_id = "hydroserver-${var.instance}-api-secret-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    "${var.label_key}" = local.label_value
  }
}

resource "google_secret_manager_secret_version" "api_secret_key_version" {
  secret      = google_secret_manager_secret.api_secret_key.id
  secret_data = random_password.api_secret_key.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}
