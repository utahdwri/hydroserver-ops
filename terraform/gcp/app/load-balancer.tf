# -------------------------------------------------- #
# Cloud CDN Backend Service                          #
# -------------------------------------------------- #

resource "google_compute_backend_service" "cloudrun_backend" {
  name        = "hydroserver-api-backend-${var.instance}"
  protocol    = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.hydroserver_security_policy.id
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.hydroserver_api_neg.id
  }
}

# -------------------------------------------------- #
# Cloud CDN Backend Bucket - Web Content             #
# -------------------------------------------------- #

resource "google_compute_backend_bucket" "data_mgmt_bucket_backend" {
  name       = "hydroserver-${var.instance}-data-mgmt-bucket"
  bucket_name = google_storage_bucket.hydroserver_data_mgmt_app_bucket.name
  enable_cdn  = true
}

# -------------------------------------------------- #
# Cloud CDN Backend Bucket - Static/Media Content    #
# -------------------------------------------------- #

resource "google_compute_backend_bucket" "storage_bucket_backend" {
  name       = "hydroserver-${var.instance}-storage-bucket"
  bucket_name = google_storage_bucket.hydroserver_storage_bucket.name
  enable_cdn  = true
}

# -------------------------------------------------- #
# URL Map                                            #
# -------------------------------------------------- #

resource "google_compute_url_map" "hydroserver_url_map" {
  name            = "hydroserver-api-url-map-${var.instance}"
  default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.self_link

    path_rule {
      paths   = ["/api/*", "/admin/*"]
      service = google_compute_backend_service.cloudrun_backend.self_link
    }
    path_rule {
      paths   = ["/static/*", "/photos/*"]
      service = google_compute_backend_bucket.storage_bucket_backend.self_link
    }
  }
}

# -------------------------------------------------- #
# HTTPS Proxy for HTTPS Traffic                     #
# -------------------------------------------------- #

resource "google_compute_target_https_proxy" "https_proxy" {
  name    = "hydroserver-https-proxy-${var.instance}"
  url_map = google_compute_url_map.hydroserver_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.temporary_ssl_cert.id]

  lifecycle {
    ignore_changes = [ssl_certificates]
  }
}

resource "google_compute_managed_ssl_certificate" "temporary_ssl_cert" {
  name = "temp-ssl-cert-${var.instance}"
  managed {
    domains = ["hydroserver.example.com"]
  }
}

# -------------------------------------------------- #
# Global Forwarding Rule for HTTPS Traffic           #
# -------------------------------------------------- #

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = "hydroserver-api-https-forwarding-${var.instance}"
  ip_address            = google_compute_global_address.hydroserver_ip_address.id
  target                = google_compute_target_https_proxy.https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# -------------------------------------------------- #
# URL Map for HTTP Redirect to HTTPS                 #
# -------------------------------------------------- #

resource "google_compute_url_map" "http_redirect_url_map" {
  name = "hydroserver-http-redirect-url-map-${var.instance}"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
    https_redirect         = true
  }
}

# -------------------------------------------------- #
# HTTP Proxy for HTTP to HTTPS Redirect              #
# -------------------------------------------------- #

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "hydroserver-http-proxy-${var.instance}"
  url_map = google_compute_url_map.http_redirect_url_map.self_link
}

# -------------------------------------------------- #
# Global Forwarding Rule for HTTP Traffic (Redirect) #
# -------------------------------------------------- #

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "hydroserver-api-http-forwarding-${var.instance}"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  ip_address = google_compute_global_address.hydroserver_ip_address.address
  port_range = "80"
}

# -------------------------------------------------- #
# Global Static IP Address                           #
# -------------------------------------------------- #

resource "google_compute_global_address" "hydroserver_ip_address" {
  name = "hydroserver-ip-${var.instance}"
}
