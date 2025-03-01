# ---------------------------------
# VPC for RDS and App Runner
# ---------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "hydroserver-${var.instance}"
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# Private Subnet for RDS
# ---------------------------------

resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "hydroserver-${var.instance}-private-subnet-az1"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "hydroserver-${var.instance}-private-subnet-az2"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_db_subnet_group" "private_subnet_group" {
  name        = "hydroserver-${var.instance}-private-subnet-group"
  subnet_ids  = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
}


# ---------------------------------
# Public Subnet for App Runner
# ---------------------------------

resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "hydroserver-${var.instance}-public-subnet-az1"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "hydroserver-${var.instance}-public-subnet-az2"
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# Internet Gateway (App Runner)
# ---------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "hydroserver-${var.instance}-igw"
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# NAT Gateway (RDS)
# ---------------------------------

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "hydroserver-${var.instance}-nat-gateway"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_eip" "nat_eip_az2" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway_az2" {
  allocation_id = aws_eip.nat_eip_az2.id
  subnet_id     = aws_subnet.public_subnet_az2.id

  tags = {
    Name = "hydroserver-${var.instance}-nat-gateway-az2"
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# Route Tables (RDS)
# ---------------------------------

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "hydroserver-${var.instance}-private-route-table"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_route_table" "private_route_table_az2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_az2.id
  }

  tags = {
    Name = "hydroserver-${var.instance}-private-route-table-az2"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_route_table_association" "private_route_association_az1" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_association_az2" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_route_table_az2.id
}


# ---------------------------------
# Route Tables (App Runner)
# ---------------------------------

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "hydroserver-${var.instance}-public-route-table"
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_route_table_association" "public_route_association_az1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_association_az2" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}
