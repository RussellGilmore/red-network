####################################################################################################
# Transit Gateway (only if create_transit_gateway is true)
####################################################################################################

resource "aws_ec2_transit_gateway" "main" {
  count = var.create_transit_gateway ? 1 : 0

  amazon_side_asn                 = var.transit_gateway_asn
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  auto_accept_shared_attachments  = "disable"

  tags = merge(
    var.additional_tags,
    {
      Name = var.transit_gateway_name != "" ? var.transit_gateway_name : "${var.vpc_name}-tgw"
    }
  )
}

####################################################################################################
# Transit Gateway VPC Attachment (when attaching to a TGW)
####################################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  count = local.effective_attach_to_tgw ? 1 : 0

  transit_gateway_id = local.effective_transit_gateway_id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = local.private_subnet_ids

  dns_support = "enable"

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.vpc_name}-tgw-attachment"
    }
  )

  depends_on = [aws_ec2_transit_gateway.main]
}

####################################################################################################
# Transit Gateway Routes — Private Route Table
####################################################################################################

# Route cross-VPC CIDRs through the Transit Gateway on the private route table
resource "aws_route" "private_tgw" {
  count = local.effective_attach_to_tgw ? length(var.transit_gateway_routes) : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.transit_gateway_routes[count.index]
  transit_gateway_id     = local.effective_transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}

####################################################################################################
# Transit Gateway Routes — Public Route Table
####################################################################################################

# Route cross-VPC CIDRs through the Transit Gateway on the public route table
resource "aws_route" "public_tgw" {
  count = local.effective_attach_to_tgw && local.has_public_subnets ? length(var.transit_gateway_routes) : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = var.transit_gateway_routes[count.index]
  transit_gateway_id     = local.effective_transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.main]
}
