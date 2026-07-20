variable "project_name" {
  type    = string
  default = "red-network-example"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

module "red_network" {
  source = "../../"

  project_name             = var.project_name
  vpc_name                 = "${var.project_name}-vpc"
  vpc_cidr                 = "10.0.0.0/16"
  enable_flow_logs         = true
  flow_logs_retention_days = 30

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
}

output "vpc_id" {
  value = module.red_network.vpc_id
}

output "public_subnet_ids" {
  value = module.red_network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.red_network.private_subnet_ids
}

output "nat_gateway_ip" {
  value = module.red_network.nat_gateway_public_ip
}

output "flow_logs_enabled" {
  value = true
}
