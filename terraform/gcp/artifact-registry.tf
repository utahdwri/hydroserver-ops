# ---------------------------------
# GCP Artifact Registry
# ---------------------------------

resource "google_artifact_registry_repository" "api_repository" {
  provider      = google
  project       = data.google_project.gcp_project.project_id
  location      = var.region
  repository_id = var.instance
  format        = "DOCKER"

  labels = {
    "${var.label_key}" = local.label_value
  }
}
