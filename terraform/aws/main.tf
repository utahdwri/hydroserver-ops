terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {}
  required_version = ">= 1.10.0"
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
variable "proxy_base_url" {
  description = "The URL HydroServer will be served from."
  type        = string
  default     = "https://www.example.com"
}
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate HydroServer will use."
  type        = string
}
variable "database_url" {
  description = "A database connection for HydroServer to use."
  type        = string
  sensitive   = true
  default     = ""
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
  domain_match   = regex("https?://([^/]+)", var.proxy_base_url)
  domain         = replace(local.domain_match[0], "www.", "")
  admin_email    = "hs-admin@${local.domain}"
  accounts_email = "no-reply@${local.domain}"
  tag_value      = var.tag_value != "" ? var.tag_value : var.instance
}

data "aws_caller_identity" "current" {}
