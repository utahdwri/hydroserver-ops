terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {
    bucket = var.backend_bucket_name
    region = var.region
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

variable "instance" {}
variable "backend_bucket_name" {}
variable "region" {}

data "aws_caller_identity" "current" {}
