# ------------------------------------------------ #
# HydroServer Google App Engine Service            #
# ------------------------------------------------ #
resource "google_app_engine_standard_app_version" "hydroserver_django_service" {
  service                = "hydroserver-${var.instance}"
  version_id             = "v0"
  runtime                = "python311"
  entrypoint {
    shell = "gunicorn -b :$PORT hydroserver.wsgi"
  }

  # ----------------------------- #
  # Scaling Configuration         #
  # ----------------------------- #

  automatic_scaling {
    max_idle_instances = 1
    min_idle_instances = 0
  }

  # ----------------------------- #
  # Environment Variables         #
  # ----------------------------- #

  env_variables = {
    "ADMIN_EMAIL"              = ""
    "ALLOWED_HOSTS"            = ""
    "AWS_STORAGE_BUCKET_NAME"  = ""
    "DATABASE_URL"             = ""
    "DEBUG"                    = "True"
    "DEPLOYMENT_BACKEND"       = "gcp"
    "DISABLE_ACCOUNT_CREATION" = "False"
    "EMAIL_HOST"               = ""
    "EMAIL_PORT"               = ""
    "EMAIL_HOST_USER"          = ""
    "EMAIL_HOST_PASSWORD"      = ""
    "OAUTH_GOOGLE_CLIENT"      = ""
    "OAUTH_GOOGLE_SECRET"      = ""
    "OAUTH_HYDROSHARE_CLIENT"  = ""
    "OAUTH_HYDROSHARE_SECRET"  = ""
    "OAUTH_ORCID_CLIENT"       = ""
    "OAUTH_ORCID_SECRET"       = ""
    "PROXY_BASE_URL"           = ""
    "SECRET_KEY"               = ""
  }

  handlers {
    url_regex = ".*"
    static_files {
      path = "/"
      upload_path_regex = ".*"
    }
  }
}
