# -------------------------------------------------- #
# Google Cloud CDN Configuration for Cloud Run      #
# -------------------------------------------------- #

resource "google_compute_backend_service" "hydroserver_backend" {
  name                  = "hydroserver-backend-${var.instance}"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_backend_service.hydroserver_service.id
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

resource "google_compute_region_backend_service" "hydroserver_service" {
  name        = "hydroserver-service-backend"
  port_name   = "http"
  protocol    = "HTTP"

  backend {
    group = "projects/${var.project_id}/locations/${google_cloud_run_service.hydroserver_api.location}/services/${google_cloud_run_service.hydroserver_api.name}"
  }
}
