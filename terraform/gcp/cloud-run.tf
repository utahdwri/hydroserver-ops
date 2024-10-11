# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service                  #
# -------------------------------------------------- #

#resource "google_cloud_run_service" "hydroserver_api" {
#  name     = "hydroserver-api-${var.instance}"
#  location = var.region

#  template {
#    spec {
#      containers {
#        image = "gcr.io/cloudrun/hello"
#        resources {
#          limits = {
#            memory = "512Mi"
#          }
#        }
#        ports {
#          container_port = 8080
#        }
#      }
#    }
#  }

#  traffic {
#    percent         = 100
#    latest_revision = true
#  }
#}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service Public Access    #
# -------------------------------------------------- #

#resource "google_cloud_run_service_iam_member" "hydroserver_api_public_access" {
#  service  = google_cloud_run_service.hydroserver_api.name
#  location = google_cloud_run_service.hydroserver_api.location
#  role     = "roles/run.invoker"
#  member   = "allUsers"
#}

resource "google_storage_bucket" "test_bucket" {
  name     = "hydroserver-test-bucket"
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}
