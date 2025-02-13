# TODO: Need to figure out how to get VPC Connectors working correctly, but they're not currently working as documented.

# # ---------------------------------
# # VPC for RDS
# # ---------------------------------

# resource "aws_vpc" "rds_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "hydroserver-${var.instance}"
#     "${var.tag_key}" = local.tag_value
#   }
# }


# # ---------------------------------
# # Private Subnets for RDS
# # ---------------------------------

# resource "aws_subnet" "rds_subnet_a" {
#   vpc_id                  = aws_vpc.rds_vpc.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "${var.region}a"
#   map_public_ip_on_launch = true  # TODO false

#   tags = {
#     Name = "hydroserver-${var.instance}-subnet-1"
#     "${var.tag_key}" = local.tag_value
#   }
# }

# resource "aws_subnet" "rds_subnet_b" {
#   vpc_id                  = aws_vpc.rds_vpc.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "${var.region}b"
#   map_public_ip_on_launch = true  # TODO false

#   tags = {
#     Name = "hydroserver-${var.instance}-subnet-2"
#     "${var.tag_key}" = local.tag_value
#   }
# }


# # ---------------------------------
# # RDS Subnet Group
# # ---------------------------------

# resource "aws_db_subnet_group" "rds_subnet_group" {
#   name       = "hydroserver-${var.instance}-db-subnet-group"
#   subnet_ids = [aws_subnet.rds_subnet_a.id, aws_subnet.rds_subnet_b.id]

#   tags = {
#     "${var.tag_key}" = local.tag_value
#   }
# }
