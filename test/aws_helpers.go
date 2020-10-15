package test

import (
	"github.com/gruntwork-io/terratest/modules/aws"
	"testing"
)

// Get the IP address from a randomly chosen EC2 Instance in an Auto Scaling Group of the given name in the given
// region
func getIpAddressOfAsgInstance(t *testing.T, asgName string, awsRegion string) string {
	instanceIds := aws.GetInstanceIdsForAsg(t, asgName, awsRegion)

	if len(instanceIds) == 0 {
		t.Fatalf("Could not find any instances in ASG %s in %s", asgName, awsRegion)
	}

	return aws.GetPublicIpOfEc2Instance(t, instanceIds[0], awsRegion)
}
