####################################################################################################
# VPC Outputs
####################################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.main.arn
}

####################################################################################################
# Subnet Outputs
####################################################################################################

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in aws_subnet.subnets : k => v.id }
}

output "subnet_arns" {
  description = "Map of subnet names to their ARNs"
  value       = { for k, v in aws_subnet.subnets : k => v.arn }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for k, v in aws_subnet.subnets : v.id if var.subnets[k].type == "public"]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for k, v in aws_subnet.subnets : v.id if var.subnets[k].type == "private"]
}

output "subnet_cidrs" {
  description = "Map of subnet names to their CIDR blocks"
  value       = { for k, v in aws_subnet.subnets : k => v.cidr_block }
}

output "subnet_availability_zones" {
  description = "Map of subnet names to their availability zones"
  value       = { for k, v in aws_subnet.subnets : k => v.availability_zone }
}

####################################################################################################
# Route Table Outputs
####################################################################################################

output "public_route_table_id" {
  description = "ID of the public route table (if public subnets exist)"
  value       = local.has_public_subnets ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

####################################################################################################
# Internet Gateway Outputs
####################################################################################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway (if public subnets exist)"
  value       = local.has_public_subnets ? aws_internet_gateway.main[0].id : null
}

####################################################################################################
# NAT Gateway Outputs
####################################################################################################

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if created — not present when using centralized NAT)"
  value       = local.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway (if created — not present when using centralized NAT)"
  value       = local.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}

####################################################################################################
# VPC Endpoint Outputs
####################################################################################################

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_vpc_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC Endpoint (useful for security groups)"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

####################################################################################################
# Transit Gateway Outputs
####################################################################################################

output "transit_gateway_id" {
  description = "ID of the Transit Gateway (if created)"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].id : null
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway (if created)"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].arn : null
}

output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway VPC Attachment (if attached)"
  value       = local.effective_attach_to_tgw ? aws_ec2_transit_gateway_vpc_attachment.main[0].id : null
}

####################################################################################################
# Metadata Outputs
####################################################################################################

output "has_public_subnets" {
  description = "Boolean indicating if the VPC has any public subnets"
  value       = local.has_public_subnets
}

output "using_centralized_nat" {
  description = "Boolean indicating if this VPC uses centralized NAT via Transit Gateway"
  value       = var.use_centralized_nat
}
