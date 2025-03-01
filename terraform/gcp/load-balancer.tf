# ---------------------------------
# Cloud CDN Backend Service
# ---------------------------------

resource "google_compute_backend_service" "cloudrun_backend" {
  name                  = "hydroserver-api-${var.instance}-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.security_policy.id
  timeout_sec           = 30

  backend {
    group = google_compute_region_network_endpoint_group.api_neg.id
  }
}

# ---------------------------------
# Cloud CDN Backend Buckets
# ---------------------------------

resource "google_compute_backend_bucket" "static_bucket_backend" {
  name       = "hydroserver-${var.instance}-static-bucket"
  bucket_name = google_storage_bucket.static_bucket.name
  enable_cdn  = true
}

resource "google_compute_backend_bucket" "media_bucket_backend" {
  name       = "hydroserver-${var.instance}-media-bucket"
  bucket_name = google_storage_bucket.media_bucket.name
  enable_cdn  = true
}

resource "google_compute_backend_bucket" "data_mgmt_bucket_backend" {
  name       = "hydroserver-${var.instance}-data-mgmt-app-bucket"
  bucket_name = google_storage_bucket.data_mgmt_app_bucket.name
  enable_cdn  = true
}


# ---------------------------------
# URL Map
# ---------------------------------

resource "google_compute_url_map" "url_map" {
  name = "hydroserver-api-${var.instance}-url-map"
  default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.self_link

    path_rule {
      paths   = ["/api/*", "/admin/*", "/accounts/*"]
      service = google_compute_backend_service.cloudrun_backend.self_link
    }
    path_rule {
      paths   = ["/static/*"]
      service = google_compute_backend_bucket.static_bucket_backend.self_link
    }
    path_rule {
      paths   = ["/photos/*"]
      service = google_compute_backend_bucket.media_bucket_backend.self_link
    }
    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.data_mgmt_bucket_backend.self_link
    }
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = "hydroserver-${var.instance}-https-proxy"
  url_map = google_compute_url_map.url_map.id
  ssl_certificates = [data.google_compute_ssl_certificate.ssl_certificate.id]

  lifecycle {
    ignore_changes = [ssl_certificates]
  }
}

data "google_compute_ssl_certificate" "ssl_certificate" {
  name = var.ssl_certificate_name
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "hydroserver-${var.instance}-https-forwarding"
  ip_address            = google_compute_global_address.ip_address.id
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ---------------------------------
# HTTP Redirect to HTTPS
# ---------------------------------

resource "google_compute_url_map" "http_redirect_url_map" {
  name = "hydroserver-${var.instance}-http-redirect-url-map"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
    https_redirect         = true
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "hydroserver-${var.instance}-http-proxy"
  url_map = google_compute_url_map.http_redirect_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "hydroserver-${var.instance}-http-forwarding"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  ip_address = google_compute_global_address.ip_address.address
  port_range = "80"
}

# ---------------------------------
# Global Static IP Address
# ---------------------------------

resource "google_compute_global_address" "ip_address" {
  name = "hydroserver-${var.instance}-ip"
}
