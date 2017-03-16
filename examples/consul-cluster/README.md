# Consul Cluster Example

This folder shows an example of Terraform code that uses the [consul-cluster](/modules/consul-cluster) module to deploy 
a [Consul](https://www.consul.io/) cluster in [AWS](https://aws.amazon.com/). The cluster consists of two Auto Scaling
Groups (ASGs): one with a small number of Consul server nodes, which are responsible for being part of the [consensus 
quorum](https://www.consul.io/docs/internals/consensus.html), and one with a larger number of client nodes, which 
would typically run alongside your apps:

![Consul architecture](/_docs/architecture.png)

You will need to create an [Amazon Machine Image (AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) 
that has Consul installed, which you can do using the [consul-ami example](/examples/consul-ami)). Note that to keep 
this example simple, both the server ASG and client ASG are running the exact same AMI. In real-world usage, you'd 
probably have multiple client ASGs, and each of those ASGs would run a different AMI that has the Consul agent 
installed alongside your apps.

For more info on how the Consul cluster works, check out the [consul-cluster](/modules/consul-cluster) documentation.



## Quick start

To deploy a Consul Cluster:

1. `git clone` this repo to your computer.
1. Build a Consul AMI. See the [consul-ami example](/examples/consul-ami) documentation for instructions. Make sure to
   note down the ID of the AMI.
1. Install [Terraform](https://www.terraform.io/).
1. Open `vars.tf`, set the environment variables specified at the top of the file, and fill in any other variables that
   don't have a default, including putting your AMI ID into the `ami_id` variable.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

After the `apply` command finishes, the Consul EC2 Instances will start, discover each other, and form a cluster.
 
To see how to connect to the cluster and start reading/writing data, head over to the [How do you connect to the Consul 
cluster?](/modules/consul-cluster#how-do-you-connect-to-the-consul-cluster) docs.
