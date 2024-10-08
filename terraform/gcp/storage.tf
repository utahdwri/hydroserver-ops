# ------------------------------------------------ #
# HydroServer GCS Buckets                          #
# ------------------------------------------------ #

resource "google_storage_bucket" "hydroserver_storage_bucket" {
  name     = "hydroserver-storage-${var.instance}-${data.google_client_config.current.project}"
  location = var.region
}
