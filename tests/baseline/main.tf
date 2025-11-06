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
}
