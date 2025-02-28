# ---------------------------------
# RDS PostgreSQL Database
# ---------------------------------

resource "aws_db_instance" "rds_db_instance" {
  count = var.database_url == "" ? 1 : 0

  identifier                 = "hydroserver-${var.instance}"
  engine                     = "postgres"
  engine_version             = "15"
  instance_class             = "db.t4g.micro"

  storage_type               = "gp2"
  storage_encrypted          = true
  allocated_storage          = 20
  max_allocated_storage      = 100

  publicly_accessible                 = false
  db_subnet_group_name                = aws_db_subnet_group.private_subnet_group.name
  iam_database_authentication_enabled = true
  vpc_security_group_ids              = [aws_security_group.rds_sg.id]

  deletion_protection        = true
  apply_immediately          = true
  auto_minor_version_upgrade = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring_role[0].arn

  db_name  = "hydroserver"
  username = "hsdbadmin"
  password = "${random_string.rds_db_user_password_prefix[0].result}${random_password.rds_db_user_password[0].result}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }

  lifecycle {
    ignore_changes = [
      instance_class,
      storage_type,
      allocated_storage,
      max_allocated_storage,
      backup_retention_period,
      backup_window,
      performance_insights_enabled,
      performance_insights_retention_period,
      monitoring_interval
    ]
  }
}

resource "random_password" "rds_db_user_password" {
  count            = var.database_url == "" ? 1 : 0
  length           = 15
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "-_~*"
}

resource "random_string" "rds_db_user_password_prefix" {
  count            = var.database_url == "" ? 1 : 0
  length           = 1
  upper            = true
  lower            = true
  numeric          = false
  special          = false
}


# ---------------------------------
# RDS Security Group
# ---------------------------------

resource "aws_security_group" "rds_sg" {
  name        = "hydroserver-${var.instance}-rds-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    # cidr_blocks     = ["0.0.0.0/0"]  # TODO remove
    # security_groups = [aws_security_group.app_runner_sg.id]
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
# IAM Role for RDS Monitoring
# ---------------------------------

resource "aws_iam_role" "enhanced_monitoring_role" {
  name  = "hydroserver-${var.instance}-enhanced-monitoring-role"
  count = var.database_url == "" ? 1 : 0

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_role_attachment" {
  count      = var.database_url == "" ? 1 : 0
  role       = aws_iam_role.enhanced_monitoring_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


# ---------------------------------
# AWS Secrets Manager
# ---------------------------------

resource "aws_ssm_parameter" "database_url" {
  name        = "/hydroserver-${var.instance}-api/database-url"
  type        = "SecureString"
  value       = var.database_url != "" ? var.database_url : "postgresql://${aws_db_instance.rds_db_instance[0].username}:${random_string.rds_db_user_password_prefix[0].result}${random_password.rds_db_user_password[0].result}@${aws_db_instance.rds_db_instance[0].endpoint}/hydroserver?sslmode=require"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "random_password" "api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "aws_ssm_parameter" "secret_key" {
  name        = "/hydroserver-${var.instance}-api/secret-key"
  type        = "SecureString"
  value       = random_password.api_secret_key.result

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}
