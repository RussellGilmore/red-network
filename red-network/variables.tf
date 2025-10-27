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
