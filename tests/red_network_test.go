package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

var (
	awsRegion   = getAWSRegion()
	projectName = fmt.Sprintf("red-network-%s", strings.ToLower(random.UniqueId()))
	opts        = &terraform.Options{
		TerraformDir: "./baseline",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": projectName,
		},
	}
)

// Destroy the terraform code
func destroyTerraform(t *testing.T) {
	terraform.Destroy(t, opts)
}

// Helper function to get AWS region from multiple possible env vars and because I can't make up my mind
func getAWSRegion() string {
	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = os.Getenv("AWS_DEFAULT_REGION")
	}
	if region == "" {
		region = "us-east-1" // fallback default
	}
	return region
}

// A baseline deployment to ensure bare minimum functionality
func testBaseline(t *testing.T) {
	t.Parallel()

	// Deploy using Terraform
	test_structure.RunTestStage(t, "setup", func() {
		_, err := terraform.InitAndApplyE(t, opts)
		if err != nil {
			terraform.Apply(t, opts)
		}
	})

	// Get Public and Private Subnet IDs
	test_structure.RunTestStage(t, "validate", func() {
		publicSubnetIDs := terraform.OutputList(t, opts, "public_subnet_ids")
		privateSubnetIDs := terraform.OutputList(t, opts, "private_subnet_ids")

		if len(publicSubnetIDs) != 2 {
			t.Fatalf("Expected 2 public subnets, but got %d", len(publicSubnetIDs))
		}

		if len(privateSubnetIDs) != 2 {
			t.Fatalf("Expected 2 private subnets, but got %d", len(privateSubnetIDs))
		}
	})
}

func TestRedNetwork(t *testing.T) {
	defer test_structure.RunTestStage(t, "terraform_destroy", func() {
		destroyTerraform(t)
	})

	test_structure.RunTestStage(t, "terraform_init_and_apply", func() {
		testBaseline(t)
	})
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Transit Gateway Test
////////////////////////////////////////////////////////////////////////////////////////////////////

func TestTransitGateway(t *testing.T) {
	transitProjectName := fmt.Sprintf("red-tgw-%s", strings.ToLower(random.UniqueId()))

	transitOpts := &terraform.Options{
		TerraformDir: "./transit",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": transitProjectName,
		},
	}

	// Always clean up
	defer test_structure.RunTestStage(t, "terraform_destroy_transit", func() {
		terraform.Destroy(t, transitOpts)
	})

	// Deploy hub and spoke VPCs with Transit Gateway
	test_structure.RunTestStage(t, "terraform_init_and_apply_transit", func() {
		_, err := terraform.InitAndApplyE(t, transitOpts)
		if err != nil {
			terraform.Apply(t, transitOpts)
		}
	})

	// Validate Transit Gateway resources
	test_structure.RunTestStage(t, "validate_transit", func() {
		// Verify Transit Gateway was created
		tgwID := terraform.Output(t, transitOpts, "transit_gateway_id")
		if tgwID == "" {
			t.Fatal("Expected Transit Gateway ID to be non-empty")
		}
		if !strings.HasPrefix(tgwID, "tgw-") {
			t.Fatalf("Expected Transit Gateway ID to start with 'tgw-', got: %s", tgwID)
		}

		// Verify both VPC attachments were created
		hubAttachmentID := terraform.Output(t, transitOpts, "hub_tgw_attachment_id")
		if hubAttachmentID == "" {
			t.Fatal("Expected Hub TGW attachment ID to be non-empty")
		}
		if !strings.HasPrefix(hubAttachmentID, "tgw-attach-") {
			t.Fatalf("Expected Hub TGW attachment ID to start with 'tgw-attach-', got: %s", hubAttachmentID)
		}

		spokeAttachmentID := terraform.Output(t, transitOpts, "spoke_tgw_attachment_id")
		if spokeAttachmentID == "" {
			t.Fatal("Expected Spoke TGW attachment ID to be non-empty")
		}
		if !strings.HasPrefix(spokeAttachmentID, "tgw-attach-") {
			t.Fatalf("Expected Spoke TGW attachment ID to start with 'tgw-attach-', got: %s", spokeAttachmentID)
		}

		// Verify hub has a NAT gateway (it provides shared NAT)
		hubNatID := terraform.Output(t, transitOpts, "hub_nat_gateway_id")
		if hubNatID == "" {
			t.Fatal("Expected Hub NAT Gateway ID to be non-empty (hub provides shared NAT)")
		}

		// Verify spoke does NOT have a NAT gateway (uses centralized NAT)
		spokeNatID, err := terraform.OutputE(t, transitOpts, "spoke_nat_gateway_id")
		if err == nil && spokeNatID != "" {
			t.Fatalf("Expected Spoke NAT Gateway ID to be empty (using centralized NAT), got: %s", spokeNatID)
		}

		// Verify spoke is using centralized NAT
		spokeCentralizedNat := terraform.Output(t, transitOpts, "spoke_using_centralized_nat")
		if spokeCentralizedNat != "true" {
			t.Fatalf("Expected spoke using_centralized_nat to be true, got: %s", spokeCentralizedNat)
		}

		// Verify both VPCs have private subnets
		hubPrivateSubnets := terraform.OutputList(t, transitOpts, "hub_private_subnet_ids")
		if len(hubPrivateSubnets) != 2 {
			t.Fatalf("Expected 2 hub private subnets, but got %d", len(hubPrivateSubnets))
		}

		spokePrivateSubnets := terraform.OutputList(t, transitOpts, "spoke_private_subnet_ids")
		if len(spokePrivateSubnets) != 1 {
			t.Fatalf("Expected 1 spoke private subnet, but got %d", len(spokePrivateSubnets))
		}

		// Verify spoke has public subnets (for the K3s instance)
		spokePublicSubnets := terraform.OutputList(t, transitOpts, "spoke_public_subnet_ids")
		if len(spokePublicSubnets) != 1 {
			t.Fatalf("Expected 1 spoke public subnet, but got %d", len(spokePublicSubnets))
		}
	})
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Public-Only VPC Test (create_nat_gateway = false)
////////////////////////////////////////////////////////////////////////////////////////////////////

func TestPublicOnlyVPC(t *testing.T) {
	publicProjectName := fmt.Sprintf("red-public-%s", strings.ToLower(random.UniqueId()))

	publicOpts := &terraform.Options{
		TerraformDir: "./public-only",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": publicProjectName,
		},
	}

	// Always clean up
	defer test_structure.RunTestStage(t, "terraform_destroy_public", func() {
		terraform.Destroy(t, publicOpts)
	})

	// Deploy the public-only VPC
	test_structure.RunTestStage(t, "terraform_init_and_apply_public", func() {
		_, err := terraform.InitAndApplyE(t, publicOpts)
		if err != nil {
			terraform.Apply(t, publicOpts)
		}
	})

	// Validate the public-only, no-NAT topology
	test_structure.RunTestStage(t, "validate_public", func() {
		// Exactly one public subnet
		publicSubnetIDs := terraform.OutputList(t, publicOpts, "public_subnet_ids")
		if len(publicSubnetIDs) != 1 {
			t.Fatalf("Expected 1 public subnet, but got %d", len(publicSubnetIDs))
		}

		// No private subnets
		privateSubnetIDs := terraform.OutputList(t, publicOpts, "private_subnet_ids")
		if len(privateSubnetIDs) != 0 {
			t.Fatalf("Expected 0 private subnets, but got %d", len(privateSubnetIDs))
		}

		// Internet Gateway must exist (public subnet needs egress/ingress)
		igwID := terraform.Output(t, publicOpts, "internet_gateway_id")
		if igwID == "" {
			t.Fatal("Expected Internet Gateway ID to be non-empty")
		}
		if !strings.HasPrefix(igwID, "igw-") {
			t.Fatalf("Expected Internet Gateway ID to start with 'igw-', got: %s", igwID)
		}

		// The core assertion: NO NAT gateway was created.
		// outputs.tf returns null for these when create_nat_gateway = false,
		// which terraform surfaces as an empty string.
		natID, err := terraform.OutputE(t, publicOpts, "nat_gateway_id")
		if err == nil && natID != "" {
			t.Fatalf("Expected NAT Gateway ID to be empty (create_nat_gateway = false), got: %s", natID)
		}

		natIP, err := terraform.OutputE(t, publicOpts, "nat_gateway_public_ip")
		if err == nil && natIP != "" {
			t.Fatalf("Expected NAT Gateway public IP to be empty (create_nat_gateway = false), got: %s", natIP)
		}

		// Sanity: module still reports public subnets present
		hasPublic := terraform.Output(t, publicOpts, "has_public_subnets")
		if hasPublic != "true" {
			t.Fatalf("Expected has_public_subnets to be true, got: %s", hasPublic)
		}
	})
}
