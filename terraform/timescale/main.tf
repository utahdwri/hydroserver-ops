terraform {
  required_providers {
    timescale = {
      source  = "timescale/timescale"
      version = "~> 1.1.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "timescale" {
  project_id = var.project_id
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "instance" {}
variable "project_id" {}
variable "access_key" {}
variable "secret_key" {}

resource "timescale_service" "hydroserver_timescale" {
  name        = "hydroserver-${var.instance}"
  milli_cpu   = 500
  memory_gb   = 2
  region_code = "us-east-1"

  lifecycle {
    prevent_destroy = true
  }
}
