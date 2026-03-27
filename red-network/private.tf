####################################################################################################
# Route Tables
####################################################################################################

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

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.private.id
}

####################################################################################################
# Private Subnet Default Routes
####################################################################################################

# Route to NAT Gateway for private subnets (when NOT using centralized NAT)
resource "aws_route" "private_nat" {
  count = local.create_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# Route to Transit Gateway for private subnets (when using centralized NAT)
# This sends all internet-bound traffic from private subnets through the TGW
# to the hub VPC where the shared NAT gateway provides outbound access
resource "aws_route" "private_centralized_nat" {
  count = var.use_centralized_nat && local.effective_attach_to_tgw ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = local.effective_transit_gateway_id
}
