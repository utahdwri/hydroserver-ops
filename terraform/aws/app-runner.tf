# ---------------------------------
# AWS App Runner Service
# ---------------------------------

resource "aws_apprunner_service" "api" {
  service_name = "hydroserver-api-${var.instance}"

  depends_on = [
    aws_s3_bucket.static_bucket,
    aws_s3_bucket.media_bucket,
    null_resource.db_wait
  ]
  
  instance_configuration {
    instance_role_arn = aws_iam_role.app_runner_service_role.arn
  }

  source_configuration {
    image_repository {
      image_identifier      = "${aws_ecr_repository.api_repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
        runtime_environment_secrets = {
          DATABASE_URL               = aws_ssm_parameter.database_url.arn
          SMTP_URL                   = aws_ssm_parameter.smtp_url.arn
          SECRET_KEY                 = aws_ssm_parameter.secret_key.arn
          AWS_CLOUDFRONT_KEY_ID      = aws_ssm_parameter.signing_key_id.arn
          AWS_CLOUDFRONT_KEY         = aws_ssm_parameter.signing_key.arn
          PROXY_BASE_URL             = aws_ssm_parameter.proxy_base_url.arn
          DEBUG                      = aws_ssm_parameter.debug_mode.arn
          DEFAULT_SUPERUSER_EMAIL    = aws_ssm_parameter.admin_email.arn
          DEFAULT_SUPERUSER_PASSWORD = aws_ssm_parameter.admin_password.arn
          DEFAULT_FROM_EMAIL         = aws_ssm_parameter.default_from_email.arn
          ACCOUNT_SIGNUP_ENABLED     = aws_ssm_parameter.account_signup_enabled.arn
          ACCOUNT_OWNERSHIP_ENABLED  = aws_ssm_parameter.account_ownership_enabled.arn
          SOCIALACCOUNT_SIGNUP_ONLY  = aws_ssm_parameter.socialaccount_signup_only.arn
        }
        runtime_environment_variables = {
          DEPLOYED                   = "True"
          DEPLOYMENT_BACKEND         = "aws"
          STATIC_BUCKET_NAME         = aws_s3_bucket.static_bucket.bucket
          MEDIA_BUCKET_NAME          = aws_s3_bucket.media_bucket.bucket
        }
      }
    }

    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_access_role.arn
    }
  }

  health_check_configuration {
    protocol = "TCP"
    interval = 5
    timeout  = 2
    unhealthy_threshold = 2
  }

  network_configuration {
    egress_configuration {
      egress_type = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.vpc_connector.arn
    }
    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "null_resource" "db_wait" {
  count = length(aws_db_instance.rds_db_instance) == 1 ? 1 : 0

  triggers = {
    wait_for_rds = "true"
  }
}


# ---------------------------------
# App Runner Security Group
# ---------------------------------

resource "aws_security_group" "app_runner_sg" {
  name        = "hydroserver-${var.instance}-app-runner-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# App Runner VPC Connector for RDS
# ---------------------------------

resource "aws_apprunner_vpc_connector" "vpc_connector" {
  vpc_connector_name = "hydroserver-${var.instance}"
  security_groups = [aws_security_group.app_runner_sg.id]
  subnets = [
    aws_subnet.private_subnet_az1.id,
    aws_subnet.private_subnet_az2.id
  ]

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# App Runner Instance Role
# ---------------------------------

resource "aws_iam_role" "app_runner_service_role" {
  name = "hydroserver-${var.instance}-app-runner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_runner_rds_policy" {
  name  = "hydroserver-${var.instance}-app-runner-rds-access-policy"
  count = var.database_url == "" ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "rds-db:connect"
        Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.rds_db_instance[0].id}/hsdbadmin"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_rds_policy_attachment" {
  name       = "hydroserver-${var.instance}-app-runner-rds-access-policy-attachment"
  count      = var.database_url == "" ? 1 : 0
  policy_arn = aws_iam_policy.app_runner_rds_policy[0].arn
  roles      = [aws_iam_role.app_runner_service_role.name]
}

resource "aws_iam_policy" "app_runner_ssm_policy" {
  name = "hydroserver-${var.instance}-app-runner-ssm-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/hydroserver-${var.instance}-api/*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_ssm_policy_attachment" {
  name       = "hydroserver-${var.instance}-app-runner-ssm-access-policy-attachment"
  policy_arn = aws_iam_policy.app_runner_ssm_policy.arn
  roles      = [aws_iam_role.app_runner_service_role.name]
}

resource "aws_iam_policy" "app_runner_s3_policy" {
  name        = "hydroserver-${var.instance}-app-runner-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.static_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.media_bucket.id}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.static_bucket.id}/*",
          "arn:aws:s3:::${aws_s3_bucket.media_bucket.id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_s3_policy_attachment" {
  name       = "hydroserver-${var.instance}-app-runner-s3-access-policy-attachment"
  policy_arn = aws_iam_policy.app_runner_s3_policy.arn
  roles      = [aws_iam_role.app_runner_service_role.name]
}


# ---------------------------------
# App Runner Access Role
# ---------------------------------

resource "aws_iam_role" "app_runner_access_role" {
  name = "hydroserver-${var.instance}-app-runner-access-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_runner_ecr_access_policy" {
  name = "hydroserver-${var.instance}-app-runner-ecr-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_ecr_access_policy_attachment" {
  name       = "hydroserver-${var.instance}-app-runner-ecr-access-policy-attachment"
  policy_arn = aws_iam_policy.app_runner_ecr_access_policy.arn
  roles      = [aws_iam_role.app_runner_access_role.name]
}


# ---------------------------------
# Default Admin Credentials
# ---------------------------------

resource "random_password" "admin_password" {
  length      = 20
  lower       = true
  min_lower   = 1
  upper       = true
  min_upper   = 1
  numeric     = true
  min_numeric = 1
  special     = true
  min_special = 1
}

resource "aws_ssm_parameter" "admin_email" {
  name      = "/hydroserver-${var.instance}-api/default-admin-email"
  type      = "SecureString"
  value     = local.admin_email

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "admin_password" {
  name      = "/hydroserver-${var.instance}-api/default-admin-password"
  type      = "SecureString"
  value     = random_password.admin_password.result

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

# ---------------------------------
# App Runner Environment Variables
# ---------------------------------

resource "aws_ssm_parameter" "smtp_url" {
  name        = "/hydroserver-${var.instance}-api/smtp-url"
  type        = "SecureString"
  value       = "smtp://127.0.0.1:1025"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "proxy_base_url" {
  name        = "/hydroserver-${var.instance}-api/proxy-base-url"
  type        = "String"
  value       = var.proxy_base_url

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "default_from_email" {
  name        = "/hydroserver-${var.instance}-api/default-from-email"
  type        = "String"
  value       = local.accounts_email

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "account_signup_enabled" {
  name        = "/hydroserver-${var.instance}-api/account-signup-enabled"
  type        = "String"
  value       = "True"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "account_ownership_enabled" {
  name        = "/hydroserver-${var.instance}-api/account-ownership-enabled"
  type        = "String"
  value       = "True"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "socialaccount_signup_only" {
  name        = "/hydroserver-${var.instance}-api/socialaccount-signup-only"
  type        = "String"
  value       = "False"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_ssm_parameter" "debug_mode" {
  name        = "/hydroserver-${var.instance}-api/debug-mode"
  type        = "String"
  value       = "True"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}
