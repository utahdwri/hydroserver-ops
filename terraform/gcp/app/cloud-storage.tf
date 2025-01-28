# -------------------------------------------------- #
# HydroServer API Storage Bucket                     #
# -------------------------------------------------- #

resource "google_storage_bucket" "hydroserver_storage_bucket" {
  name          = "hydroserver-storage-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = false
  uniform_bucket_level_access = false
}

resource "google_storage_bucket_iam_member" "storage_bucket_public_access" {
  bucket = google_storage_bucket.hydroserver_storage_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# -------------------------------------------------- #
# HydroServer Data Management App Bucket             #
# -------------------------------------------------- #

resource "google_storage_bucket" "hydroserver_data_mgmt_app_bucket" {
  name          = "hydroserver-data-mgmt-app-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  uniform_bucket_level_access = false

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket_iam_member" "data_mgmt_app_bucket_public_access" {
  bucket = google_storage_bucket.hydroserver_data_mgmt_app_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# -------------------------------------------------- #
# Placeholder index.html File                        #
# -------------------------------------------------- #

resource "google_storage_bucket_object" "hydroserver_data_mgmt_app_default_index" {
  name   = "index.html"
  bucket = google_storage_bucket.hydroserver_data_mgmt_app_bucket.name
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
