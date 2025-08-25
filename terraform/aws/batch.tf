# ---------------------------------
# AWS Batch Init Service
# ---------------------------------

resource "aws_batch_compute_environment" "hydroserver_init_env" {
  compute_environment_name = "hydroserver-init-${var.instance}"
  service_role             = aws_iam_role.batch_service_role.arn
  type                     = "MANAGED"

  compute_resources {
    type          = "FARGATE"
    max_vcpus     = 1
    min_vcpus     = 0
    desired_vcpus = 0
    subnets       = [
      aws_subnet.private_subnet_az1.id,
      aws_subnet.private_subnet_az2.id
    ]
    security_group_ids = [aws_security_group.app_runner_sg.id]
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_batch_job_queue" "hydroserver_init_queue" {
  name                 = "hydroserver-init-${var.instance}"
  state                = "ENABLED"
  priority             = 1

  compute_environments = [aws_batch_compute_environment.hydroserver_init_env.arn]

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_batch_job_definition" "hydroserver_init" {
  name = "hydroserver-init-${var.instance}"
  type = "container"

  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image = "${aws_ecr_repository.api_repository.repository_url}:latest"
    command = ["/bin/sh", "-c", "set -e; python manage.py migrate && python manage.py setup_admin_user && python manage.py load_default_data && python manage.py collectstatic --noinput --clear"]

    resourceRequirements = [
      {
        type  = "VCPU"
        value = "1"
      },
      {
        type  = "MEMORY"
        value = "2048"
      }
    ]

    environment = [
      { name = "DEPLOYED", value = "True" },
      { name = "DEPLOYMENT_BACKEND", value = "aws" },
      { name = "LOAD_DEFAULT_DATA", value = "False" },
      { name = "STATIC_BUCKET_NAME", value = aws_s3_bucket.static_bucket.bucket },
      { name = "MEDIA_BUCKET_NAME", value = aws_s3_bucket.media_bucket.bucket }
    ]

    secrets = [
      { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_url.arn },
      { name = "SECRET_KEY", valueFrom = aws_ssm_parameter.secret_key.arn },
      { name = "DEFAULT_SUPERUSER_EMAIL", valueFrom = aws_ssm_parameter.admin_email.arn },
      { name = "DEFAULT_SUPERUSER_PASSWORD", valueFrom = aws_ssm_parameter.admin_password.arn }
    ]

    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    jobRoleArn = aws_iam_role.app_runner_service_role.arn
  })

  retry_strategy {
    attempts = 1
  }

  timeout {
    attempt_duration_seconds = 3600
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# AWS Batch Service Role
# ---------------------------------

resource "aws_iam_role" "batch_service_role" {
  name = "hydroserver-${var.instance}-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "batch.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_iam_role_policy_attachment" "batch_service_role_attach" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_iam_role_policy" "batch_service_role_ecs_delete" {
  role = aws_iam_role.batch_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSClusterDelete",
        Effect = "Allow",
        Action = [
          "ecs:List*",
          "ecs:Get*",
          "ecs:Describe*",
          "ecs:DeleteCluster"
        ],
        Resource = "*"
      }
    ]
  })
}


# ---------------------------------
# AWS ECS Execution Role
# ---------------------------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "hydroserver-${var.instance}-ecs-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_iam_policy" "ecs_task_execution_ssm_policy" {
  name = "hydroserver-${var.instance}-ecs-task-execution-ssm-access-policy"

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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_ecs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm_policy.arn
}
