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


# ---------------------------------
# Data Management App Bucket
# ---------------------------------

resource "google_storage_bucket" "data_mgmt_app_bucket" {
  name          = "hydroserver-data-mgmt-app-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  uniform_bucket_level_access = false

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  labels = {
    "${var.label_key}" = local.label_value
  }
}

resource "google_storage_bucket_iam_member" "data_mgmt_app_bucket_public_access" {
  bucket = google_storage_bucket.data_mgmt_app_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "data_mgmt_app_default_index" {
  name   = "index.html"
  bucket = google_storage_bucket.data_mgmt_app_bucket.name
  content = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Placeholder Page</title>
</head>
<body>
    <h1>Welcome to HydroServer</h1>
    <p>This is a placeholder page served from Google Cloud Storage.</p>
</body>
</html>
EOF

  cache_control = "no-cache"
}
