# Red Network

## [![Red Network Module](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml/badge.svg?branch=main)](https://github.com/RussellGilmore/red-network/actions/workflows/module-test.yml)

**Requirements:**

1. Terraform 1.14.6
2. Trivy >= 0.68.2

Trivy can be installed via Homebrew on macOS with the command:

```bash
brew install aquasecurity/trivy/trivy
```

A VPC Network module designed to be practical for casual use.

## Features

-   VPC with DNS hostname and DNS resolution support
-   Flexible subnet configuration via a single map variable (public, private, or
    both)
-   Internet Gateway provisioned automatically when public subnets exist
-   NAT Gateway with Elastic IP for private subnet outbound internet access
-   S3 Gateway VPC Endpoint with route table associations
-   Optional Transit Gateway creation for hub-and-spoke network topologies
-   Optional Transit Gateway VPC attachment with automatic private subnet
    selection
-   Cross-VPC routing via configurable CIDR-based Transit Gateway routes on both
    public and private route tables
-   Centralized NAT gateway sharing — spoke VPCs can skip local NAT and route
    outbound internet traffic through a hub VPC's NAT via the Transit Gateway
-   Trivy security scanning via pre-commit hooks
-   Terratest integration tests for baseline and transit gateway deployments
-   Configurable tags with default project and orchestrator metadata

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
