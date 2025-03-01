terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {}
  required_version = ">= 1.10.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "instance" {
  description = "The name of this HydroServer instance."
  type        = string
}
variable "project_id" {
  description = "The project ID for this HydroServer instance."
  type        = string
}
variable "region" {
  description = "The GCP region this HydroServer instance will be deployed in."
  type        = string
}
variable "hydroserver_version" {
  description = "The version of HydroServer to deploy."
  type        = string
  default     = "latest"
}
variable "proxy_base_url" {
  description = "The URL HydroServer will be served from."
  type        = string
  default     = "https://www.example.com"
}
variable "ssl_certificate_name" {
  description = "The name of the classic SSL certificate HydroServer will use."
  type        = string
}
variable "database_url" {
  description = "A database connection for HydroServer to use."
  type        = string
  sensitive   = true
  default     = ""
}
variable "label_key" {
  description = "The key of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = "hydroserver-instance"
}
variable "label_value" {
  description = "The value of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = ""
}

locals {
  domain_match   = regex("https?://([^/]+)", var.proxy_base_url)
  domain         = replace(local.domain_match[0], "www.", "")
  admin_email    = "hs-admin@${local.domain}"
  accounts_email = "no-reply@${local.domain}"
  label_value    = var.label_value != "" ? var.label_value : var.instance
}

data "google_project" "gcp_project" {
  project_id = var.project_id
}
data "google_client_config" "current" {}
