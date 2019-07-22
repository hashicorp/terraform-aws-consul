package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
)

func TestConsulClusterWithCustomASGRoleUbuntu16Ami(t *testing.T) {
	t.Parallel()
	terraformVars := map[string]interface{}{
		"consul_service_linked_role_suffix": random.UniqueId(),
	}
	runConsulClusterTestWithVars(t, "ubuntu16-ami", "examples/example-with-custom-asg-role", "../examples/consul-ami/consul.json", "ubuntu", terraformVars, "")
}

func TestConsulClusterWithCustomASGRoleUbuntu18Ami(t *testing.T) {
	t.Parallel()
	terraformVars := map[string]interface{}{
		"consul_service_linked_role_suffix": random.UniqueId(),
	}
	runConsulClusterTestWithVars(t, "ubuntu18-ami", "examples/example-with-custom-asg-role", "../examples/consul-ami/consul.json", "ubuntu", terraformVars, "")
}

func TestConsulClusterWithCustomASGRoleAmazonLinuxAmi(t *testing.T) {
	t.Parallel()
	terraformVars := map[string]interface{}{
		"consul_service_linked_role_suffix": random.UniqueId(),
	}
	runConsulClusterTestWithVars(t, "amazon-linux-2-ami", "examples/example-with-custom-asg-role", "../examples/consul-ami/consul.json", "ec2-user", terraformVars, "")
}
