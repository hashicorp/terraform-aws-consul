package test

import (
	"testing"
)

func TestConsulClusterWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "TestConsulUbuntu", "ubuntu-16-ami")
}

func TestConsulClusterWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "TestConsulAmazonLinux", "amazon-linux-ami")
}

