# Contains the main resource block for creating the Red Instance

# Provider configuration with default tags
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Orchestrator = "Terraform"
      Artifact     = "Red-Network"
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
