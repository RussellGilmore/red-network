# Contains the main resource block for creating the Red Network

# Main VPC Resource
# Justification: Flow logs are available opt-in via var.enable_flow_logs.
# trivy:ignore:AVD-AWS-0178
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.tags,
    {
      Name = var.vpc_name
    }
  )
}

####################################################################################################
# Subnets
####################################################################################################

# Justification: Public IP assignment is the defining behavior of a subnet the caller has
# explicitly declared as type = "public"; private subnets receive false.
# The caller controls which subnets are public via var.subnets.
# trivy:ignore:AVD-AWS-0164
resource "aws_subnet" "subnets" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = merge(
    local.tags,
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
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"

  tags = merge(
    local.tags,
    {
      Name = "${var.vpc_name}-s3-endpoint"
    }
  )
}
