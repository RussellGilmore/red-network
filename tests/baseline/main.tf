variable "project_name" {
  description = "Set the project name."
  type        = string
}

variable "region" {
  description = "Set the appropriate AWS region."
  type        = string
}

module "red-network" {
  source = "../red-network"

  project_name = var.project_name
  region       = var.region
  vpc_name = "${var.project_name}-vpc"
  vpc_cidr = "10.0.0.0/16"

  subnets = {
    public-1a = {
      name              = "${var.project_name}-public-subnet-1a"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "${var.region}a"
      type              = "public"
    }
    public-1b = {
      name              = "${var.project_name}-public-subnet-1b"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "${var.region}b"
      type              = "public"
    }
    private-1a = {
      name              = "${var.project_name}-private-subnet-1a"
      cidr_block        = "10.0.11.0/24"
      availability_zone = "${var.region}a"
      type              = "private"
    }
    private-1b = {
      name              = "${var.project_name}-private-subnet-1b"
      cidr_block        = "10.0.12.0/24"
      availability_zone = "${var.region}b"
      type              = "private"
    }
  }

  additional_tags = var.additional_tags
}

# Example outputs to use in other modules
output "vpc_id" {
  description = "VPC ID for use in other modules"
  value       = module.red-network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for load balancers, etc."
  value       = module.red-network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for application servers, databases, etc."
  value       = module.red-network.private_subnet_ids
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP for whitelisting"
  value       = module.red-network.nat_gateway_public_ip
}
