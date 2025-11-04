locals {
  # Detect if any public subnets exist
  has_public_subnets = length([for s in var.subnets : s if s.type == "public"]) > 0

  # Get the first public subnet for NAT Gateway placement
  first_public_subnet = local.has_public_subnets ? [for s in var.subnets : s if s.type == "public"][0] : null

  # Separate subnets by type
  public_subnets  = { for k, v in var.subnets : k => v if v.type == "public" }
  private_subnets = { for k, v in var.subnets : k => v if v.type == "private" }
}
