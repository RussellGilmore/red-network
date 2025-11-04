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
