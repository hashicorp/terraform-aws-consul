package test

import (
	"fmt"
	"strings"
	"testing"
	"time"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)



// Test the consul-cluster example by:
//
// 1. Copying the code in this repo to a temp folder so tests on the Terraform code can run in parallel without the
//    state files overwriting each other.
// 2. Building the AMI in the consul-ami example with the given build name
// 3. Deploying that AMI using the consul-cluster Terraform code
// 4. Checking that the Consul cluster comes up within a reasonable time period and can respond to requests
func runConsulConnectTest(t *testing.T, packerBuildName string, examplesFolder string, packerTemplatePath string, sshUser string) {
	runConsulConnectTestWithVars(t,
		packerBuildName,
		examplesFolder,
		packerTemplatePath,
		sshUser,
		map[string]interface{}{})
}

func runConsulConnectTestWithVars(t *testing.T, packerBuildName string, examplesFolder string, packerTemplatePath string, sshUser string, terraformVarsMerge map[string]interface{}) {
	// Uncomment any of the following to skip that section during the test
	//os.Setenv("SKIP_setup_ami", "true")
	//os.Setenv("SKIP_deploy", "true")
	//os.Setenv("SKIP_validate", "true")
	//os.Setenv("SKIP_teardown", "true")

	exampleFolder := test_structure.CopyTerraformFolderToTemp(t, REPO_ROOT, examplesFolder)

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegion := aws.GetRandomRegion(t, nil, []string{"eu-north-1"})
		test_structure.SaveString(t, exampleFolder, SAVED_AWS_REGION, awsRegion)

		amiId := buildAmi(t, packerTemplatePath, packerBuildName, awsRegion, "")
		test_structure.SaveAmiId(t, exampleFolder, amiId)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleFolder)
		terraform.Destroy(t, terraformOptions)

		keyPair := test_structure.LoadEc2KeyPair(t, exampleFolder)
		aws.DeleteEC2KeyPair(t, keyPair)

		amiId := test_structure.LoadAmiId(t, exampleFolder)
		awsRegion := test_structure.LoadString(t, exampleFolder, SAVED_AWS_REGION)
		aws.DeleteAmi(t, awsRegion, amiId)
	})

	test_structure.RunTestStage(t, "deploy", func() {
		uniqueId := random.UniqueId()
		awsRegion := test_structure.LoadString(t, exampleFolder, SAVED_AWS_REGION)
		amiId := test_structure.LoadAmiId(t, exampleFolder)

		keyPair := aws.CreateAndImportEC2KeyPair(t, awsRegion, uniqueId)
		test_structure.SaveEc2KeyPair(t, exampleFolder, keyPair)

		terraformVars := map[string]interface{}{
			CONSUL_CLUSTER_EXAMPLE_VAR_CLUSTER_NAME: uniqueId,
			CONSUL_CLUSTER_EXAMPLE_VAR_NUM_SERVERS:  CONSUL_CLUSTER_EXAMPLE_DEFAULT_NUM_SERVERS,
			CONSUL_CLUSTER_EXAMPLE_VAR_NUM_CLIENTS:  CONSUL_CLUSTER_EXAMPLE_DEFAULT_NUM_CLIENTS,
			CONSUL_CLUSTER_EXAMPLE_VAR_AMI_ID:       amiId,
			CONSUL_CLUSTER_EXAMPLE_VAR_SSH_KEY_NAME: keyPair.Name,
		}

		for k, v := range terraformVarsMerge {
			terraformVars[k] = v
		}

		terraformOptions := &terraform.Options{
			TerraformDir: exampleFolder,
			Vars:         terraformVars,
			EnvVars: map[string]string{
				AWS_DEFAULT_REGION_ENV_VAR: awsRegion,
			},
		}
		test_structure.SaveTerraformOptions(t, exampleFolder, terraformOptions)

		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		awsRegion := test_structure.LoadString(t, exampleFolder, SAVED_AWS_REGION)
		terraformOptions := test_structure.LoadTerraformOptions(t, exampleFolder)
		keyPair := test_structure.LoadEc2KeyPair(t, exampleFolder)

		// Check the Consul servers
		checkConsulClusterIsWorking(t, CONSUL_CLUSTER_EXAMPLE_OUTPUT_SERVER_ASG_NAME, terraformOptions, awsRegion)

		// Check the Consul clients
		checkConsulClusterIsWorking(t, CONSUL_CLUSTER_EXAMPLE_OUTPUT_CLIENT_ASG_NAME, terraformOptions, awsRegion)
		
		// Check the Consul CA
		checkConsulCA(t, CONSUL_CLUSTER_EXAMPLE_OUTPUT_SERVER_ASG_NAME, terraformOptions, awsRegion, sshUser, keyPair)
	})
}

func checkConsulCA(t *testing.T, asgNameOutputVar string, terratestOptions *terraform.Options, awsRegion string, sshUser string, keyPair *aws.Ec2Keypair) {
	asgName := terraform.OutputRequired(t, terratestOptions, asgNameOutputVar)
	nodeIpAddress := getIpAddressOfAsgInstance(t, asgName, awsRegion)
	
	host := ssh.Host{
		Hostname:    nodeIpAddress,
		SshUserName: sshUser,
		SshKeyPair:  keyPair.KeyPair,
	}

	maxRetries := 10
	sleepBetweenRetries := 10 * time.Second
	
	output := retry.DoWithRetry(t, "Check Consul Built-in Certificate Authority", maxRetries, sleepBetweenRetries, func() (string, error) {
		out, err := ssh.CheckSshCommandE(t, host, "consul connect ca get-config")
		if err != nil {
			return "", fmt.Errorf("Error running consul command: %s\n", err)
		}

		return out, nil
	})

	if !strings.Contains(output, "Config") {
		t.Fatalf("Consul CA does not have a Config\n")
	}
}

