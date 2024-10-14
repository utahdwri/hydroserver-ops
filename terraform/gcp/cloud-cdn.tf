# -------------------------------------------------- #
# Google Cloud CDN Configuration for Cloud Run       #
# -------------------------------------------------- #

resource "google_compute_global_address" "hydroserver_lb_ip" {
  name = "hydroserver-lb-ip-${var.instance}"
}


resource "google_compute_backend_service" "hydroserver_backend" {
  name                  = "hydroserver-backend-${var.instance}"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"

  backend {
    group = google_compute_region_network_endpoint_group.hydroserver_neg.id
  }

  enable_cdn = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl      = 3600
    max_ttl          = 86400
    cache_key_policy {
      include_host          = true
      include_protocol      = true
    }
  }
}

resource "google_compute_url_map" "hydroserver_url_map" {
  name            = "hydroserver-url-map-${var.instance}"
  default_service = google_compute_backend_service.hydroserver_backend.id
}

resource "google_compute_target_http_proxy" "hydroserver_http_proxy" {
  name   = "hydroserver-http-proxy-${var.instance}"
  url_map = google_compute_url_map.hydroserver_url_map.id
}

resource "google_compute_global_forwarding_rule" "hydroserver_forwarding_rule" {
  name       = "hydroserver-forwarding-rule-${var.instance}"
  target     = google_compute_target_http_proxy.hydroserver_http_proxy.id
  port_range = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address = google_compute_global_address.hydroserver_ip.address
}

resource "google_compute_global_address" "hydroserver_ip" {
  name = "hydroserver-ip-${var.instance}"
}
