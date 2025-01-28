# -------------------------------------------------- #
# AWS HydroServer RDS PostgreSQL Database            #
# -------------------------------------------------- #

resource "aws_db_instance" "hydroserver_db_instance" {

  # Basic Configuration
  identifier            = "hydroserver-${var.instance}"
  engine                = "postgres"
  engine_version        = "15"
  db_name               = "hydroserver"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  publicly_accessible   = false

  # Networking Configuration
  db_subnet_group_name   = aws_db_subnet_group.hydroserver_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.hydroserver_rds_sg.id]

  # High Availability
  multi_az = true

  # Encryption
  storage_encrypted = true

  # Backup Configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring_role.arn

  # Database Credentials
  username = "hsdbadmin"
  password = random_password.hydroserver_db_user_password.result

  # Tags for resource tracking
  tags = {
    "${var.tag_key}" = var.tag_value
  }

  # Lifecycle settings
  lifecycle {
    ignore_changes = [
      instance_class,
      allocated_storage,
      max_allocated_storage
    ]
  }
}

resource "random_password" "hydroserver_db_user_password" {
  length  = 16
  special = false
}

# -------------------------------------------------- #
# AWS HydroServer RDS Security Group                 #
# -------------------------------------------------- #

data "aws_vpc" "hydroserver_vpc" {
  filter {
    name   = "tag:Name"
    values = ["hydroserver-${var.instance}"]
  }
}

data "aws_subnet_ids" "hydroserver_db_subnets" {
  vpc_id = data.aws_vpc.hydroserver_vpc.id
  filter {
    name   = "tag:Name"
    values = ["hydroserver-private-db-${var.instance}-*"]
  }
}

resource "aws_db_subnet_group" "hydroserver_db_subnet_group" {
  name       = "hydroserver-rds-subnet-group-${var.instance}"
  subnet_ids = data.aws_subnet_ids.hydroserver_db_subnets.ids

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_security_group" "hydroserver_rds_sg" {
  name        = "hydroserver-rds-sg-${var.instance}"
  description = "Security group for RDS to allow only internal VPC traffic."

  vpc_id = data.aws_vpc.hydroserver_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.hydroserver_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.hydroserver_vpc.cidr_block]
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# IAM Role for RDS Enhanced Monitoring               #
# -------------------------------------------------- #

resource "aws_iam_role" "enhanced_monitoring_role" {
  name = "hydroserver-enhanced-monitoring-role-${var.instance}"

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
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_role_attachment" {
  role       = aws_iam_role.enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -------------------------------------------------- #
# AWS Secrets Manager for Database Credentials       #
# -------------------------------------------------- #

resource "aws_secretsmanager_secret" "hydroserver_database_url" {
  name = "hydroserver-database-url-${var.instance}"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "hydroserver_database_url_version" {
  secret_id     = aws_secretsmanager_secret.hydroserver_database_url.id
  secret_string = "postgresql://${aws_db_instance.hydroserver_db_instance.username}:${random_password.hydroserver_db_user_password.result}@${aws_db_instance.hydroserver_db_instance.endpoint}/hydroserver?sslmode=require"
}

resource "random_password" "hydroserver_api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "aws_secretsmanager_secret" "hydroserver_api_secret_key" {
  name = "hydroserver-api-secret-key-${var.instance}"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "hydroserver_api_secret_key_version" {
  secret_id     = aws_secretsmanager_secret.hydroserver_api_secret_key.id
  secret_string = random_password.hydroserver_api_secret_key.result
}
