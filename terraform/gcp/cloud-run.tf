# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service                  #
# -------------------------------------------------- #

resource "google_cloud_run_service" "hydroserver_api" {
  name     = "hydroserver-api-${var.instance}"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        resources {
          limits = {
            memory = "512Mi"
          }
        }
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service NEG              #
# -------------------------------------------------- #

resource "google_compute_region_network_endpoint_group" "hydroserver_neg" {
  name                  = "hydroserver-api-neg-${var.instance}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_service.hydroserver_api.name
  }
}
