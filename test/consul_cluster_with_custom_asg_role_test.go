package test

import "testing"

func TestConsulClusterWithCustomASGRoleUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", "examples/example-with-custom-asg-role", "../examples/consul-ami/consul.json", "ubuntu", "")
}

func TestConsulClusterWithCustomASGRoleAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-ami", "examples/example-with-custom-asg-role", "../examples/consul-ami/consul.json", "ec2-user", "")
}
