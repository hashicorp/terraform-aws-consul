package test

import (
	"os"
	"testing"
)

// Test the example in the root folder
func TestConsulInstallFromURLWithUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", ".", "../examples/consul-ami/consul.json", "ubuntu", getUrlFromEnv(t))
}

func TestConsulInstallFromURLWithUbuntu18Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu18-ami", ".", "../examples/consul-ami/consul.json", "ubuntu", getUrlFromEnv(t))
}

func TestConsulInstallFromURLWithUbuntu20Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu20-ami", ".", "../examples/consul-ami/consul.json", "ubuntu", getUrlFromEnv(t))
}

func TestConsulInstallFromURLWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-2-ami", ".", "../examples/consul-ami/consul.json", "ec2-user", getUrlFromEnv(t))
}

// To test this on circle ci you need a url set as an environment variable, CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL
// which you would also have to set locally if you want to run this test locally.
func getUrlFromEnv(t *testing.T) string {
	url := os.Getenv("CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL")
	if url == "" {
		t.Fatalf("Please set the environment variable CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL.\n")
	}
	return url
}
