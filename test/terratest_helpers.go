package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/packer"
)

const CONSUL_AMI_TEMPLATE_VAR_REGION = "aws_region"
const CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL = "CONSUL_DOWNLOAD_URL"

// Use Packer to build the AMI in the given packer template, with the given build name, and return the AMI's ID
func buildAmi(t *testing.T, packerTemplatePath string, packerBuildName string, awsRegion string, downloadUrl string) string {
	options := &packer.Options{
		Template: packerTemplatePath,
		Only:     packerBuildName,
		Vars: map[string]string{
			CONSUL_AMI_TEMPLATE_VAR_REGION: awsRegion,
		},
		Env: map[string]string{
			CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL: downloadUrl,
		},
	}

	return packer.BuildAmi(t, options)
}
