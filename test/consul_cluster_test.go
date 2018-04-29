package test

import (
	"testing"
)

func TestConsulClusterWithUbuntuAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "ubuntu16-ami")
}

func TestConsulClusterWithAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	runConsulClusterTest(t, "amazon-linux-ami")
}

