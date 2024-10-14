# -------------------------------------------------- #
# Google Cloud CDN Configuration for Cloud Run       #
# -------------------------------------------------- #

resource "google_compute_global_address" "default_ip" {
  name = "hydroserver-ip"
}

resource "google_compute_health_check" "default_health_check" {
  name                = "hydroserver-health-check"
  check_interval_sec  = 10
  timeout_sec         = 4
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port        = 8080
    request_path = "/"
  }
}

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name               = "hydroserver-neg"
  network_endpoint_type = "serverless"
  region            = var.region

  network_endpoints {
    port    = 8080
    serverless_endpoint {
      service = google_cloud_run_service.hydroserver_api.id
    }
  }
}

resource "google_compute_backend_service" "default_backend" {
  name                    = "hydroserver-backend"
  load_balancing_scheme   = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }

  health_checks = [google_compute_health_check.default_health_check.id]

  cdn_policy {
    cache_key_policy {
      include_host          = true
      include_protocol      = true
      include_query_string  = true
    }
    signed_url_cache_max_age_sec = 3600
  }
}

resource "google_compute_url_map" "default_url_map" {
  name            = "hydroserver-url-map"
  default_service = google_compute_backend_service.default_backend.id
}

resource "google_compute_target_http_proxy" "default_proxy" {
  name    = "hydroserver-http-proxy"
  url_map = google_compute_url_map.default_url_map.id
}

resource "google_compute_global_forwarding_rule" "default_rule" {
  name       = "hydroserver-forwarding-rule"
  target     = google_compute_target_http_proxy.default_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.default_ip.address
}
