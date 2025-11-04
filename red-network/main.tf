# Contains the main resource block for creating the Red Instance

# Provider configuration with default tags
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Orchestrator = "Terraform"
      Artifact     = "Red-Instance"
      Project      = var.project_name
    }
  }
}

####################################################################################################
# VPC
####################################################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.additional_tags,
    {
      Name = var.vpc_name
    }
  )
}

####################################################################################################
# Subnets
####################################################################################################

resource "aws_subnet" "subnets" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = merge(
    var.additional_tags,
    {
      Name = each.value.name
      Type = each.value.type
    }
  )
}

####################################################################################################
# Internet Gateway (only if public subnets exist)
####################################################################################################

resource "aws_internet_gateway" "main" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

####################################################################################################
# Elastic IP for NAT Gateway (only if public subnets exist)
####################################################################################################

resource "aws_eip" "nat" {
  count = local.has_public_subnets ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

####################################################################################################
# NAT Gateway (only if public subnets exist)
####################################################################################################

resource "aws_nat_gateway" "main" {
  count = local.has_public_subnets ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.subnets[local.first_public_subnet.name].id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

####################################################################################################
# Route Tables
####################################################################################################

# Public Route Table (only if public subnets exist)
resource "aws_route_table" "public" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-public-rt"
      Type = "public"
    }
  )
}

# Route to Internet Gateway for public route table
resource "aws_route" "public_internet" {
  count = local.has_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-private-rt"
      Type = "private"
    }
  )
}

# Route to NAT Gateway for private route table (only if public subnets exist)
resource "aws_route" "private_nat" {
  count = local.has_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

####################################################################################################
# Route Table Associations
####################################################################################################

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private.id
}

####################################################################################################
# VPC Endpoints
####################################################################################################

# S3 VPC Endpoint (Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-s3-endpoint"
    }
  )
}

# Associate S3 endpoint with route tables
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count = local.has_public_subnets ? 1 : 0

  route_table_id  = aws_route_table.public[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
