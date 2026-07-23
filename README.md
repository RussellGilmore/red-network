# Red Network

## [![Red Network Module](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml/badge.svg?branch=main)](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml)

**Requirements:**

1. Terraform 1.14.6
2. Trivy >= 0.68.2

Trivy can be installed via Homebrew on macOS with the command:

```bash
brew install aquasecurity/trivy/trivy
```

A practical AWS VPC module with first-class support for hub-and-spoke
topologies and **centralized NAT** — share one NAT gateway across many VPCs
via a Transit Gateway instead of paying for one per VPC.

## Why this module

Most VPC modules stop at "make me a VPC." Red Network goes further: spoke
VPCs can skip their own NAT gateway entirely and route outbound traffic
through a hub VPC's shared NAT over a Transit Gateway. At roughly $32/month
per NAT gateway, that difference adds up fast once you have more than one
VPC.

## Security posture

- Public IP assignment is scoped to subnets you explicitly declare as
  `type = "public"`; private subnets never auto-assign
- VPC Flow Logs are available opt-in via `enable_flow_logs` (CloudWatch,
  configurable retention and traffic type) — off by default to avoid
  imposing cost, on when you want the visibility
- An S3 Gateway VPC Endpoint keeps S3 traffic off the public internet
- Scanned with Trivy and gitleaks on every commit; integration-tested with
  Terratest across baseline, hub-and-spoke, and public-only topologies

## Features

- VPC with DNS hostnames and resolution
- Flexible subnet layout via a single `subnets` map (public, private, or both)
- Internet Gateway provisioned automatically when public subnets exist
- NAT Gateway with Elastic IP for private subnet egress, or skip it entirely
  with `create_nat_gateway = false` for public-only VPCs (no NAT cost)
- S3 Gateway VPC Endpoint with route table associations
- Optional Transit Gateway creation for hub-and-spoke topologies
- Optional Transit Gateway attachment with automatic private-subnet selection
- Cross-VPC routing via configurable CIDR-based Transit Gateway routes
- Centralized NAT — spoke VPCs route outbound traffic through a hub VPC's
  shared NAT via the Transit Gateway
- Opt-in VPC Flow Logs to CloudWatch
- Configurable tags with project and orchestrator metadata

## Usage

A VPC with public and private subnets — see
[`examples/complete`](./examples/complete):

```hcl
provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "RussellGilmore/red-network/aws"

  project_name = "my-project"
  vpc_name     = "my-project-vpc"
  vpc_cidr     = "10.0.0.0/16"

  subnets = {
    public-1a = {
      name              = "public-1a"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      type              = "public"
    }
    private-1a = {
      name              = "private-1a"
      cidr_block        = "10.0.11.0/24"
      availability_zone = "us-east-1a"
      type              = "private"
    }
  }
}
```

### Hub-and-spoke with centralized NAT

The hub owns the Transit Gateway and a NAT gateway; each spoke attaches to
the hub's TGW and sets `use_centralized_nat = true` to route its private
subnets' outbound traffic through the hub instead of provisioning its own
NAT. See [`examples/hub-and-spoke`](./examples/hub-and-spoke) for the full
two-VPC configuration.

### Public-only VPC (no NAT cost)

For bastion or build hosts that only need an Internet Gateway and no private
egress, set `create_nat_gateway = false` to skip the NAT gateway entirely.
See [`examples/public-only`](./examples/public-only).

### VPC Flow Logs

Set `enable_flow_logs = true` to capture flow logs to CloudWatch. The module
creates the log group, IAM role, and flow log for you; retention
(`flow_logs_retention_days`), traffic type (`flow_logs_traffic_type`), and
log group name (`flow_logs_log_group_name`) are all configurable.

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.47.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.47.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_transit_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_centralized_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.s3_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.s3_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to apply to the resources | `map(string)` | `{}` | no |
| <a name="input_attach_to_transit_gateway"></a> [attach\_to\_transit\_gateway](#input\_attach\_to\_transit\_gateway) | Whether to attach this VPC to a Transit Gateway | `bool` | `false` | no |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | Whether to create a NAT gateway for private subnet outbound internet access. Defaults to true (created when public subnets exist). Set to false for public-only VPCs (e.g. bastion or build hosts) that have no private subnets needing egress, avoiding the NAT gateway hourly + data processing cost. Ignored when use\_centralized\_nat is true. | `bool` | `true` | no |
| <a name="input_create_transit_gateway"></a> [create\_transit\_gateway](#input\_create\_transit\_gateway) | Whether to create a new Transit Gateway | `bool` | `false` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VPC Flow Logs to CloudWatch. When true, the module creates a CloudWatch log group, an IAM role, and the flow log itself. | `bool` | `false` | no |
| <a name="input_flow_logs_log_group_name"></a> [flow\_logs\_log\_group\_name](#input\_flow\_logs\_log\_group\_name) | Name of the CloudWatch log group for VPC flow logs. When empty, defaults to /aws/vpc-flow-logs/<vpc\_name>. Only used when enable\_flow\_logs is true. | `string` | `""` | no |
| <a name="input_flow_logs_retention_days"></a> [flow\_logs\_retention\_days](#input\_flow\_logs\_retention\_days) | Retention period in days for the flow logs CloudWatch log group. Only used when enable\_flow\_logs is true. | `number` | `30` | no |
| <a name="input_flow_logs_traffic_type"></a> [flow\_logs\_traffic\_type](#input\_flow\_logs\_traffic\_type) | Type of traffic to capture in flow logs: ALL, ACCEPT, or REJECT. | `string` | `"ALL"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Set the project name. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnets to create. Each subnet should specify name, cidr\_block, availability\_zone, and type (public/private) | <pre>map(object({<br/>    name              = string<br/>    cidr_block        = string<br/>    availability_zone = string<br/>    type              = string<br/>  }))</pre> | n/a | yes |
| <a name="input_transit_gateway_asn"></a> [transit\_gateway\_asn](#input\_transit\_gateway\_asn) | Amazon side ASN for the Transit Gateway | `number` | `64512` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | ID of an existing Transit Gateway to attach to (required if attach\_to\_transit\_gateway is true and create\_transit\_gateway is false) | `string` | `""` | no |
| <a name="input_transit_gateway_name"></a> [transit\_gateway\_name](#input\_transit\_gateway\_name) | Name for the Transit Gateway (only used if create\_transit\_gateway is true) | `string` | `""` | no |
| <a name="input_transit_gateway_routes"></a> [transit\_gateway\_routes](#input\_transit\_gateway\_routes) | List of CIDR blocks to route through the Transit Gateway (e.g., other VPC CIDRs) | `list(string)` | `[]` | no |
| <a name="input_use_centralized_nat"></a> [use\_centralized\_nat](#input\_use\_centralized\_nat) | If true, this VPC will NOT create its own NAT gateway. Instead, a default route (0.0.0.0/0) on private subnets will point to the Transit Gateway, expecting a hub VPC to provide NAT. Only applies when attach\_to\_transit\_gateway is true. | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_has_public_subnets"></a> [has\_public\_subnets](#output\_has\_public\_subnets) | Boolean indicating if the VPC has any public subnets |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the Internet Gateway (if public subnets exist) |
| <a name="output_nat_gateway_id"></a> [nat\_gateway\_id](#output\_nat\_gateway\_id) | ID of the NAT Gateway (if created — not present when using centralized NAT) |
| <a name="output_nat_gateway_public_ip"></a> [nat\_gateway\_public\_ip](#output\_nat\_gateway\_public\_ip) | Public IP address of the NAT Gateway (if created — not present when using centralized NAT) |
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
| <a name="output_transit_gateway_arn"></a> [transit\_gateway\_arn](#output\_transit\_gateway\_arn) | ARN of the Transit Gateway (if created) |
| <a name="output_transit_gateway_attachment_id"></a> [transit\_gateway\_attachment\_id](#output\_transit\_gateway\_attachment\_id) | ID of the Transit Gateway VPC Attachment (if attached) |
| <a name="output_transit_gateway_id"></a> [transit\_gateway\_id](#output\_transit\_gateway\_id) | ID of the Transit Gateway (if created) |
| <a name="output_using_centralized_nat"></a> [using\_centralized\_nat](#output\_using\_centralized\_nat) | Boolean indicating if this VPC uses centralized NAT via Transit Gateway |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
