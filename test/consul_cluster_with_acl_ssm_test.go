package test

import (
	"testing"
)

// Test the example in the example-with-acl folder
func TestConsulClusterWithAclSsmUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", "examples/example-with-acl", "../examples/consul-ami/consul.json", "ubuntu", "",true)
}

// Test the example in the example-with-acl folder
func TestConsulClusterWithAclSsmUbuntu18Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu18-ami", "examples/example-with-acl", "../examples/consul-ami/consul.json", "ubuntu", "",true)
}

// Test the example in the example-with-acl folder
func TestConsulClusterWithAclSsmAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-2-ami", "examples/example-with-acl", "../examples/consul-ami/consul.json", "ec2-user", "",true)
}
