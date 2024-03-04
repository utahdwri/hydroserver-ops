terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {}
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

variable "instance" {}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "state" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    region = "${var.region}"
    key    = "${var.key}"
  }
}
