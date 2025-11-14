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
