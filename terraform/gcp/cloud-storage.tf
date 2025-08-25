# ---------------------------------
# Static Bucket
# ---------------------------------

resource "google_storage_bucket" "static_bucket" {
  name          = "hydroserver-static-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = false
  uniform_bucket_level_access = false

  labels = {
    "${var.label_key}" = local.label_value
  }
}

resource "google_storage_bucket_iam_member" "static_bucket_public_access" {
  bucket = google_storage_bucket.static_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}


# ---------------------------------
# Media Bucket
# ---------------------------------

resource "google_storage_bucket" "media_bucket" {
  name          = "hydroserver-media-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = false
  uniform_bucket_level_access = false

  labels = {
    "${var.label_key}" = local.label_value
  }
}

resource "google_storage_bucket_iam_member" "media_bucket_public_access" {
  bucket = google_storage_bucket.media_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
