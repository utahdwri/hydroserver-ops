terraform {
  backend "gcs" {}
  required_version = ">= 1.2.0"
}

variable "instance" {}
variable "project_id" {}
variable "region" {}
