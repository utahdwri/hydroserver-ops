# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service                  #
# -------------------------------------------------- #

# Enable Cloud Run API
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

# Enable Container Registry API
resource "google_project_service" "container_registry" {
  service = "containerregistry.googleapis.com"
}

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
# HydroServer GCP Cloud Run Service Public Access    #
# -------------------------------------------------- #

resource "google_cloud_run_service_iam_member" "hydroserver_api_public_access" {
  service  = google_cloud_run_service.hydroserver_api.name
  location = google_cloud_run_service.hydroserver_api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
