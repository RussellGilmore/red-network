# Red Network

**Requirements:**

1. Terraform 1.13.5
2. Trivy >= 0.67.2

Trivy can be installed via Homebrew on macOS with the command:

```bash
brew install aquasecurity/trivy/trivy
```

## [![Red Network Module](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml/badge.svg?branch=main)](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml)

A VPC Network module designed to be practical for casual use.

## Features

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.14.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.28.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.28.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/eip) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/nat_gateway) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/route_table_association) | resource |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.s3_private](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.s3_public](https://registry.terraform.io/providers/hashicorp/aws/6.28.0/docs/resources/vpc_endpoint_route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to the resources | `map(string)` | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Set the project name. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Set the appropriate AWS region. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnets to create. Each subnet should specify name, cidr\_block, availability\_zone, and type (public/private) | <pre>map(object({<br/>    name              = string<br/>    cidr_block        = string<br/>    availability_zone = string<br/>    type              = string<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_has_public_subnets"></a> [has\_public\_subnets](#output\_has\_public\_subnets) | Boolean indicating if the VPC has any public subnets |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the Internet Gateway (if public subnets exist) |
| <a name="output_nat_gateway_id"></a> [nat\_gateway\_id](#output\_nat\_gateway\_id) | ID of the NAT Gateway (if public subnets exist) |
| <a name="output_nat_gateway_public_ip"></a> [nat\_gateway\_public\_ip](#output\_nat\_gateway\_public\_ip) | Public IP address of the NAT Gateway (if public subnets exist) |
| <a name="output_private_route_table_id"></a> [private\_route\_table\_id](#output\_private\_route\_table\_id) | ID of the private route table |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | ID of the public route table (if public subnets exist) |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_s3_vpc_endpoint_id"></a> [s3\_vpc\_endpoint\_id](#output\_s3\_vpc\_endpoint\_id) | ID of the S3 VPC Endpoint |
| <a name="output_s3_vpc_endpoint_prefix_list_id"></a> [s3\_vpc\_endpoint\_prefix\_list\_id](#output\_s3\_vpc\_endpoint\_prefix\_list\_id) | Prefix list ID of the S3 VPC Endpoint (useful for security groups) |
| <a name="output_subnet_arns"></a> [subnet\_arns](#output\_subnet\_arns) | Map of subnet names to their ARNs |
| <a name="output_subnet_availability_zones"></a> [subnet\_availability\_zones](#output\_subnet\_availability\_zones) | Map of subnet names to their availability zones |
| <a name="output_subnet_cidrs"></a> [subnet\_cidrs](#output\_subnet\_cidrs) | Map of subnet names to their CIDR blocks |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet names to their IDs |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
