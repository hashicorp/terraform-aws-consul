package test

import (
	"testing"
)

/*
// Test the example in the example-with-consul-connect folder
func TestConsulClusterWithUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", "examples/example-with-consul-connect", "../examples/consul-ami/consul.json", "ubuntu", "")
}*/

// Test the example in the example-with-consul-connect folder
func TestConsulConnectWithUbuntu18Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu18-ami", "examples/example-with-consul-connect", "../examples/consul-ami/consul.json", "ubuntu", "")
}

/*
// Test the example in the example-with-consul-connect folder
func TestConsulClusterWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-2-ami", "examples/example-with-consul-connect", "../examples/consul-ami/consul.json", "ec2-user", "")
}
*/
