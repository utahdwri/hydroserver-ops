# -------------------------------------------------- #
# Google Cloud CDN Configuration for Cloud Run      #
# -------------------------------------------------- #

resource "google_compute_global_address" "default" {
  name = "hydroserver-api-address-${var.instance}"
}

resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "cloud-run-backend-${var.instance}"
  load_balancing_scheme = "EXTERNAL"
  backend {
    group = google_cloud_run_service.hydroserver_api.status[0].url
  }

health_checks = [google_compute_health_check.default.id]
  timeout_sec  = 10
  port_name    = "http"
  enable_cdn = true
}

resource "google_compute_health_check" "default" {
  name                = "health-check-${var.instance}"
  check_interval_sec  = 10
  timeout_sec         = 4
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port = 8080
    request_path = "/health"
  }
}

resource "google_compute_url_map" "default" {
  name            = "url-map-${var.instance}"
  default_service = google_compute_backend_service.cloud_run_backend.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy-${var.instance}"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "forwarding-rule-${var.instance}"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}
