package test

import (
	"testing"
)

// Test the example in the root folder
func TestConsulClusterWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", ".", "../examples/consul-ami/consul.json", "ubuntu", "")
}

// Test the example in the root folder
func TestConsulClusterWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-2-ami", ".", "../examples/consul-ami/consul.json", "ec2-user", "")
}
