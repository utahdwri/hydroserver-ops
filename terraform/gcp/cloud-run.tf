# ---------------------------------
# GCP Cloud Run Web Service
# ---------------------------------

resource "google_cloud_run_v2_service" "api" {
  name                = "hydroserver-api-${var.instance}"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = false

  depends_on = [
    google_secret_manager_secret_version.database_url_version,
    google_secret_manager_secret_version.smtp_url_version,
    google_secret_manager_secret_version.api_secret_key_version
  ]

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${data.google_project.gcp_project.project_id}/${var.instance}/hydroserver-api-services:latest"
      command = ["sh", "-c"]
      args    = ["gunicorn --bind 0.0.0.0:8000 --workers 3 hydroserver.wsgi:application"]

      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }

      ports {
        container_port = 8000
      }

      volume_mounts {
        name      = "cloudsql"
        mount_path = "/cloudsql"
      }

      dynamic "env" {
        for_each = {
          DEFAULT_SUPERUSER_EMAIL    = google_secret_manager_secret.default_admin_email.id
          DEFAULT_SUPERUSER_PASSWORD = google_secret_manager_secret.default_admin_password.id
          DATABASE_URL               = google_secret_manager_secret.database_url.id
          SMTP_URL                   = google_secret_manager_secret.smtp_url.id
          SECRET_KEY                 = google_secret_manager_secret.api_secret_key.id
        }
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = {
          USE_CLOUD_SQL_AUTH_PROXY  = "true"
          DEPLOYED                  = "True"
          DEPLOYMENT_BACKEND        = "gcp"
          STATIC_BUCKET_NAME        = google_storage_bucket.static_bucket.name
          MEDIA_BUCKET_NAME         = google_storage_bucket.media_bucket.name
          PROXY_BASE_URL            = var.proxy_base_url
          DEBUG                     = ""
          DEFAULT_FROM_EMAIL        = local.accounts_email
          ACCOUNT_SIGNUP_ENABLED    = ""
          ACCOUNT_OWNERSHIP_ENABLED = ""
          SOCIALACCOUNT_SIGNUP_ONLY = ""
        }
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    service_account = google_service_account.cloud_run_service_account.email

    dynamic "volumes" {
      for_each = length(google_sql_database_instance.db_instance) > 0 ? [google_sql_database_instance.db_instance[0].connection_name] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [volumes.value]
        }
      }
    }

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    labels = {
      "${var.label_key}" = local.label_value
    }
  }

  lifecycle {
    ignore_changes = [
      "template[0].containers[0].resources",
      "template[0].scaling"
    ]
  }
}

resource "google_compute_region_network_endpoint_group" "api_neg" {
  name                  = "hydroserver-api-${var.instance}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.api.name
  }
}

resource "google_secret_manager_secret" "smtp_url" {
  secret_id = "hydroserver-${var.instance}-api-smtp-url"
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

resource "google_secret_manager_secret_version" "smtp_url_version" {
  secret      = google_secret_manager_secret.smtp_url.id
  secret_data = "smtp://127.0.0.1:1025"

  lifecycle {
    ignore_changes = [secret_data]
  }
}


# ---------------------------------
# GCP Cloud Run Init Service
# ---------------------------------

resource "google_cloud_run_v2_job" "hydroserver_init" {
  name     = "hydroserver-init-${var.instance}"
  location = var.region
  deletion_protection  = false

  template {
    template {
      containers {
        image = "${var.region}-docker.pkg.dev/${data.google_project.gcp_project.project_id}/${var.instance}/hydroserver-api-services:latest"
        command = ["/bin/sh", "-c"]
        args    = [<<EOT
        set -e
        python manage.py migrate &&
        python manage.py setup_admin_user &&
        python manage.py load_default_data &&
        python manage.py collectstatic --noinput --clear
        EOT
        ]

        resources {
          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }

        env {
          name = "DEFAULT_SUPERUSER_EMAIL"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.default_admin_email.id
              version = "latest"
            }
          }
        }

        env {
          name = "DEFAULT_SUPERUSER_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.default_admin_password.id
              version = "latest"
            }
          }
        }

        env {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.database_url.id
              version = "latest"
            }
          }
        }

        env {
          name = "SECRET_KEY"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.api_secret_key.id
              version = "latest"
            }
          }
        }

        env {
          name  = "USE_CLOUD_SQL_AUTH_PROXY"
          value = "true"
        }
        env {
          name  = "DEPLOYED"
          value = "True"
        }
        env {
          name  = "DEPLOYMENT_BACKEND"
          value = "gcp"
        }
        env {
          name  = "LOAD_DEFAULT_DATA"
          value = "False"
        }
        env {
          name  = "STATIC_BUCKET_NAME"
          value = google_storage_bucket.static_bucket.name
        }
        env {
          name  = "MEDIA_BUCKET_NAME"
          value = google_storage_bucket.media_bucket.name
        }
      }

      service_account = google_service_account.cloud_run_service_account.email
      max_retries = 0

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.db_instance[0].connection_name]
        }
      }
    }
  }

  labels = {
    "${var.label_key}" = local.label_value
  }
}


# ---------------------------------
# Default Admin Credentials
# ---------------------------------

resource "random_password" "admin_password" {
  length      = 20
  lower       = true
  min_lower   = 1
  upper       = true
  min_upper   = 1
  numeric     = true
  min_numeric = 1
  special     = true
  min_special = 1
}

resource "google_secret_manager_secret" "default_admin_email" {
  secret_id = "hydroserver-${var.instance}-default-admin-email"
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

resource "google_secret_manager_secret_version" "default_admin_email_version" {
  secret      = google_secret_manager_secret.default_admin_email.id
  secret_data = local.admin_email

  lifecycle {
    ignore_changes = [secret_data]
  }
}

resource "google_secret_manager_secret" "default_admin_password" {
  secret_id = "hydroserver-${var.instance}-default-admin-password"
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

resource "google_secret_manager_secret_version" "default_admin_password_version" {
  secret      = google_secret_manager_secret.default_admin_password.id
  secret_data = random_password.admin_password.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}


# ---------------------------------
# GCP Cloud Run Service Account
# ---------------------------------

resource "google_service_account" "cloud_run_service_account" {
  account_id   = "hydroserver-api-${var.instance}"
  display_name = "HydroServer Cloud Run Service Account - ${var.instance}"
  project      = data.google_project.gcp_project.project_id
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.api.location
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_member" "cloud_run_sql_access" {
  project = data.google_project.gcp_project.project_id
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = {
    "default_admin_email"    = google_secret_manager_secret.default_admin_email.id,
    "default_admin_password" = google_secret_manager_secret.default_admin_password.id,
    "database_url"           = google_secret_manager_secret.database_url.id,
    "smtp_url"               = google_secret_manager_secret.smtp_url.id,
    "api_secret_key"         = google_secret_manager_secret.api_secret_key.id
  }
  project   = data.google_project.gcp_project.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = data.google_project.gcp_project.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_storage_bucket_access" {
  for_each = toset([
    google_storage_bucket.static_bucket.name,
    google_storage_bucket.media_bucket.name,
  ])
  bucket = each.value
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}
