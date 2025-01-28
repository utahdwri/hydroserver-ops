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

variable "instance" {
  description = "The name of this HydroServer instance."
  type        = string
}
variable "region" {
  description = "The AWS region this HydroServer instance will be deployed in."
  type        = string
}
variable "hydroserver_version" {
  description = "The version of HydroServer to deploy."
  type        = string
  default     = "latest"
}
variable "tag_key" {
  description = "The key of the AWS tag that will be attached to this HydroServer instance."
  type        = string
  default     = "HydroServerInstance"
}
variable "tag_value" {
  description = "The value of the AWS tag that will be attached to this HydroServer instance."
  type        = string
  default     = ""
}

locals {
  tag_value = var.tag_value != "" ? var.tag_value : var.instance
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "hydroserver_vpc" {
  filter {
    name   = "tag:Name"
    values = ["hydroserver-${var.instance}"]
  }
}

data "aws_subnets" "hydroserver_app_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.hydroserver_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["hydroserver-private-app-${var.instance}-*"]
  }
}

data "aws_subnets" "hydroserver_app_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.hydroserver_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["hydroserver-public-app-${var.instance}-*"]
  }
}
