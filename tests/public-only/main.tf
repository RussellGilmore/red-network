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
# Public-Only VPC — single public subnet, no private subnets, no NAT gateway
#
# Exercises create_nat_gateway = false. This is the bastion / build-host pattern:
# a VPC that only needs inbound + egress via the Internet Gateway on a public
# subnet, with no private subnets requiring NAT egress. Asserts that no NAT
# gateway (and no NAT EIP) is created, avoiding the ~$32/mo cost.
####################################################################################################

module "public-only-network" {
  source = "../../red-network"

  project_name = var.project_name
  region       = var.region
  vpc_name     = "${var.project_name}-public-vpc"
  vpc_cidr     = "10.0.0.0/16"

  subnets = {
    public-1a = {
      name              = "${var.project_name}-public-1a"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "${var.region}a"
      type              = "public"
    }
  }

  # The feature under test: skip NAT gateway creation entirely.
  create_nat_gateway = false

  additional_tags = var.additional_tags
}

####################################################################################################
# Outputs
####################################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.public-only-network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.public-only-network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (expected empty)"
  value       = module.public-only-network.private_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID (should be present)"
  value       = module.public-only-network.internet_gateway_id
}

# Should be null when create_nat_gateway = false.
output "nat_gateway_id" {
  description = "NAT Gateway ID (expected null)"
  value       = module.public-only-network.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP (expected null)"
  value       = module.public-only-network.nat_gateway_public_ip
}

output "has_public_subnets" {
  description = "Whether the VPC has public subnets"
  value       = module.public-only-network.has_public_subnets
}
