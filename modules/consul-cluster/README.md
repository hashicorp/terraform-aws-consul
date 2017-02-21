# Consul Cluster

This folder contains a [Terraform](https://www.terraform.io/) module that can be used to deploy a 
[Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/) on top of an Auto Scaling Group. This module 
is designed to deploy an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that had Consul installed via the [install-consul](/modules/install-consul) module in this Blueprint.



## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter to URL of this folder:

```hcl
module "consul_cluster" {
  # TODO: update this to the final URL
  # Use version v0.0.1 of the consul-cluster module
  source = "github.com/gruntwork-io/consul-aws-blueprint//modules/consul-cluster?ref=v0.0.1"

  # Specify the ID of the Consul AMI. You should build this using the scripts in the install-consul module.
  ami_id = "ami-abcd1234"
  
  # Configure and start Consul during boot 
  user_data = <<-EOF
              #!/bin/bash
              /opt/consul/bin/run-consul
              EOF
  
  # ... See vars.tf for the other parameters you must define for the consul-cluster module
}
```

Note the following parameters:

* `source`: Use this parameter to specify the URL of the consul-cluster module. The double slash (`//`) is intentional 
  and required. Terraform uses it to specify subfolders within a Git repo (see [module 
  sources](https://www.terraform.io/docs/modules/sources.html)). The `ref` parameter specifies a specific Git tag in 
  this repo. That way, instead of using the latest version of this module from the `master` branch, which 
  will change every time you run Terraform, you're using a fixed version of the repo.

* `ami_id`: Use this parameter to specify the ID of a Consul [Amazon Machine Image 
  (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) to deploy on each server in the cluster. You
  should install Consul in this AMI using the scripts in the [install-consul](/modules/install-consul) module.
  
* `user_data`: Use this parameter to specify a [User 
  Data](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts) script that each
  server will run during boot. This is where you can use the [run-consul script](/modules/run-consul) to configure and 
  run Consul. The `run-consul` script is one of the scripts installed by the [install-consul](/modules/install-consul) 
  module. 

You can find the other parameters in `vars.tf`.

To deploy the Consul cluster, do the following:

1. Download the module code: `terraform get`
1. Check the plan: `terraform plan`
1. If the plan looks good, deploy: `terraform apply`

Check out the [consul-cluster example](/examples/consul-cluster) for fully-working sample code. 



## What's included in this module?

This module creates the following architecture:

![Consul architecture](/_docs/architecture.png)

This architecture consists of the following resources:

* [Auto Scaling Group](#auto-scaling-group)
* [EC2 Instance Tags](#ec2-instance-tags)
* [Security Group](#security-group)
* [IAM Role and Permissions](#iam-role-and-permissions)

### Auto Scaling Group

This module runs Consul on top of an [Auto Scaling Group (ASG)](https://aws.amazon.com/autoscaling/). Typically, you
should run the ASG with 3 or 5 EC2 Instances spread across multiple [Availability 
Zones](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Each of the EC2
Instances should be running an AMI that has had Consul installed via the [install-consul](/modules/install-consul)
module. You pass in the ID of the AMI to run using the `ami_id` input parameter.

### EC2 Instance Tags

This module allows you to specify tags to add to each EC2 instance in the ASG. We recommend using these tags with the
[retry_join_ec2](https://www.consul.io/docs/agent/options.html?#retry_join_ec2) configuration to allow the EC2 
Instances to find each other and automatically form a cluster.     

### Security Group

Each EC2 Instance in the ASG has a Security Group that allows:
 
* All outbound requests
* All the inbound ports specified in the [Consul documentation](https://www.consul.io/docs/agent/options.html?#ports-used)

The Security Group ID is exported as an output variable if you need to add additional rules. 

### IAM Role and Permissions

Each EC2 Instance in the ASG has an IAM Role attached. The IAM permissions attached to this role are:

* `ec2:DescribeInstances`: Used to look up EC2 tags.

The IAM Role ARN is exported as an output variable if you need to add additional permissions. 



## How do you roll out updates?

If you want to deploy a new version of Consul across the cluster, the best way to do that is to:

1. Build a new AMI.
1. Set the `ami_id` parameter to the ID of the new AMI.
1. Run `terraform apply`.

This updates the Launch Configuration of the ASG, so any new Instances in the ASG will have your new AMI, but it does
NOT actually deploy those new instances. To make that happen, you should do the following:

1. Issue an API call to one of the old Instances in the ASG to have it leave gracefully. E.g.:

    ```
    curl -X PUT <OLD_INSTANCE_IP>:8500/v1/agent/leave
    ```
    
1. Once the instance has left the cluster, terminate it:
 
    ```
    aws ec2 terminate-instances --instance-ids <OLD_INSTANCE_ID>
    ```

1. After a minute or two, the ASG should automatically launch a new Instance, with the new AMI, to replace the old one.

1. Wait for the new Instance to boot and join the cluster.

1. Repeat these steps for each of the other old Instances in the ASG.
   
We will add a script in the future to automate this process (PRs are welcome!).




## What's NOT included in this module?

This module does NOT handle the following items, which you may want to provide on your own:

* [Monitoring, alerting, log aggregation](#monitoring-alerting-log-aggregation)
* [VPCs, subnets, route tables](#vpcs-subnets-route-tables)
* [DNS entries](#dns-entries)

### Monitoring, alerting, log aggregation

This module does not include anything for monitoring, alerting, or log aggregation. All ASGs and EC2 Instances come 
with limited [CloudWatch](https://aws.amazon.com/cloudwatch/) metrics built-in, but beyond that, you will have to 
provide your own solutions.

### VPCs, subnets, route tables

This module assumes you've already created your network topology (VPC, subnets, route tables, etc). You will need to 
pass in the the relevant info about your network topology (e.g. `vpc_id`, `subnet_ids`) as input variables to this 
module.

### DNS entries

This module does not create any DNS entries for Consul (e.g. in Route 53). However, the IDs of the ASG, ELB, and all
other resources are exported as output variables, so you should be able to add DNS entries yourself.


