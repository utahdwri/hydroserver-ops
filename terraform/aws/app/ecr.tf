# -------------------------------------------------- #
# Amazon ECR Repository                              #
# -------------------------------------------------- #

resource "aws_ecr_repository" "hydroserver_api_repository" {
  name         = "hydroserver-api-${var.instance}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# VPC Endpoints for ECR                              #
# -------------------------------------------------- #

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id             = data.aws_vpc.hydroserver_vpc.id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = data.aws_subnets.hydroserver_app_subnets.ids
  security_group_ids = [aws_security_group.ecr_sg.id]

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id             = data.aws_vpc.hydroserver_vpc.id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = data.aws_subnets.hydroserver_app_subnets.ids
  security_group_ids = [aws_security_group.ecr_sg.id]

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# AWS HydroServer ECR Security Group                 #
# -------------------------------------------------- #

resource "aws_security_group" "ecr_sg" {
  name        = "hydroserver-ecr-sg-${var.instance}"
  description = "Security group for ECR to allow VPC traffic."
  vpc_id      = data.aws_vpc.hydroserver_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.hydroserver_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}
