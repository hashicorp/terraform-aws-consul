# Consul Cluster

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a 
[Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/). This module is designed to deploy an 
[Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that had Consul installed
via the [consul-install](/modules/consul-install) module.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "consul_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of this module
  source = "github.com/gruntwork-io/consul-aws-blueprint//modules/consul-cluster?ref=v0.0.1"

  # Set the parameters for this module. See vars.tf for available parameters.
  foo = "bar"
}
```

Two notes about the URL in the `source` parameter:

1. The double slash (`//`) is intentional and required. Terraform uses it to specify subfolders within a Git repo 
   (see [module sources](https://www.terraform.io/docs/modules/sources.html)).
1. The `ref` parameter specifies a specific Git tag in this repo. That way, instead of using the latest version of this
   module from the `master` branch, which will change every time you run Terraform, you're using a fixed version of 
   this repo.

To deploy the module, run:

1. Download the module code: `terraform get`
1. See the plan: `terraform plan`
1. If the plan looks good, deploy: `terraform apply`

Check out the [consul-cluster example](/examples/consul-cluster) for fully-working sample code. 

## What's included in this module?

This module creates the following architecture:

![Consul architecture](/_docs/architecture.png)

This architecture consists of the following resources:

* Auto Scaling Group
* EC2 Instance Tags
* Security Group
* IAM Role and Permissions

### Auto Scaling Group

This module runs Consul on top of an [Auto Scaling Group (ASG)](https://aws.amazon.com/autoscaling/). Typically, you
would run the ASG with 3 or 5 EC2 Instances spread across multiple [Availability 
Zones](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Each of the EC2
Instances should be running an AMI that has had Consul installed via the [consul-install](/modules/consul-install)
module. 

TODO: should we provide a way to automatically roll out updates across the ASG? We could use the [create_before_destroy
approach described by Paul Hinze](https://groups.google.com/forum/#!msg/terraform-tool/7Gdhv1OAc80/iNQ93riiLwAJ),
although we'd need to hook up a load balancer to the ASG. However, that approach creates an entirely new ASG, so all 
the locally stored data on the nodes of the original ASG would have to be synced to the new nodes. Is this a slow 
process or a bad approach? Should the nodes be updated in-place instead (mutable infrastructure) using a cfg mgmt 
tool?

TODO: should we hook up a load balancer to the ASG? It's useful for health checks and could be a central URL for users
to visit the `/ui` endpoint.

### EC2 Instance Tags

The ASG adds a tag called `consul-cluster` to each EC2 instance. When each EC2 Instance is booting, it will look up 
this tag, use it to find all other EC2 Instances with the same tag, and join them to form a cluster (using the 
[retry_join_ec2](https://www.consul.io/docs/agent/options.html?#retry_join_ec2) configuration).    

### Security Group

Each EC2 Instance in the ASG has a Security Group that allows:
 
* All outbound requests
* All the inbound ports specified in the [Consul documentation](https://www.consul.io/docs/agent/options.html?#ports-used)

The Security Group ID is exported as an output variable if you need to add additional rules. 

### IAM Role and Permissions

Each EC2 Instance in the ASG has an IAM Role attached. The IAM permissions attached to this role are:

* `ec2:DescribeInstances`: Used to look up EC2 tags.

The IAM Role ARN is exported as an output variable if you need to add additional permissions. 

## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own:

* Monitoring, alerting, log aggregation
* VPCs, subnets, route tables

### Monitoring, alerting, log aggregation

This module does not include anything for monitoring, alerting, or log aggregation. All ASGs and EC2 Instances come 
with limited [CloudWatch](https://aws.amazon.com/cloudwatch/) metrics built-in, but beyond that, you will have to 
provide your own solutions.

### VPCs, subnets, route tables

This module assumes you've already created your network topology (VPC, subnets, route tables, etc). You will need to 
pass in the the relevant info about your network topology (e.g. `vpc_id`, `subnet_ids`) as input variables to this 
module.

### Route 53 entries (TODO)

TODO: Should we include any Route 53 entries for the consul cluster?

### Encryption (TODO)

TODO: How do we securely get an SSL cert to the Consul servers? KMS?
TODO: How do we securely get an encryption key to the Consul servers? KMS?