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
