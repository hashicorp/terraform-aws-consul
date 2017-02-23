package test

import (
	"github.com/gruntwork-io/terratest/packer"
	"github.com/gruntwork-io/terratest"
	"os"
	"log"
	"testing"
	"github.com/gruntwork-io/terratest/shell"
)

// Deploy the given terraform code
func deploy(t *testing.T, terratestOptions *terratest.TerratestOptions) {
	_, err := terratest.Apply(terratestOptions)
	if err != nil {
		t.Fatalf("Failed to apply templates: %s", err.Error())
	}
}

// Use Packer to build the AMI in the given packer template, with the given build name, and return the AMI's ID
func buildAmi(t *testing.T, packerTemplatePath string, packerBuildName string, resourceCollection *terratest.RandomResourceCollection, logger *log.Logger) string {
	branchName := getCurrentBranchName(t, logger)

	options := packer.PackerOptions{
		Template: packerTemplatePath,
		Only: packerBuildName,
		Vars: map[string]string{
			"aws_region": resourceCollection.AwsRegion,
			"blueprint_version": branchName,
		},
	}

	amiId, err := packer.BuildAmi(options, logger)
	if err != nil {
		t.Fatalf("Failed to build AMI for Packer template %s: %s", packerTemplatePath, err.Error())
	}
	if amiId == "" {
		t.Fatalf("Got blank AMI ID after building Packer template %s", packerTemplatePath)
	}

	return amiId
}

// Create the basic RandomResourceCollection for testing the consul-cluster example
func createBaseRandomResourceCollection(t *testing.T) *terratest.RandomResourceCollection {
	resourceCollectionOptions := terratest.NewRandomResourceCollectionOptions()

	randomResourceCollection, err := terratest.CreateRandomResourceCollection(resourceCollectionOptions)
	if err != nil {
		t.Fatalf("Failed to create Random Resource Collection: %s", err.Error())
	}

	return randomResourceCollection
}

// Create the basic TerratestOptions for testing the consul-cluster example
func createBaseTerratestOptions(t *testing.T, testName string, templatePath string, resourceCollection *terratest.RandomResourceCollection) *terratest.TerratestOptions {
	terratestOptions := terratest.NewTerratestOptions()

	terratestOptions.UniqueId = resourceCollection.UniqueId
	terratestOptions.TemplatePath = templatePath
	terratestOptions.TestName = testName

	return terratestOptions
}

// Return the name of the current branch. We need this so that when the Packer build runs gruntwork-install, it uses
// the latest code checked into the branch we're on now and not what's in a published release from before.
func getCurrentBranchName(t *testing.T, logger *log.Logger) string {
	branchNameFromCircleCi := os.Getenv("CIRCLE_BRANCH")
	if branchNameFromCircleCi != "" {
		return branchNameFromCircleCi
	}

	branchName, err := shell.RunCommandAndGetOutput(shell.Command{Command: "git", Args: []string{"rev-parse", "--symbolic-full-name", "--abbrev-ref", "HEAD"}}, logger)
	if err != nil {
		t.Fatalf("Failed to get current branch name due to error: %v", err)
	}

	return branchName
}


