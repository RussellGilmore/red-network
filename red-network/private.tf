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
