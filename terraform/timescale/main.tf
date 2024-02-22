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
