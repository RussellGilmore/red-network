####################################################################################################
# Required Variables
variable "project_name" {
  description = "Set the project name."
  type        = string
}

variable "region" {
  description = "Set the appropriate AWS region."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "subnets" {
  description = "Map of subnets to create. Each subnet should specify name, cidr_block, availability_zone, and type (public/private)"
  type = map(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    type              = string
  }))

  validation {
    condition = alltrue([
      for k, v in var.subnets : contains(["public", "private"], v.type)
    ])
    error_message = "Subnet type must be either 'public' or 'private'."
  }

  validation {
    condition = alltrue([
      for k, v in var.subnets : can(cidrhost(v.cidr_block, 0))
    ])
    error_message = "All subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

####################################################################################################
# Optional Red Instance Variables
variable "additional_tags" {
  description = "Additional tags to apply to the resources"
  type        = map(string)
  default     = {}
}

####################################################################################################
# Transit Gateway Variables
variable "create_transit_gateway" {
  description = "Whether to create a new Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_name" {
  description = "Name for the Transit Gateway (only used if create_transit_gateway is true)"
  type        = string
  default     = ""
}

variable "transit_gateway_asn" {
  description = "Amazon side ASN for the Transit Gateway"
  type        = number
  default     = 64512
}

variable "attach_to_transit_gateway" {
  description = "Whether to attach this VPC to a Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "ID of an existing Transit Gateway to attach to (required if attach_to_transit_gateway is true and create_transit_gateway is false)"
  type        = string
  default     = ""

  validation {
    condition     = var.transit_gateway_id == "" || can(regex("^tgw-", var.transit_gateway_id))
    error_message = "Transit Gateway ID must start with 'tgw-' if provided."
  }
}

variable "transit_gateway_routes" {
  description = "List of CIDR blocks to route through the Transit Gateway (e.g., other VPC CIDRs)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.transit_gateway_routes : can(cidrhost(cidr, 0))
    ])
    error_message = "All Transit Gateway route CIDR blocks must be valid IPv4 CIDR blocks."
  }
}

####################################################################################################
# Centralized NAT Variables
variable "use_centralized_nat" {
  description = "If true, this VPC will NOT create its own NAT gateway. Instead, a default route (0.0.0.0/0) on private subnets will point to the Transit Gateway, expecting a hub VPC to provide NAT. Only applies when attach_to_transit_gateway is true."
  type        = bool
  default     = false
}
