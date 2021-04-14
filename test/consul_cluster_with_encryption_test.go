package test

import "testing"

func TestConsulClusterWithEncryptionUbuntu16Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami", "examples/example-with-encryption", "../examples/example-with-encryption/packer/consul-with-certs.json", "ubuntu", "")
}

func TestConsulClusterWithEncryptionUbuntu18Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu18-ami", "examples/example-with-encryption", "../examples/example-with-encryption/packer/consul-with-certs.json", "ubuntu", "")
}

func TestConsulClusterWithEncryptionUbuntu20Ami(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu20-ami", "examples/example-with-encryption", "../examples/example-with-encryption/packer/consul-with-certs.json", "ubuntu", "")
}

func TestConsulClusterWithEncryptionAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-2-ami", "examples/example-with-encryption", "../examples/example-with-encryption/packer/consul-with-certs.json", "ec2-user", "")
}
