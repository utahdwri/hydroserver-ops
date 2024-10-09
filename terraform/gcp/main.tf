terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = var.bucket
    prefix = var.prefix
  }
  required_version = ">= 1.2.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "bucket" {}
variable "prefix" {}
variable "instance" {}
variable "project_id" {}
variable "region" {}

data "google_client_config" "current" {}
