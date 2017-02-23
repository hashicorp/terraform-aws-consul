package test

import (
	"testing"
)

func TestConsulClusterWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "TestConsulClusterWithUbuntuAmi", "ubuntu-16-ami")
}

func TestConsulClusterWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "TestConsulClusterWithAmazonLinuxAmi", "amazon-linux-ami")
}

