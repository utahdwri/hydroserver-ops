# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service                  #
# -------------------------------------------------- #

resource "google_cloud_run_v2_service" "hydroserver_api" {
  name     = "hydroserver-api-${var.instance}"
  location = var.region
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${data.google_project.gcp_project.project_id}/${var.instance}/hydroserver-api-services:latest"

      resources {
        limits = {
          memory = "512Mi"
        }
      }

      ports {
        container_port = 8000
      }

      volume_mounts {
        name      = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret = "hydroserver-database-url-${var.instance}"
            version  = "latest"
          }
        }
      }

      env {
        name  = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = "hydroserver-api-secret-key-${var.instance}"
            version = "latest"
          }
        }
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
        name  = "USE_CLOUD_SQL_AUTH_PROXY"
        value = "true"
      }
      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.hydroserver_storage_bucket.name
      }
      env {
        name  = "SMTP_URL"
        value = ""
      }
      env {
        name  = "ACCOUNTS_EMAIL"
        value = ""
      }
      env {
        name  = "PROXY_BASE_URL"
        value = ""
      }
      env {
        name  = "ALLOWED_HOSTS"
        value = ""
      }
      env {
        name  = "OAUTH_GOOGLE"
        value = ""
      }
      env {
        name  = "OAUTH_ORCID"
        value = ""
      }
      env {
        name  = "OAUTH_HYDROSHARE"
        value = ""
      }
      env {
        name  = "DEBUG"
        value = ""
      }
    }

    service_account = google_service_account.cloud_run_service_account.email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [data.google_sql_database_instance.hydroserver_db_instance.connection_name]
      }
    }

    labels = {
      "${var.label_key}" = local.label_value
    }
  }
}

resource "google_compute_region_network_endpoint_group" "hydroserver_api_neg" {
  name                  = "hydroserver-api-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.hydroserver_api.name
  }
}

data "google_sql_database_instance" "hydroserver_db_instance" {
  name = "hydroserver-${var.instance}"
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service Account          #
# -------------------------------------------------- #

resource "google_service_account" "cloud_run_service_account" {
  account_id   = "hydroserver-api-${var.instance}"
  display_name = "HydroServer Cloud Run Service Account - ${var.instance}"
  project      = data.google_project.gcp_project.project_id
}

resource "google_project_iam_member" "cloud_run_sql_access" {
  project = data.google_project.gcp_project.project_id
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = toset([
    "hydroserver-database-url-${var.instance}",
    "hydroserver-api-secret-key-${var.instance}",
  ])
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
  bucket = google_storage_bucket.hydroserver_storage_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

# resource "google_cloud_run_service_iam_member" "cloud_run_lb_neg_invoker" {
#   service  = google_cloud_run_v2_service.hydroserver_api.name
#   location = var.region
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:service-${data.google_project.gcp_project.number}@gcp-sa-loadbalancer.iam.gserviceaccount.com"
# }
