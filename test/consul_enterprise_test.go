package test

import (
	"os"
	"testing"
)

// Test the example in the root folder
func TestConsulInstallFromURLWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", ".", "../examples/consul-ami/consul.json", "ubuntu", os.Getenv("CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL"))
}

func TestConsulInstallFromURLWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-ami", ".", "../examples/consul-ami/consul.json", "ec2-user", os.Getenv("CONSUL_AMI_TEMPLATE_VAR_DOWNLOAD_URL"))
}
