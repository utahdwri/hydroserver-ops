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
      image_identifier = "${aws_ecr_repository.api_repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
        runtime_environment_secrets = {
          DATABASE_URL         = aws_secretsmanager_secret.rds_database_url.arn
          SECRET_KEY           = aws_secretsmanager_secret.api_secret_key.arn
        }
        runtime_environment_variables = {
          DEPLOYED             = "True"
          DEPLOYMENT_BACKEND   = "aws"
          PROXY_BASE_URL       = "https://www.example.com"
          STATIC_BUCKET_NAME   = aws_s3_bucket.static_bucket.bucket
          MEDIA_BUCKET_NAME    = aws_s3_bucket.media_bucket.bucket
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

  # network_configuration {
  #   egress_configuration {
  #     egress_type = "VPC"
  #     vpc_connector_arn = aws_apprunner_vpc_connector.rds_connector.arn
  #   }
  # }

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

# TODO AWS indicates this setup should allow App Runner to be reachable while RDS is not, but it isn't working. App Runner is unreachable with VPC connector attached.

# # ---------------------------------
# # App Runner Security Group
# # ---------------------------------

# resource "aws_security_group" "app_runner_sg" {
#   name        = "hydroserver-${var.instance}-app-runner-sg"
#   vpc_id      = aws_vpc.rds_vpc.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "${var.tag_key}" = local.tag_value
#   }
# }


# # ---------------------------------
# # App Runner VPC Connector for RDS
# # ---------------------------------

# resource "aws_apprunner_vpc_connector" "rds_connector" {
#   vpc_connector_name = "hydroserver-${var.instance}"
#   security_groups = [aws_security_group.app_runner_sg.id]
#   subnets = [
#     aws_subnet.rds_subnet_a.id,
#     aws_subnet.rds_subnet_b.id
#   ]

#   tags = {
#     "${var.tag_key}" = local.tag_value
#   }
# }


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

resource "aws_iam_policy" "app_runner_secrets_policy" {
  name  = "hydroserver-${var.instance}-app-runner-secrets-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.rds_database_url.arn,
          aws_secretsmanager_secret.api_secret_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_secrets_policy_attachment" {
  name       = "hydroserver-${var.instance}-app-runner-secrets-access-policy-attachment"
  policy_arn = aws_iam_policy.app_runner_secrets_policy.arn
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
