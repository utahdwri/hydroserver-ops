# -------------------------------------------------- #
# Google Cloud Load Balancer with CDN for Cloud Run   #
# -------------------------------------------------- #

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "cloud-run-neg-${var.instance}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_service.hydroserver_api.name
  }
}

resource "google_compute_global_forwarding_rule" "http_lb_forwarding_rule" {
  name        = "http-forwarding-rule-${var.instance}"
  load_balancing_scheme = "EXTERNAL"
  port_range  = "80"
  target      = google_compute_target_http_proxy.http_proxy.id
}

resource "google_compute_url_map" "http_lb_url_map" {
  name            = "http-url-map-${var.instance}"
  default_service = google_compute_backend_service.default_backend.id
}

resource "google_compute_backend_service" "default_backend" {
  name                  = "default-backend-${var.instance}"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  cdn_policy {
    # Enable Google Cloud CDN on the backend service
    cache_mode = "CACHE_ALL_STATIC"
    signed_url_cache_max_age_sec = 3600
  }
  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-lb-proxy-${var.instance}"
  url_map = google_compute_url_map.http_lb_url_map.id
}

resource "google_compute_global_address" "http_lb_ip" {
  name = "http-lb-ip-${var.instance}"
}

output "http_lb_ip_address" {
  value = google_compute_global_address.http_lb_ip.address
}
