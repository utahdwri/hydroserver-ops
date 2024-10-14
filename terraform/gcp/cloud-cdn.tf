# -------------------------------------------------- #
# Google Cloud CDN Configuration for Cloud Run      #
# -------------------------------------------------- #

resource "google_compute_global_address" "default" {
  name = "hydroserver-api-address-${var.instance}"
}

resource "google_compute_network_endpoint_group" "cloud_run_neg" {
  name               = "cloud-run-neg-${var.instance}"
  network_endpoint_type = "serverless"
  region             = var.region

  endpoint {
    url = google_cloud_run_service.hydroserver_api.status[0].url
  }
}

resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "cloud-run-backend-${var.instance}"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_network_endpoint_group.cloud_run_neg.id
  }

  health_checks = [google_compute_health_check.default.id]
  timeout_sec  = 10
  port_name    = "http"

  enable_cdn = true  # Enable CDN
}

resource "google_compute_health_check" "default" {
  name                = "health-check-${var.instance}"
  check_interval_sec  = 10
  timeout_sec         = 4
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port = 8080
    request_path = "/health"  # Adjust if you have a different health check endpoint
  }
}
