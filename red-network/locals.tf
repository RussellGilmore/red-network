locals {
  # Detect if any public subnets exist
  has_public_subnets = length([for s in var.subnets : s if s.type == "public"]) > 0

  # Get the first public subnet for NAT Gateway placement
  first_public_subnet_key = local.has_public_subnets ? [for k, v in var.subnets : k if v.type == "public"][0] : null

  # Separate subnets by type
  public_subnets  = { for k, v in var.subnets : k => v if v.type == "public" }
  private_subnets = { for k, v in var.subnets : k => v if v.type == "private" }

  # Whether this VPC should create its own NAT gateway
  # Skipped when using centralized NAT (spoke VPCs route through TGW to hub NAT)
  create_nat_gateway = local.has_public_subnets && !var.use_centralized_nat

  # Determine whether to attach to a Transit Gateway
  # If creating a TGW, implicitly attach to it
  effective_attach_to_tgw = var.create_transit_gateway || var.attach_to_transit_gateway

  # Determine the effective TGW ID (either created or passed in)
  effective_transit_gateway_id = var.create_transit_gateway ? aws_ec2_transit_gateway.main[0].id : var.transit_gateway_id

  # Whether private subnets exist (needed for TGW attachment validation)
  has_private_subnets = length([for s in var.subnets : s if s.type == "private"]) > 0

  # Private subnet IDs for TGW attachment
  private_subnet_ids = [for k, v in var.subnets : aws_subnet.subnets[k].id if v.type == "private"]
}
