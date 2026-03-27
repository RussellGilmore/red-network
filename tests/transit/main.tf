variable "project_name" {
  description = "Set the project name."
  type        = string
}

variable "region" {
  description = "Set the appropriate AWS region."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

####################################################################################################
# Hub VPC — Owns the Transit Gateway and provides shared NAT
####################################################################################################

module "hub-network" {
  source = "../../red-network"

  project_name = var.project_name
  region       = var.region
  vpc_name     = "${var.project_name}-hub-vpc"
  vpc_cidr     = "10.1.0.0/16"

  subnets = {
    hub-public-1a = {
      name              = "${var.project_name}-hub-public-1a"
      cidr_block        = "10.1.1.0/24"
      availability_zone = "${var.region}a"
      type              = "public"
    }
    hub-private-1a = {
      name              = "${var.project_name}-hub-private-1a"
      cidr_block        = "10.1.11.0/24"
      availability_zone = "${var.region}a"
      type              = "private"
    }
    hub-private-1b = {
      name              = "${var.project_name}-hub-private-1b"
      cidr_block        = "10.1.12.0/24"
      availability_zone = "${var.region}b"
      type              = "private"
    }
  }

  # Transit Gateway — this VPC owns it
  create_transit_gateway    = true
  transit_gateway_name      = "${var.project_name}-tgw"
  attach_to_transit_gateway = true
  transit_gateway_routes    = ["10.2.0.0/16"]

  additional_tags = var.additional_tags
}

####################################################################################################
# Spoke VPC — Attaches to the hub's Transit Gateway, uses centralized NAT
####################################################################################################

module "spoke-network" {
  source = "../../red-network"

  project_name = var.project_name
  region       = var.region
  vpc_name     = "${var.project_name}-spoke-vpc"
  vpc_cidr     = "10.2.0.0/16"

  subnets = {
    spoke-public-1a = {
      name              = "${var.project_name}-spoke-public-1a"
      cidr_block        = "10.2.1.0/24"
      availability_zone = "${var.region}a"
      type              = "public"
    }
    spoke-private-1a = {
      name              = "${var.project_name}-spoke-private-1a"
      cidr_block        = "10.2.11.0/24"
      availability_zone = "${var.region}a"
      type              = "private"
    }
  }

  # Transit Gateway — attach to hub's TGW
  attach_to_transit_gateway = true
  transit_gateway_id        = module.hub-network.transit_gateway_id
  transit_gateway_routes    = ["10.1.0.0/16"]

  # Use the hub's NAT gateway for private subnet internet access
  use_centralized_nat = true

  additional_tags = var.additional_tags
}

####################################################################################################
# Outputs
####################################################################################################

# Hub outputs
output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = module.hub-network.vpc_id
}

output "hub_private_subnet_ids" {
  description = "Hub private subnet IDs"
  value       = module.hub-network.private_subnet_ids
}

output "hub_nat_gateway_id" {
  description = "Hub NAT Gateway ID (shared NAT)"
  value       = module.hub-network.nat_gateway_id
}

output "hub_private_route_table_id" {
  description = "Hub private route table ID"
  value       = module.hub-network.private_route_table_id
}

# Transit Gateway outputs
output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = module.hub-network.transit_gateway_id
}

output "hub_tgw_attachment_id" {
  description = "Hub TGW attachment ID"
  value       = module.hub-network.transit_gateway_attachment_id
}

output "spoke_tgw_attachment_id" {
  description = "Spoke TGW attachment ID"
  value       = module.spoke-network.transit_gateway_attachment_id
}

# Spoke outputs
output "spoke_vpc_id" {
  description = "Spoke VPC ID"
  value       = module.spoke-network.vpc_id
}

output "spoke_public_subnet_ids" {
  description = "Spoke public subnet IDs"
  value       = module.spoke-network.public_subnet_ids
}

output "spoke_private_subnet_ids" {
  description = "Spoke private subnet IDs"
  value       = module.spoke-network.private_subnet_ids
}

output "spoke_nat_gateway_id" {
  description = "Spoke NAT Gateway ID (should be null when using centralized NAT)"
  value       = module.spoke-network.nat_gateway_id
}

output "spoke_using_centralized_nat" {
  description = "Whether the spoke is using centralized NAT"
  value       = module.spoke-network.using_centralized_nat
}

output "spoke_private_route_table_id" {
  description = "Spoke private route table ID"
  value       = module.spoke-network.private_route_table_id
}
