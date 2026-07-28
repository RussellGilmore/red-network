package test

import (
	"context"
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
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": projectName,
		},
	}
)

// Destroy the terraform code
func destroyTerraform(t *testing.T, ctx context.Context) {
	terraform.DestroyContext(t, ctx, opts)
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
func testBaseline(t *testing.T, ctx context.Context) {
	t.Parallel()

	// Deploy using Terraform
	test_structure.RunTestStage(t, "setup", func() {
		_, err := terraform.InitAndApplyContextE(t, ctx, opts)
		if err != nil {
			terraform.ApplyContext(t, ctx, opts)
		}
	})

	// Get Public and Private Subnet IDs
	test_structure.RunTestStage(t, "validate", func() {
		publicSubnetIDs := terraform.OutputListContext(t, ctx, opts, "public_subnet_ids")
		privateSubnetIDs := terraform.OutputListContext(t, ctx, opts, "private_subnet_ids")

		if len(publicSubnetIDs) != 2 {
			t.Fatalf("Expected 2 public subnets, but got %d", len(publicSubnetIDs))
		}

		if len(privateSubnetIDs) != 2 {
			t.Fatalf("Expected 2 private subnets, but got %d", len(privateSubnetIDs))
		}

		// Verify flow logs were actually created (example sets enable_flow_logs = true)
		flowLogID := terraform.OutputContext(t, ctx, opts, "flow_log_id")
		if flowLogID == "" {
			t.Fatal("Expected a flow log ID, but got empty (flow logs should be enabled)")
		}
		if !strings.HasPrefix(flowLogID, "fl-") {
			t.Fatalf("Expected flow log ID to start with 'fl-', got: %s", flowLogID)
		}
	})
}

func TestRedNetwork(t *testing.T) {
	ctx := t.Context()

	defer test_structure.RunTestStage(t, "terraform_destroy", func() {
		destroyTerraform(t, ctx)
	})

	test_structure.RunTestStage(t, "terraform_init_and_apply", func() {
		testBaseline(t, ctx)
	})
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Transit Gateway Test
////////////////////////////////////////////////////////////////////////////////////////////////////

func TestTransitGateway(t *testing.T) {
	ctx := t.Context()

	transitProjectName := fmt.Sprintf("red-tgw-%s", strings.ToLower(random.UniqueId()))

	transitOpts := &terraform.Options{
		TerraformDir: "../examples/hub-and-spoke",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": transitProjectName,
		},
	}

	// Always clean up
	defer test_structure.RunTestStage(t, "terraform_destroy_transit", func() {
		terraform.DestroyContext(t, ctx, transitOpts)
	})

	// Deploy hub and spoke VPCs with Transit Gateway
	test_structure.RunTestStage(t, "terraform_init_and_apply_transit", func() {
		_, err := terraform.InitAndApplyContextE(t, ctx, transitOpts)
		if err != nil {
			terraform.ApplyContext(t, ctx, transitOpts)
		}
	})

	// Validate Transit Gateway resources
	test_structure.RunTestStage(t, "validate_transit", func() {
		// Verify Transit Gateway was created
		tgwID := terraform.OutputContext(t, ctx, transitOpts, "transit_gateway_id")
		if tgwID == "" {
			t.Fatal("Expected Transit Gateway ID to be non-empty")
		}
		if !strings.HasPrefix(tgwID, "tgw-") {
			t.Fatalf("Expected Transit Gateway ID to start with 'tgw-', got: %s", tgwID)
		}

		// Verify both VPC attachments were created
		hubAttachmentID := terraform.OutputContext(t, ctx, transitOpts, "hub_tgw_attachment_id")
		if hubAttachmentID == "" {
			t.Fatal("Expected Hub TGW attachment ID to be non-empty")
		}
		if !strings.HasPrefix(hubAttachmentID, "tgw-attach-") {
			t.Fatalf("Expected Hub TGW attachment ID to start with 'tgw-attach-', got: %s", hubAttachmentID)
		}

		spokeAttachmentID := terraform.OutputContext(t, ctx, transitOpts, "spoke_tgw_attachment_id")
		if spokeAttachmentID == "" {
			t.Fatal("Expected Spoke TGW attachment ID to be non-empty")
		}
		if !strings.HasPrefix(spokeAttachmentID, "tgw-attach-") {
			t.Fatalf("Expected Spoke TGW attachment ID to start with 'tgw-attach-', got: %s", spokeAttachmentID)
		}

		// Verify hub has a NAT gateway (it provides shared NAT)
		hubNatID := terraform.OutputContext(t, ctx, transitOpts, "hub_nat_gateway_id")
		if hubNatID == "" {
			t.Fatal("Expected Hub NAT Gateway ID to be non-empty (hub provides shared NAT)")
		}

		// Verify spoke does NOT have a NAT gateway (uses centralized NAT)
		spokeNatID, err := terraform.OutputContextE(t, ctx, transitOpts, "spoke_nat_gateway_id")
		if err == nil && spokeNatID != "" {
			t.Fatalf("Expected Spoke NAT Gateway ID to be empty (using centralized NAT), got: %s", spokeNatID)
		}

		// Verify spoke is using centralized NAT
		spokeCentralizedNat := terraform.OutputContext(t, ctx, transitOpts, "spoke_using_centralized_nat")
		if spokeCentralizedNat != "true" {
			t.Fatalf("Expected spoke using_centralized_nat to be true, got: %s", spokeCentralizedNat)
		}

		// Verify both VPCs have private subnets
		hubPrivateSubnets := terraform.OutputListContext(t, ctx, transitOpts, "hub_private_subnet_ids")
		if len(hubPrivateSubnets) != 2 {
			t.Fatalf("Expected 2 hub private subnets, but got %d", len(hubPrivateSubnets))
		}

		spokePrivateSubnets := terraform.OutputListContext(t, ctx, transitOpts, "spoke_private_subnet_ids")
		if len(spokePrivateSubnets) != 1 {
			t.Fatalf("Expected 1 spoke private subnet, but got %d", len(spokePrivateSubnets))
		}

		// Verify spoke has public subnets (for the K3s instance)
		spokePublicSubnets := terraform.OutputListContext(t, ctx, transitOpts, "spoke_public_subnet_ids")
		if len(spokePublicSubnets) != 1 {
			t.Fatalf("Expected 1 spoke public subnet, but got %d", len(spokePublicSubnets))
		}
	})
}

////////////////////////////////////////////////////////////////////////////////////////////////////
// Public-Only VPC Test (create_nat_gateway = false)
////////////////////////////////////////////////////////////////////////////////////////////////////

func TestPublicOnlyVPC(t *testing.T) {
	ctx := t.Context()

	publicProjectName := fmt.Sprintf("red-public-%s", strings.ToLower(random.UniqueId()))

	publicOpts := &terraform.Options{
		TerraformDir: "../examples/public-only",
		Vars: map[string]interface{}{
			"region":       awsRegion,
			"project_name": publicProjectName,
		},
	}

	// Always clean up
	defer test_structure.RunTestStage(t, "terraform_destroy_public", func() {
		terraform.DestroyContext(t, ctx, publicOpts)
	})

	// Deploy the public-only VPC
	test_structure.RunTestStage(t, "terraform_init_and_apply_public", func() {
		_, err := terraform.InitAndApplyContextE(t, ctx, publicOpts)
		if err != nil {
			terraform.ApplyContext(t, ctx, publicOpts)
		}
	})

	// Validate the public-only, no-NAT topology
	test_structure.RunTestStage(t, "validate_public", func() {
		// Exactly one public subnet
		publicSubnetIDs := terraform.OutputListContext(t, ctx, publicOpts, "public_subnet_ids")
		if len(publicSubnetIDs) != 1 {
			t.Fatalf("Expected 1 public subnet, but got %d", len(publicSubnetIDs))
		}

		// No private subnets
		privateSubnetIDs := terraform.OutputListContext(t, ctx, publicOpts, "private_subnet_ids")
		if len(privateSubnetIDs) != 0 {
			t.Fatalf("Expected 0 private subnets, but got %d", len(privateSubnetIDs))
		}

		// Internet Gateway must exist (public subnet needs egress/ingress)
		igwID := terraform.OutputContext(t, ctx, publicOpts, "internet_gateway_id")
		if igwID == "" {
			t.Fatal("Expected Internet Gateway ID to be non-empty")
		}
		if !strings.HasPrefix(igwID, "igw-") {
			t.Fatalf("Expected Internet Gateway ID to start with 'igw-', got: %s", igwID)
		}

		// The core assertion: NO NAT gateway was created.
		// outputs.tf returns null for these when create_nat_gateway = false,
		// which terraform surfaces as an empty string.
		natID, err := terraform.OutputContextE(t, ctx, publicOpts, "nat_gateway_id")
		if err == nil && natID != "" {
			t.Fatalf("Expected NAT Gateway ID to be empty (create_nat_gateway = false), got: %s", natID)
		}

		natIP, err := terraform.OutputContextE(t, ctx, publicOpts, "nat_gateway_public_ip")
		if err == nil && natIP != "" {
			t.Fatalf("Expected NAT Gateway public IP to be empty (create_nat_gateway = false), got: %s", natIP)
		}

		// Sanity: module still reports public subnets present
		hasPublic := terraform.OutputContext(t, ctx, publicOpts, "has_public_subnets")
		if hasPublic != "true" {
			t.Fatalf("Expected has_public_subnets to be true, got: %s", hasPublic)
		}
	})
}
